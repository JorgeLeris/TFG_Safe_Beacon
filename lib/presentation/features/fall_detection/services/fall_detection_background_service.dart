import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/presentation/features/fall_detection/services/fall_detection_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==============================================
// MARK: - SharedPreferences keys
// ==============================================

/// UID of the user who activated fall detection.
const kPrefFallUid = 'fall_detection_bg_uid';

/// Locale code used for localised notification strings.
const kPrefFallLocale = 'fall_detection_bg_locale';

// ==============================================
// MARK: - Event names (UI - Background)
// ==============================================

/// Sent by the UI to start fall detection when the service is already running.
const kEvtFallStart = 'fall_detection_start';

/// Sent by the UI to stop the fall detection check loop.
const kEvtFallStop = 'fall_detection_stop';

/// Broadcast by the background isolate when a fall alert is created.
const kEvtFallAlertGenerated = 'fall_detection_alert_generated';

// ==============================================
// MARK: - UI-side manager
// ==============================================

/// Controls the fall detection background service from the UI isolate.
///
/// On **Android** this delegates to the unified [FlutterBackgroundService]
/// which runs in a separate foreground-service isolate (survives app close).
///
/// On **iOS** it runs the [FallDetectionCheckService] in the *same* isolate
/// as the main app.
class FallDetectionBackgroundServiceManager {
  FallDetectionBackgroundServiceManager._();

  static final _service = FlutterBackgroundService();

  // iOS in-process check service.
  static FallDetectionCheckService? _iosCheckService;
  static final _iosAlertController = StreamController<void>.broadcast();

  // ──────────────────────────────────────────
  // Control
  // ──────────────────────────────────────────

  /// Whether fall detection is currently running.
  static Future<bool> isRunning() async {
    if (Platform.isAndroid) {
      if (!await _service.isRunning()) return false;
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(kPrefFallUid);
    }
    return _iosCheckService?.isRunning ?? false;
  }

  /// Starts fall detection.
  ///
  /// Returns `true` if the service was started or was already running.
  static Future<bool> startChecks({
    required String uid,
    required String locale,
  }) async {
    if (Platform.isAndroid) {
      return _startChecksAndroid(uid: uid, locale: locale);
    }
    return _startChecksIos(uid: uid, locale: locale);
  }

  /// Stops fall detection and clears stored params.
  static Future<void> stopChecks() async {
    if (Platform.isAndroid) {
      _service.invoke(kEvtFallStop, {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPrefFallUid);
      await prefs.remove(kPrefFallLocale);
    } else {
      _iosCheckService?.stop();
      _iosCheckService = null;
    }
  }

  // ──────────────────────────────────────────
  // Events
  // ──────────────────────────────────────────

  /// Stream that emits whenever a fall alert is created.
  static Stream<void> get onAlertGenerated {
    if (Platform.isAndroid) {
      return _service.on(kEvtFallAlertGenerated).map((_) {});
    }
    return _iosAlertController.stream;
  }

  // ──────────────────────────────────────────
  // Android-specific start
  // ──────────────────────────────────────────

  static Future<bool> _startChecksAndroid({
    required String uid,
    required String locale,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefFallUid, uid);
      await prefs.setString(kPrefFallLocale, locale);

      if (await _service.isRunning()) {
        // Unified service already running (e.g. guardian mode active).
        // Send a start event so the background isolate picks up the new params.
        _service.invoke(kEvtFallStart, {});
        appLogger.info(
          'Fall detection: unified service already running — sent start event',
        );
        return true;
      }

      final started = await _service.startService();
      if (!started) {
        appLogger.warning(
          'Fall detection background service: startService() returned false',
        );
        return false;
      }
      return true;
    } on PlatformException catch (e, st) {
      appLogger.severe(
        'Fall detection background service: failed to start — ${e.message}',
        e,
        st,
      );
      return false;
    } catch (e, st) {
      appLogger.severe(
        'Fall detection background service: unexpected error on start',
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
    required String locale,
  }) async {
    try {
      _iosCheckService?.stop();
      _iosCheckService = null;

      final alertRepo = AlertRepositoryImpl(api: AlertApi());
      final userProfileRepo = UserProfileRepositoryImpl(api: UserProfileApi());

      final l10n = await AppLocalizations.delegate.load(Locale(locale));

      final checkService = FallDetectionCheckService(
        uid: uid,
        alertRepository: alertRepo,
        userProfileRepository: userProfileRepo,
        onAlertGenerated: () {
          _iosAlertController.add(null);
        },
        notificationTitleBuilder: l10n.notificationAlertTitle,
        notificationBodyBuilder: l10n.notificationFallDetectionBody,
      );

      checkService.start();
      _iosCheckService = checkService;

      appLogger.info('Fall detection iOS: check service started in main isolate');
      return true;
    } catch (e, st) {
      appLogger.severe(
        'Fall detection iOS: failed to start check service',
        e,
        st,
      );
      return false;
    }
  }
}
