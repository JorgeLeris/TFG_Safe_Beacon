import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/notification_service.dart';

// TODO(background): Once background execution is implemented this is going to change
/// Interval between periodic guardian checks.
const _kCheckInterval = Duration(minutes: 1);

/// Maximum distance in metres from a OSRM route before flagging a deviation.
const _kRealRouteBufferMeters = 150.0;

/// Maximum distance in metres from a straight-line path before flagging a deviation.
const _kStraightLineBufferMeters = 500.0;

/// Manages the periodic checks performed during an active guardian mode session.
///
/// Instantiate once per [GuardianModeCubit] and call [start] / [stop] to control the check loop.
class GuardianModeCheckService {
  GuardianModeCheckService({
    required String uid,
    required GuardianSessionRepository guardianSessionRepository,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
    required void Function(List<GuardianSessionSecondaryStatus> statuses)
    onAlertGenerated,
  }) : _uid = uid,
       _guardianSessionRepository = guardianSessionRepository,
       _alertRepository = alertRepository,
       _userProfileRepository = userProfileRepository,
       _onAlertGenerated = onAlertGenerated;

  final String _uid;
  final GuardianSessionRepository _guardianSessionRepository;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;
  final void Function(List<GuardianSessionSecondaryStatus> statuses)
  _onAlertGenerated;

  Timer? _checkTimer;
  GuardianSession? _session;
  List<LatLng> _routePoints = [];
  bool _hasRealRoute = false;
  bool _alertAlreadySent = false;

  /// Notification string builders provided by the presentation layer.
  String Function(String name)? _notificationTitleBuilder;
  String Function(String name)? _notificationBodyBuilder;

  bool get isRunning => _checkTimer != null;

  // ==============================================
  // MARK: - Lifecycle
  // ==============================================

  /// Starts the periodic check loop for [session].
  ///
  /// [routePoints] must be the OSRM polyline returned by the map widget.
  /// Is an empty list when the route could not be fetched (straight-line mode).
  ///
  /// [notificationTitleBuilder] and [notificationBodyBuilder] are called with
  /// the user's display name to produce push-notification content.
  void start({
    required GuardianSession session,
    required List<LatLng> routePoints,
    required String Function(String name) notificationTitleBuilder,
    required String Function(String name) notificationBodyBuilder,
  }) {
    stop();
    _session = session;
    _routePoints = List.of(routePoints);
    _hasRealRoute = routePoints.isNotEmpty;
    _alertAlreadySent = false;
    _notificationTitleBuilder = notificationTitleBuilder;
    _notificationBodyBuilder = notificationBodyBuilder;

    appLogger.info(
      'Guardian check service started '
      '(session: ${session.id}, real route: $_hasRealRoute, '
      'interval: ${_kCheckInterval.inSeconds}s)',
    );

    _checkTimer = Timer.periodic(_kCheckInterval, (_) => _runCheck());
  }

  /// Updates the route polyline used for deviation detection while running.
  void updateRoutePoints(List<LatLng> routePoints) {
    if (!isRunning) return;
    _routePoints = List.of(routePoints);
    _hasRealRoute = routePoints.isNotEmpty;
    appLogger.fine(
      'Guardian check service: route updated '
      '(${_routePoints.length} points, real: $_hasRealRoute)',
    );
  }

  /// Stops the periodic check loop and clears all internal state.
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _session = null;
    appLogger.info('Guardian check service stopped');
  }

  // ==============================================
  // MARK: - Check logic
  // ==============================================

  Future<void> _runCheck() async {
    final session = _session;
    if (session == null) return;

    appLogger.fine('Running guardian check (session: ${session.id})');

    // 1. Get current position.
    final position = await _fetchPosition();
    final currentLatLng = position != null
        ? LatLng(position.latitude, position.longitude)
        : null;

    // 2. Evaluate checks and collect newly triggered statuses.
    final newStatuses = <GuardianSessionSecondaryStatus>[];

    // --- Estimated time exceeded ---
    final elapsed = DateTime.now().difference(session.activatedAt);
    if (elapsed > session.estimatedDuration &&
        !session.secondaryStatuses.contains(
          GuardianSessionSecondaryStatus.estimatedTimeExceeded,
        )) {
      appLogger.warning(
        'Guardian: estimated time exceeded '
        '(elapsed ${elapsed.inMinutes}min > '
        'estimated ${session.estimatedDuration.inMinutes}min)',
      );
      newStatuses.add(GuardianSessionSecondaryStatus.estimatedTimeExceeded);
    }

    // --- Route deviation ---
    if (currentLatLng != null &&
        _isOutOfBounds(currentLatLng, session) &&
        !session.secondaryStatuses.contains(
          GuardianSessionSecondaryStatus.routeDeviation,
        )) {
      appLogger.warning('Guardian: route deviation detected');
      newStatuses.add(GuardianSessionSecondaryStatus.routeDeviation);
    }

    // 3. Always update session location; also append new secondary statuses.
    final updatedLocation = currentLatLng != null
        ? GuardianCoordinate(
            latitude: currentLatLng.latitude,
            longitude: currentLatLng.longitude,
          )
        : session.currentLocation;

    await _guardianSessionRepository.updateSession(
      sessionId: session.id,
      newLocation: updatedLocation,
      newSecondaryStatuses: newStatuses.isEmpty ? null : newStatuses,
    );

    // 4. Keep local session snapshot up-to-date so we don't re-flag statuses.
    _session = GuardianSession(
      id: session.id,
      ownerUid: session.ownerUid,
      trustedContactUids: session.trustedContactUids,
      status: session.status,
      secondaryStatuses: [...session.secondaryStatuses, ...newStatuses],
      originLocation: session.originLocation,
      currentLocation: updatedLocation,
      destination: session.destination,
      estimatedDuration: session.estimatedDuration,
      description: session.description,
      completionJustification: session.completionJustification,
      activatedAt: session.activatedAt,
      deactivatedAt: session.deactivatedAt,
      lastLocationTimestamp: DateTime.now(),
    );

    // 5. Create guardian alert if any check triggered (once per session).
    if (newStatuses.isNotEmpty && !_alertAlreadySent) {
      await _createAlert(
        session: session,
        position: position,
        newStatuses: newStatuses,
      );
    }
  }

  Future<void> _createAlert({
    required GuardianSession session,
    required Position? position,
    required List<GuardianSessionSecondaryStatus> newStatuses,
  }) async {
    appLogger.fine(
      'Creating guardian alert '
      '(session: ${session.id}, '
      'statuses: ${newStatuses.map((s) => s.id).join(', ')})',
    );

    // Resolve user profile for the alert and notification content.
    final profileResult = await _userProfileRepository.getProfile(_uid);
    String? username;
    String? name;
    profileResult.when(
      success: (profile) {
        username = profile.username ?? _uid;
        name = '${profile.name} ${profile.surname ?? ''}'.capitalized();
      },
      failure: (f) => appLogger.warning(
        'Guardian check: could not resolve profile for alert — $f',
      ),
    );
    if (username == null) return;

    final batteryLevel = await _fetchBatteryLevel();

    // Create the alert linked to this guardian session.
    final createResult = await _alertRepository.createAlert(
      ownerUid: _uid,
      ownerUsername: username!,
      alertType: AlertType.guardian,
      latitude: position?.latitude ?? 0.0,
      longitude: position?.longitude ?? 0.0,
      batteryLevel: batteryLevel,
      guardianSessionId: session.id,
    );

    if (createResult.isFailure) {
      appLogger.warning(
        'Guardian check: failed to create alert — '
        '${(createResult as Failure).failure}',
      );
      return;
    }

    // Mark as sent so subsequent checks do not create additional alerts.
    _alertAlreadySent = true;
    _onAlertGenerated(newStatuses);

    // Fetch the created alert to obtain its ID and trusted-contact list.
    final alertResult = await _alertRepository.getActiveAlert(_uid);
    final alertId = alertResult.valueOrNull?.id;
    final trustedContactUids =
        alertResult.valueOrNull?.trustedContactUids ?? <String>[];

    if (trustedContactUids.isEmpty) {
      appLogger.fine(
        'Guardian alert created but no trusted contacts to notify',
      );
      return;
    }

    // Fetch FCM tokens and send push notifications.
    final tokensResult = await _userProfileRepository.getFcmTokensForUsers(
      trustedContactUids,
    );
    tokensResult.when(
      success: (tokens) {
        for (final token in tokens) {
          NotificationService().sendPushNotification(
            deviceToken: token,
            title: _notificationTitleBuilder?.call(name!) ?? name!,
            body: _notificationBodyBuilder?.call(name!) ?? name!,
            data: alertId != null ? {'alertId': alertId} : null,
          );
        }
        appLogger.info(
          'Guardian alert notifications sent to ${tokens.length} contact(s) '
          '(session: ${session.id})',
        );
      },
      failure: (f) =>
          appLogger.warning('Guardian check: failed to fetch FCM tokens — $f'),
    );
  }

  // ==============================================
  // MARK: - Route deviation helpers
  // ==============================================

  bool _isOutOfBounds(LatLng location, GuardianSession session) {
    if (_hasRealRoute && _routePoints.isNotEmpty) {
      return _distanceToPolyline(location, _routePoints) >
          _kRealRouteBufferMeters;
    }

    // Straight-line fallback
    final destination = session.destination;
    if (destination == null) return false;

    final origin = LatLng(
      session.originLocation.latitude,
      session.originLocation.longitude,
    );
    final dest = LatLng(destination.latitude, destination.longitude);
    return _distanceToPolyline(location, [origin, dest]) >
        _kStraightLineBufferMeters;
  }

  /// Returns the minimum distance in metres from [point] to any segment of
  /// the given [polyline].
  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return 0;
    if (polyline.length == 1) return const Distance()(point, polyline.first);

    var minDist = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Distance in metres from [p] to the segment [a]->[b].
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    const metersPerDegLat = 111320.0;
    final cosLat = cos(a.latitudeInRad);
    final metersPerDegLng = metersPerDegLat * cosLat;

    final px = (p.longitude - a.longitude) * metersPerDegLng;
    final py = (p.latitude - a.latitude) * metersPerDegLat;
    final bx = (b.longitude - a.longitude) * metersPerDegLng;
    final by = (b.latitude - a.latitude) * metersPerDegLat;

    final lenSq = bx * bx + by * by;
    if (lenSq == 0) return sqrt(px * px + py * py);

    final t = ((px * bx + py * by) / lenSq).clamp(0.0, 1.0);
    final dx = px - t * bx;
    final dy = py - t * by;
    return sqrt(dx * dx + dy * dy);
  }

  // ==============================================
  // MARK: - Platform helpers
  // ==============================================

  Future<Position?> _fetchPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e, st) {
      appLogger.warning('Guardian check: failed to fetch position', e, st);
      return null;
    }
  }

  Future<int> _fetchBatteryLevel() async {
    try {
      return await Battery().batteryLevel;
    } catch (e, st) {
      appLogger.warning('Guardian check: failed to fetch battery level', e, st);
      return 0;
    }
  }
}
