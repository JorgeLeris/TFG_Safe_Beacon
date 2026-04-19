import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/services/guardian_background_service.dart';

part 'guardian_mode_state.dart';
part 'guardian_mode_cubit.freezed.dart';

class GuardianModeCubit extends Cubit<GuardianModeCubitState> {
  GuardianModeCubit({
    required String uid,
    required ContactRepository contactRepository,
    required GuardianSessionRepository guardianSessionRepository,
    required AlertRepository alertRepository,
  }) : _uid = uid,
       _contactRepository = contactRepository,
       _guardianSessionRepository = guardianSessionRepository,
       _alertRepository = alertRepository,
       super(const GuardianModeCubitState()) {
    // Subscribe to alert events broadcast by the background isolate.
    _alertSubscription = GuardianBackgroundServiceManager.onAlertGenerated
        .listen(_onCheckAlertGenerated);
  }

  final String _uid;
  final ContactRepository _contactRepository;
  final GuardianSessionRepository _guardianSessionRepository;
  final AlertRepository _alertRepository;

  /// Subscription to guardian alert events from the background service.
  late final StreamSubscription<List<GuardianSessionSecondaryStatus>>
  _alertSubscription;

  // ==============================================
  // MARK: - Session loading
  // ==============================================

  /// Queries Firestore for an active guardian session and updates state.
  Future<void> loadSessionState() async {
    appLogger.fine('Loading guardian session state for uid: $_uid');
    emit(state.copyWith(isLoadingSession: true, failure: null));

    final result = await _guardianSessionRepository.getActiveSession(_uid);

    result.when(
      success: (session) {
        appLogger.info(
          session != null
              ? 'Active guardian session found for uid: $_uid'
              : 'No active guardian session for uid: $_uid',
        );

        // Restore alert-trigger statuses from the session's secondary statuses
        List<GuardianSessionSecondaryStatus>? restoredAlertStatuses;
        if (session != null) {
          final alertStatuses = session.secondaryStatuses
              .where(
                (s) =>
                    s == GuardianSessionSecondaryStatus.routeDeviation ||
                    s == GuardianSessionSecondaryStatus.estimatedTimeExceeded,
              )
              .toList();
          if (alertStatuses.isNotEmpty) {
            restoredAlertStatuses = alertStatuses;
          }
        }

        emit(
          state.copyWith(
            isLoadingSession: false,
            activeSession: session,
            alertTriggerStatuses: restoredAlertStatuses,
          ),
        );

        // Safety net: if no active session but the background service is still running
        if (session == null) {
          unawaited(
            GuardianBackgroundServiceManager.isRunning()
                .then((running) {
                  if (running) GuardianBackgroundServiceManager.stopChecks();
                })
                .then((_) {}),
          );
        }
      },
      failure: (failure) {
        appLogger.severe('Failed to load guardian session state', failure);
        emit(state.copyWith(isLoadingSession: false, failure: failure));
      },
    );
  }

  // ==============================================
  // MARK: - Session activation
  // ==============================================

  /// Creates a new guardian mode session using the current pending form data.
  ///
  /// On success, reloads the active session to populate [activeSession] with the server-assigned ID.
  Future<void> activateSession({
    required GuardianCoordinate initialLocation,
  }) async {
    final destination = state.pendingDestination;
    final duration = state.pendingDuration;
    if (duration == null) return;

    appLogger.fine('Activating guardian session for uid: $_uid');
    emit(state.copyWith(isActivating: true, activateFailure: null));

    final description = (state.pendingDescription?.trim().isNotEmpty ?? false)
        ? state.pendingDescription
        : null;

    final createResult = await _guardianSessionRepository.createSession(
      ownerUid: _uid,
      destination: destination,
      estimatedDuration: duration,
      initialLocation: initialLocation,
      description: description,
    );

    if (createResult is Failure) {
      appLogger.warning('Guardian session activation failed');
      emit(
        state.copyWith(
          isActivating: false,
          activateFailure: (createResult as Failure<void>).failure,
        ),
      );
      return;
    }

    // Fetch the newly created session.
    final sessionResult = await _guardianSessionRepository.getActiveSession(
      _uid,
    );
    final session = sessionResult.valueOrNull;
    appLogger.info('Guardian session activated for uid: $_uid');
    emit(state.copyWith(isActivating: false, activeSession: session));
  }

  // ==============================================
  // MARK: - Session completion
  // ==============================================

  /// Completes the active guardian session.
  ///
  /// [completionStatus] must be [GuardianSessionSecondaryStatus.completedByArrival]
  /// or [GuardianSessionSecondaryStatus.completedByCancellation].
  Future<void> completeSession({
    required GuardianSessionSecondaryStatus completionStatus,
    String? completionJustification,
  }) async {
    appLogger.fine(
      'Completing guardian session for uid: $_uid (${completionStatus.id})',
    );

    // Stop the check loop.
    unawaited(GuardianBackgroundServiceManager.stopChecks());

    // Deactivate any linked alert in the background.
    final sessionId = state.activeSession?.id;
    if (sessionId != null) {
      unawaited(
        _alertRepository
            .deactivateAlertByGuardianSession(guardianSessionId: sessionId)
            .then(
              (result) => result.onFailure(
                (f) => appLogger.warning(
                  'Failed to deactivate guardian alert on completion: $f',
                ),
              ),
            ),
      );
    }

    emit(state.copyWith(isCompleting: true, completeFailure: null));

    final result = await _guardianSessionRepository.completeSession(
      ownerUid: _uid,
      completionStatus: completionStatus,
      completionJustification: completionJustification,
    );

    result.when(
      success: (_) {
        appLogger.info('Guardian session completed for uid: $_uid');
        emit(
          state.copyWith(
            isCompleting: false,
            activeSession: null,
            alertTriggerStatuses: null,
            pendingDestination: null,
            pendingDuration: null,
            pendingDescription: null,
          ),
        );
      },
      failure: (failure) {
        appLogger.severe('Failed to complete guardian session', failure);
        emit(state.copyWith(isCompleting: false, completeFailure: failure));
      },
    );
  }

  void consumeCompleteFailure() {
    emit(state.copyWith(completeFailure: null));
  }

  // ==============================================
  // MARK: - Guardian check service
  // ==============================================

  /// Starts the background check loop for the currently active session.
  ///
  /// [routePoints] is the OSRM polyline from the map widget (empty list when
  /// the route could not be fetched — straight-line mode applies).
  ///
  /// If the background service is already running this is a no-op.
  Future<void> startChecks({
    required List<LatLng> routePoints,
    required String locale,
  }) async {
    final session = state.activeSession;
    if (session == null) return;
    await GuardianBackgroundServiceManager.startChecks(
      uid: _uid,
      routePoints: routePoints,
      locale: locale,
    );
  }

  /// Stops the background check loop.
  ///
  /// Called automatically by [completeSession].
  void stopChecks() {
    unawaited(GuardianBackgroundServiceManager.stopChecks());
  }

  /// Forwards an updated route polyline to the running background service.
  void updateCheckRoutePoints(List<LatLng> routePoints) {
    unawaited(GuardianBackgroundServiceManager.updateRoutePoints(routePoints));
  }

  /// Called by [GuardianModeCheckService] when a guardian alert is created.
  void _onCheckAlertGenerated(List<GuardianSessionSecondaryStatus> statuses) {
    appLogger.info('Guardian alert generated — updating state');
    emit(state.copyWith(alertTriggerStatuses: statuses));
  }

  @override
  Future<void> close() {
    _alertSubscription.cancel();
    return super.close();
  }

  // ==============================================
  // MARK: - Pending form state
  // ==============================================

  void updatePendingDestination(GuardianCoordinate? destination) {
    emit(state.copyWith(pendingDestination: destination));
  }

  void updatePendingDuration(Duration? duration) {
    emit(state.copyWith(pendingDuration: duration));
  }

  void updatePendingDescription(String? description) {
    emit(state.copyWith(pendingDescription: description));
  }

  void consumeActivateFailure() {
    emit(state.copyWith(activateFailure: null));
  }

  // ==============================================
  // MARK: - Navigation guard
  // ==============================================

  /// Checks prerequisites (location permission + trusted contacts) before
  /// allowing navigation to the guardian mode screen.
  Future<void> requestNavigate() async {
    // TODO: manage disable case in feature configuration - add to state other disabled cases (more permission cases)
    emit(
      state.copyWith(
        isChecking: true,
        canNavigate: false,
        blockedReason: null,
        showPermissionDeniedDialog: false,
      ),
    );

    // Check location permission first.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason: GuardianModeBlockedReason.locationPermissionDenied,
        ),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason:
              GuardianModeBlockedReason.locationPermissionDeniedForever,
        ),
      );
      return;
    }

    // Check that the user has at least one trusted contact.
    final contactsResult = await _contactRepository.getTrustedContacts(_uid);
    final hasContacts = contactsResult.when(
      success: (list) => list.isNotEmpty,
      failure: (_) => true,
    );

    if (!hasContacts) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason: GuardianModeBlockedReason.noTrustedContacts,
        ),
      );
      return;
    }

    emit(state.copyWith(isChecking: false, canNavigate: true));
  }

  /// Clears [canNavigate] after the navigation event has been consumed.
  void consumeNavigation() {
    emit(state.copyWith(canNavigate: false));
  }

  /// Clears [blockedReason] after the dialog has been consumed.
  void consumeBlockedReason() {
    emit(state.copyWith(blockedReason: null));
  }

  // ==============================================
  // MARK: - Location permission helpers
  // ==============================================

  /// Triggers the native OS location-permission dialog.
  Future<void> requestLocationPermission() async {
    emit(state.copyWith(blockedReason: null));
    final result = await Geolocator.requestPermission();
    if (result == LocationPermission.denied ||
        result == LocationPermission.deniedForever) {
      emit(state.copyWith(showPermissionDeniedDialog: true));
      return;
    }
    emit(state.copyWith(permissionJustGranted: true));
    await requestNavigate();
  }

  /// Clears [permissionJustGranted] after the event has been consumed.
  void consumePermissionGranted() {
    emit(state.copyWith(permissionJustGranted: false));
  }

  /// Opens the app settings page so the user can manually re-grant location access.
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
    emit(const GuardianModeCubitState());
  }
}
