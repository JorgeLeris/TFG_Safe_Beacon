import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
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
import 'package:safe_beacon/firebase_options.dart';
import 'package:safe_beacon/presentation/features/fall_detection/services/fall_detection_background_service.dart';
import 'package:safe_beacon/presentation/features/fall_detection/services/fall_detection_check_service.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/services/guardian_background_service.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/services/guardian_mode_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==============================================
// MARK: - Notification channel
// ==============================================

const _notificationChannelId = 'safe_beacon_background_service';
const _notificationChannelName = 'Safe Beacon';

// ==============================================
// MARK: - Background entry point
// ==============================================

/// Unified entry point executed in the background Dart isolate.
///
/// Handles both guardian mode and fall detection features. Each feature
/// stores its parameters in [SharedPreferences] before starting the service.
/// The entry point reads those parameters and starts the appropriate check
/// services. It also listens for start/stop events so features can be
/// toggled independently while the service is already running.
@pragma('vm:entry-point')
Future<void> onUnifiedBackgroundStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await runZonedGuarded(
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      try {
        await dotenv.load();
      } catch (e) {
        appLogger.warning(
          'Background service: dotenv.load() failed — push notifications may not work: $e',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Mutable references so event handlers can start/stop features.
      GuardianModeCheckService? guardianCheck;
      FallDetectionCheckService? fallCheck;

      void tryStopSelf() {
        final guardianRunning = guardianCheck?.isRunning ?? false;
        final fallRunning = fallCheck?.isRunning ?? false;
        if (!guardianRunning && !fallRunning) {
          appLogger.info(
            'Background service: no features running — stopping service',
          );
          service.stopSelf();
        }
      }

      // Guardian mode
      guardianCheck = await _startGuardian(service, prefs);

      // Fall detection
      fallCheck = await _startFallDetection(service, prefs);

      // If nothing to run, stop immediately.
      if (guardianCheck == null && fallCheck == null) {
        appLogger.warning(
          'Background service: no features to run — stopping service',
        );
        await service.stopSelf();
        return;
      }

      // Guardian events

      service.on(kEvtGuardianStart).listen((_) async {
        if (guardianCheck?.isRunning ?? false) return;
        guardianCheck = await _startGuardian(service, prefs);
      });

      service.on(kEvtGuardianStop).listen((_) async {
        guardianCheck?.stop();
        guardianCheck = null;
        tryStopSelf();
      });

      service.on(kEvtGuardianUpdateRoute).listen((data) {
        if (data == null) return;
        guardianCheck?.updateRoutePoints(
          _decodeRoutePoints(data['routePoints'] as String?),
        );
      });

      // Fall detection events

      service.on(kEvtFallStart).listen((_) async {
        if (fallCheck?.isRunning ?? false) return;
        fallCheck = await _startFallDetection(service, prefs);
      });

      service.on(kEvtFallStop).listen((_) async {
        fallCheck?.stop();
        fallCheck = null;
        tryStopSelf();
      });
    },
    (error, stack) {
      appLogger.severe(
        'Background service: unhandled error in background isolate',
        error,
        stack,
      );
    },
  );
}

// ==============================================
// MARK: - Guardian startup helper
// ==============================================

Future<GuardianModeCheckService?> _startGuardian(
  ServiceInstance service,
  SharedPreferences prefs,
) async {
  final uid = prefs.getString(kPrefGuardianUid);
  final localeCode = prefs.getString(kPrefGuardianLocale) ?? 'es';
  final rawRouteJson = prefs.getString(kPrefGuardianRoutePoints);

  if (uid == null || uid.isEmpty) return null;

  final routePoints = _decodeRoutePoints(rawRouteJson);

  final guardianSessionRepo = GuardianSessionRepositoryImpl(
    api: GuardianSessionApi(),
  );
  final alertRepo = AlertRepositoryImpl(api: AlertApi());
  final userProfileRepo = UserProfileRepositoryImpl(api: UserProfileApi());

  final l10n = await AppLocalizations.delegate.load(Locale(localeCode));

  final sessionResult = await guardianSessionRepo.getActiveSession(uid);
  final session = sessionResult.valueOrNull;
  if (session == null) {
    appLogger.warning(
      'Background service: no active guardian session for uid $uid',
    );
    return null;
  }

  final checkService = GuardianModeCheckService(
    uid: uid,
    guardianSessionRepository: guardianSessionRepo,
    alertRepository: alertRepo,
    userProfileRepository: userProfileRepo,
    onAlertGenerated: (statuses) {
      service.invoke(kEvtGuardianAlertGenerated, {
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

  appLogger.info('Background service: guardian check service started');
  return checkService;
}

// ==============================================
// MARK: - Fall detection startup helper
// ==============================================

Future<FallDetectionCheckService?> _startFallDetection(
  ServiceInstance service,
  SharedPreferences prefs,
) async {
  final uid = prefs.getString(kPrefFallUid);
  final localeCode = prefs.getString(kPrefFallLocale) ?? 'es';

  if (uid == null || uid.isEmpty) return null;

  final alertRepo = AlertRepositoryImpl(api: AlertApi());
  final userProfileRepo = UserProfileRepositoryImpl(api: UserProfileApi());

  final l10n = await AppLocalizations.delegate.load(Locale(localeCode));

  final checkService = FallDetectionCheckService(
    uid: uid,
    alertRepository: alertRepo,
    userProfileRepository: userProfileRepo,
    onAlertGenerated: () {
      service.invoke(kEvtFallAlertGenerated);
    },
    notificationTitleBuilder: l10n.notificationAlertTitle,
    notificationBodyBuilder: l10n.notificationFallDetectionBody,
  );

  checkService.start();

  appLogger.info('Background service: fall detection check service started');
  return checkService;
}

// ==============================================
// MARK: - iOS background handler
// ==============================================

@pragma('vm:entry-point')
Future<bool> onUnifiedIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ==============================================
// MARK: - Helpers
// ==============================================

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

// ==============================================
// MARK: - UI-side initializer
// ==============================================

/// Configures the [FlutterBackgroundService] used by both guardian mode and
/// fall detection.
///
/// Must be called once from [mainCommon] before any feature starts the service.
class BackgroundServiceInitializer {
  BackgroundServiceInitializer._();

  static final _service = FlutterBackgroundService();

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
              description: 'Servicio de protección activo',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
            ),
          );

      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onUnifiedBackgroundStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: _notificationChannelName,
          initialNotificationContent: 'Servicio de protección activo',
          autoStartOnBoot: false,
          foregroundServiceTypes: const [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onUnifiedBackgroundStart,
          onBackground: onUnifiedIosBackground,
        ),
      );
    }
    // iOS: no service configuration needed — features run in-process.
  }
}
