part of 'guardian_mode_cubit.dart';

/// Reason navigation to guardian mode is blocked.
enum GuardianModeBlockedReason {
  noTrustedContacts,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  fallDetectionRunning,
}

@freezed
abstract class GuardianModeCubitState with _$GuardianModeCubitState {
  const factory GuardianModeCubitState({
    // -- Navigation guard
    @Default(false) bool isChecking,
    @Default(false) bool canNavigate,
    GuardianModeBlockedReason? blockedReason,
    @Default(false) bool showPermissionDeniedDialog,
    @Default(false) bool permissionJustGranted,

    // -- Session load state
    @Default(true) bool isLoadingSession,

    // -- Session activation
    @Default(false) bool isActivating,
    AppFailure? activateFailure,

    // -- Session completion
    @Default(false) bool isCompleting,
    AppFailure? completeFailure,

    GuardianSession? activeSession,
    AppFailure? failure,

    // -- Guardian check alert
    List<GuardianSessionSecondaryStatus>? alertTriggerStatuses,

    // -- Pending form data (pre-activation)
    GuardianCoordinate? pendingDestination,
    Duration? pendingDuration,
    String? pendingDescription,
  }) = _GuardianModeCubitState;
}
