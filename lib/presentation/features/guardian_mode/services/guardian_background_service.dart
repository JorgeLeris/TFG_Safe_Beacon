import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
import 'package:safe_beacon/presentation/features/guardian_mode/services/guardian_mode_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==============================================
// MARK: - SharedPreferences keys
// ==============================================

// Start parameters are written to SharedPreferences by the UI isolate *before*
// startService() is called and read directly by the background isolate.

/// UID of the user who activated guardian mode.
const kPrefGuardianUid = 'guardian_bg_uid';

/// Locale code used for localised notification strings.
const kPrefGuardianLocale = 'guardian_bg_locale';

/// JSON-encoded route polyline points.
const kPrefGuardianRoutePoints = 'guardian_bg_route_points';

// ==============================================
// MARK: - Event names (UI ↔ Background)
// ==============================================

/// Sent by the UI to start guardian when the unified service is already running.
const kEvtGuardianStart = 'guardian_start';

/// Sent by the UI to stop the check loop.
const kEvtGuardianStop = 'guardian_stop';

/// Sent by the UI when the route polyline is updated.
const kEvtGuardianUpdateRoute = 'guardian_update_route';

/// Broadcast by the background isolate when a guardian alert is created.
const kEvtGuardianAlertGenerated = 'guardian_alert_generated';

// Keep old name as alias for backwards compatibility.
const kEvtAlertGenerated = kEvtGuardianAlertGenerated;


// ==============================================
// MARK: - UI-side manager
// ==============================================

/// Controls the guardian mode background service from the UI isolate.
///
/// On **Android** this delegates to the unified [FlutterBackgroundService]
/// (configured by [BackgroundServiceInitializer]) which runs in a separate
/// foreground-service isolate (survives app close).
///
/// On **iOS** it runs [GuardianModeCheckService] directly in the *same*
/// isolate as the main app.
///
/// Both guardian mode and fall detection share the same service on Android.
/// Each feature stores its parameters in [SharedPreferences] before starting
/// so the unified entry point can start the correct check services.
class GuardianBackgroundServiceManager {
  GuardianBackgroundServiceManager._();

  static final _service = FlutterBackgroundService();

  // iOS in-process check service.
  static GuardianModeCheckService? _iosCheckService;
  static final _iosAlertController =
      StreamController<List<GuardianSessionSecondaryStatus>>.broadcast();

  // ──────────────────────────────────────────
  // Control
  // ──────────────────────────────────────────

  /// Whether guardian mode is currently running.
  static Future<bool> isRunning() async {
    if (Platform.isAndroid) {
      if (!await _service.isRunning()) return false;
      // Unified service may be running for another feature — check pref.
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(kPrefGuardianUid);
    }
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
      await prefs.setString(kPrefGuardianRoutePoints, encoded);
      _service.invoke(kEvtGuardianUpdateRoute, {'routePoints': encoded});
    } else {
      _iosCheckService?.updateRoutePoints(points);
    }
  }

  /// Sends the stop command and clears stored params.
  static Future<void> stopChecks() async {
    if (Platform.isAndroid) {
      _service.invoke(kEvtGuardianStop, {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPrefGuardianUid);
      await prefs.remove(kPrefGuardianLocale);
      await prefs.remove(kPrefGuardianRoutePoints);
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
      return _service.on(kEvtGuardianAlertGenerated).map((data) {
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefGuardianUid, uid);
      await prefs.setString(kPrefGuardianLocale, locale);
      await prefs.setString(
        kPrefGuardianRoutePoints,
        jsonEncode(routePoints.map((p) => [p.latitude, p.longitude]).toList()),
      );

      if (await _service.isRunning()) {
        // Unified service already running (e.g. fall detection active).
        // Send a start event so the background isolate picks up the new params.
        _service.invoke(kEvtGuardianStart, {});
        appLogger.info(
          'Guardian: unified service already running — sent start event',
        );
        return true;
      }

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
