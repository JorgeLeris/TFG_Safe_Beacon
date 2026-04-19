import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/repositories/guardian_session_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/firebase_options.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/services/guardian_mode_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==============================================
// MARK: - SharedPreferences keys
// ==============================================

// Start parameters are written to SharedPreferences by the UI isolate *before*
// startService() is called and read directly by the background isolate.

const _kPrefUid = 'guardian_bg_uid';
const _kPrefLocale = 'guardian_bg_locale';
const _kPrefRoutePoints = 'guardian_bg_route_points';

// ==============================================
// MARK: - Event names (UI - Background)
// ==============================================

/// Sent by the UI to stop the check loop and terminate the service.
const _kEvtStop = 'guardian_stop';

/// Sent by the UI when the route polyline is updated.
const _kEvtUpdateRoute = 'guardian_update_route';

/// Broadcast by the background isolate when a guardian alert is created.
const kEvtAlertGenerated = 'guardian_alert_generated';

// ==============================================
// MARK: - Background entry point
// ==============================================

/// Entry point executed in the background Dart isolate.
@pragma('vm:entry-point')
Future<void> onGuardianBackgroundStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await runZonedGuarded(
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // dotenv is needed by NotificationService.sendPushNotification.
      try {
        await dotenv.load();
      } catch (e) {
        appLogger.warning(
          'Guardian background: dotenv.load() failed — push notifications may not work: $e',
        );
      }

      // Read start parameters written by the UI isolate before startService().
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_kPrefUid);
      final localeCode = prefs.getString(_kPrefLocale) ?? 'es';
      final rawRouteJson = prefs.getString(_kPrefRoutePoints);

      if (uid == null || uid.isEmpty) {
        appLogger.warning(
          'Guardian background: no uid in SharedPreferences — stopping service',
        );
        await service.stopSelf();
        return;
      }

      final routePoints = _decodeRoutePoints(rawRouteJson);

      // Create fresh repository instances inside this isolate.
      final guardianSessionRepo = GuardianSessionRepositoryImpl(
        api: GuardianSessionApi(),
      );
      final alertRepo = AlertRepositoryImpl(api: AlertApi());
      final userProfileRepo = UserProfileRepositoryImpl(api: UserProfileApi());

      // Load localised notification strings for this locale.
      final l10n = await AppLocalizations.delegate.load(Locale(localeCode));

      // Fetch the session fresh from Firestore - source of truth.
      final sessionResult = await guardianSessionRepo.getActiveSession(uid);
      final session = sessionResult.valueOrNull;
      if (session == null) {
        appLogger.warning(
          'Guardian background: no active session for uid $uid — stopping service',
        );
        await service.stopSelf();
        return;
      }

      // Start the periodic check loop.
      final checkService = GuardianModeCheckService(
        uid: uid,
        guardianSessionRepository: guardianSessionRepo,
        alertRepository: alertRepo,
        userProfileRepository: userProfileRepo,
        onAlertGenerated: (statuses) {
          service.invoke(kEvtAlertGenerated, {
            'statuses': statuses.map((s) => s.id).toList(),
          });
        },
      );

      checkService.start(
        session: session,
        routePoints: routePoints,
        notificationTitleBuilder: l10n.notificationAlertTitle,
        notificationBodyBuilder: l10n.notificationGuardianBody,
      );

      // Stop command: cancel the timer and terminate the service.
      service.on(_kEvtStop).listen((_) async {
        checkService.stop();
        await service.stopSelf();
      });

      // Route update: forward new polyline to the running check service.
      service.on(_kEvtUpdateRoute).listen((data) {
        if (data == null) return;
        checkService.updateRoutePoints(
          _decodeRoutePoints(data['routePoints'] as String?),
        );
      });
    },
    (error, stack) {
      appLogger.severe(
        'Guardian background: unhandled error in background isolate',
        error,
        stack,
      );
    },
  );
}

List<LatLng> _decodeRoutePoints(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final list = (jsonDecode(json) as List).cast<List<dynamic>>();
    return list
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// iOS background handler - acknowledges the background task.
@pragma('vm:entry-point')
Future<bool> onGuardianIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ==============================================
// MARK: - UI-side manager
// ==============================================

/// Controls the guardian mode background service from the UI isolate.
///
/// On **Android** this delegates to [FlutterBackgroundService] which runs
/// in a separate foreground-service isolate (survives app close).
///
/// On **iOS** `flutter_background_service` runs the `onForeground` handler in
/// the *same* isolate as the main app.
class GuardianBackgroundServiceManager {
  GuardianBackgroundServiceManager._();

  static final _service = FlutterBackgroundService();

  static const _notificationChannelId = 'guardian_mode_service';
  static const _notificationChannelName = 'Modo Guardián';

  // iOS in-process check service
  static GuardianModeCheckService? _iosCheckService;
  static final _iosAlertController =
      StreamController<List<GuardianSessionSecondaryStatus>>.broadcast();

  // ──────────────────────────────────────────
  // Setup
  // ──────────────────────────────────────────

  /// Configures the background service engine.
  ///
  /// Must be called once before [startChecks], typically from [main].
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _notificationChannelId,
              _notificationChannelName,
              description: 'Supervisión activa del Modo Guardián',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
            ),
          );

      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onGuardianBackgroundStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: _notificationChannelName,
          initialNotificationContent: 'Supervisando tu sesión activa',
          autoStartOnBoot: false,
          foregroundServiceTypes: const [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onGuardianBackgroundStart,
          onBackground: onGuardianIosBackground,
        ),
      );
    }
    // iOS: no service configuration needed — we run in-process.
  }

  // ──────────────────────────────────────────
  // Control
  // ──────────────────────────────────────────

  /// Whether the background service is currently running.
  static Future<bool> isRunning() async {
    if (Platform.isAndroid) return _service.isRunning();
    return _iosCheckService?.isRunning ?? false;
  }

  /// Starts the background service and kicks off the guardian check loop.
  ///
  /// Returns `true` if the service was started successfully.
  static Future<bool> startChecks({
    required String uid,
    required List<LatLng> routePoints,
    required String locale,
  }) async {
    if (Platform.isAndroid) {
      return _startChecksAndroid(
        uid: uid,
        routePoints: routePoints,
        locale: locale,
      );
    }
    return _startChecksIos(uid: uid, routePoints: routePoints, locale: locale);
  }

  /// Forwards an updated route polyline to the running service.
  static Future<void> updateRoutePoints(List<LatLng> points) async {
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        points.map((p) => [p.latitude, p.longitude]).toList(),
      );
      await prefs.setString(_kPrefRoutePoints, encoded);
      _service.invoke(_kEvtUpdateRoute, {'routePoints': encoded});
    } else {
      _iosCheckService?.updateRoutePoints(points);
    }
  }

  /// Sends the stop command and clears stored params.
  static Future<void> stopChecks() async {
    if (Platform.isAndroid) {
      _service.invoke(_kEvtStop, {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefUid);
      await prefs.remove(_kPrefLocale);
      await prefs.remove(_kPrefRoutePoints);
    } else {
      _iosCheckService?.stop();
      _iosCheckService = null;
    }
  }

  // ──────────────────────────────────────────
  // Events
  // ──────────────────────────────────────────

  /// Stream of alert-trigger status lists broadcast by the background service.
  static Stream<List<GuardianSessionSecondaryStatus>> get onAlertGenerated {
    if (Platform.isAndroid) {
      return _service.on(kEvtAlertGenerated).map((data) {
        if (data == null) return const [];
        final ids = (data['statuses'] as List).cast<String>();
        return ids
            .map(GuardianSessionSecondaryStatus.fromId)
            .whereType<GuardianSessionSecondaryStatus>()
            .toList();
      });
    }
    return _iosAlertController.stream;
  }

  // ──────────────────────────────────────────
  // Android-specific start
  // ──────────────────────────────────────────

  static Future<bool> _startChecksAndroid({
    required String uid,
    required List<LatLng> routePoints,
    required String locale,
  }) async {
    try {
      if (await _service.isRunning()) return true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefUid, uid);
      await prefs.setString(_kPrefLocale, locale);
      await prefs.setString(
        _kPrefRoutePoints,
        jsonEncode(routePoints.map((p) => [p.latitude, p.longitude]).toList()),
      );

      final started = await _service.startService();
      if (!started) {
        appLogger.warning(
          'Guardian background service: startService() returned false',
        );
        return false;
      }
      return true;
    } on PlatformException catch (e, st) {
      appLogger.severe(
        'Guardian background service: failed to start — ${e.message}',
        e,
        st,
      );
      return false;
    } catch (e, st) {
      appLogger.severe(
        'Guardian background service: unexpected error on start',
        e,
        st,
      );
      return false;
    }
  }

  // ──────────────────────────────────────────
  // iOS-specific start (in-process)
  // ──────────────────────────────────────────

  static Future<bool> _startChecksIos({
    required String uid,
    required List<LatLng> routePoints,
    required String locale,
  }) async {
    try {
      // Stop any leftover instance from a previous session.
      _iosCheckService?.stop();
      _iosCheckService = null;

      final guardianSessionRepo = GuardianSessionRepositoryImpl(
        api: GuardianSessionApi(),
      );
      final alertRepo = AlertRepositoryImpl(api: AlertApi());
      final userProfileRepo = UserProfileRepositoryImpl(api: UserProfileApi());

      final l10n = await AppLocalizations.delegate.load(Locale(locale));

      final sessionResult = await guardianSessionRepo.getActiveSession(uid);
      final session = sessionResult.valueOrNull;
      if (session == null) {
        appLogger.warning(
          'Guardian iOS: no active session for uid $uid — not starting checks',
        );
        return false;
      }

      final checkService = GuardianModeCheckService(
        uid: uid,
        guardianSessionRepository: guardianSessionRepo,
        alertRepository: alertRepo,
        userProfileRepository: userProfileRepo,
        onAlertGenerated: (statuses) {
          _iosAlertController.add(statuses);
        },
      );

      checkService.start(
        session: session,
        routePoints: routePoints,
        notificationTitleBuilder: l10n.notificationAlertTitle,
        notificationBodyBuilder: l10n.notificationGuardianBody,
      );

      _iosCheckService = checkService;
      appLogger.info('Guardian iOS: check service started in main isolate');
      return true;
    } catch (e, st) {
      appLogger.severe('Guardian iOS: failed to start check service', e, st);
      return false;
    }
  }
}
