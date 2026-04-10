part of 'guardian_mode_cubit.dart';

/// Reason navigation to guardian mode is blocked.
enum GuardianModeBlockedReason {
  noTrustedContacts,
  locationPermissionDenied,
  locationPermissionDeniedForever,
}

@freezed
abstract class GuardianModeCubitState with _$GuardianModeCubitState {
  const factory GuardianModeCubitState({
    @Default(false) bool isChecking,
    @Default(false) bool canNavigate,
    GuardianModeBlockedReason? blockedReason,
    @Default(false) bool showPermissionDeniedDialog,
    @Default(false) bool permissionJustGranted,
  }) = _GuardianModeCubitState;
}
