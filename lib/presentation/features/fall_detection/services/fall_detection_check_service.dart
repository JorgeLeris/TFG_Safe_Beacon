import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/notification_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Acceleration threshold (m/s² above gravity) that triggers a fall alert.
const kFallAccelerationThreshold = 30.0;

/// Manages accelerometer-based fall detection.
///
/// Subscribes to [accelerometerEventStream], computes the net acceleration
/// (removing gravity), and creates a [AlertType.sensors] alert when the
/// threshold is exceeded.
class FallDetectionCheckService {
  FallDetectionCheckService({
    required String uid,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
    required void Function() onAlertGenerated,
    required String Function(String name) notificationTitleBuilder,
    required String Function(String name) notificationBodyBuilder,
  })  : _uid = uid,
        _alertRepository = alertRepository,
        _userProfileRepository = userProfileRepository,
        _onAlertGenerated = onAlertGenerated,
        _notificationTitleBuilder = notificationTitleBuilder,
        _notificationBodyBuilder = notificationBodyBuilder;

  final String _uid;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;
  final void Function() _onAlertGenerated;
  final String Function(String name) _notificationTitleBuilder;
  final String Function(String name) _notificationBodyBuilder;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _alertAlreadySent = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // ==============================================
  // MARK: - Lifecycle
  // ==============================================

  /// Starts listening to accelerometer events for fall detection.
  void start() {
    stop();
    _alertAlreadySent = false;
    _isRunning = true;

    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerData,
      onError: (error) {
        appLogger.severe('Fall detection: accelerometer error — $error');
      },
    );

    appLogger.info('Fall detection check service started');
  }

  /// Stops the accelerometer subscription and resets state.
  void stop() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isRunning = false;
    appLogger.info('Fall detection check service stopped');
  }

  // ==============================================
  // MARK: - Sensor processing
  // ==============================================

  void _onAccelerometerData(AccelerometerEvent event) {
    if (_alertAlreadySent) return;

    final totalAccelWithGravity = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
    );

    final totalAccel = (totalAccelWithGravity - 9.8).abs();

    if (totalAccel >= kFallAccelerationThreshold) {
      appLogger.warning(
        'Fall detection: high acceleration detected '
        '(${totalAccel.toStringAsFixed(1)} m/s²)',
      );
      _onFallDetected();
    }
  }

  // ==============================================
  // MARK: - Alert creation
  // ==============================================

  Future<void> _onFallDetected() async {
    if (_alertAlreadySent) return;
    _alertAlreadySent = true;

    final profileResult = await _userProfileRepository.getProfile(_uid);
    String? username;
    String? name;
    profileResult.when(
      success: (profile) {
        username = profile.username ?? _uid;
        name = '${profile.name} ${profile.surname ?? ''}'.capitalized();
      },
      failure: (f) => appLogger.warning(
        'Fall detection: could not resolve profile for alert — $f',
      ),
    );
    if (username == null) {
      _alertAlreadySent = false;
      return;
    }

    final batteryLevel = await _fetchBatteryLevel();
    final position = await _fetchPosition();

    final createResult = await _alertRepository.createAlert(
      ownerUid: _uid,
      ownerUsername: username!,
      alertType: AlertType.sensors,
      latitude: position?.latitude ?? 0.0,
      longitude: position?.longitude ?? 0.0,
      batteryLevel: batteryLevel,
    );

    if (createResult.isFailure) {
      appLogger.warning(
        'Fall detection: failed to create alert — '
        '${(createResult as Failure).failure}',
      );
      _alertAlreadySent = false;
      return;
    }

    _onAlertGenerated();

    // Fetch the created alert to obtain trusted-contact list.
    final alertResult = await _alertRepository.getActiveAlert(
      _uid,
      alertType: AlertType.sensors,
    );
    final alertId = alertResult.valueOrNull?.id;
    final trustedContactUids =
        alertResult.valueOrNull?.trustedContactUids ?? <String>[];

    if (trustedContactUids.isEmpty) {
      appLogger.fine(
        'Fall detection alert created but no trusted contacts to notify',
      );
      return;
    }

    final tokensResult = await _userProfileRepository.getFcmTokensForUsers(
      trustedContactUids,
    );
    tokensResult.when(
      success: (tokens) {
        for (final token in tokens) {
          NotificationService().sendPushNotification(
            deviceToken: token,
            title: _notificationTitleBuilder(name!),
            body: _notificationBodyBuilder(name!),
            data: alertId != null ? {'alertId': alertId} : null,
          );
        }
        appLogger.info(
          'Fall detection alert notifications sent to ${tokens.length} contact(s)',
        );
      },
      failure: (f) => appLogger.warning(
        'Fall detection: failed to fetch FCM tokens — $f',
      ),
    );
  }

  // ==============================================
  // MARK: - Helpers
  // ==============================================

  Future<Position?> _fetchPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      appLogger.warning('Fall detection: could not fetch position — $e');
      return null;
    }
  }

  Future<int> _fetchBatteryLevel() async {
    try {
      return await Battery().batteryLevel;
    } catch (_) {
      return -1;
    }
  }
}
