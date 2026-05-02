part of 'fall_detection_cubit.dart';

/// Visual / logical status of the fall detection feature.
enum FallDetectionStatus {
  loading,
  disabled,
  inactive,
  active,
  alertActive,
}

/// Reason why fall detection cannot be enabled.
enum FallDetectionDisabledReason {
  noTrustedContacts,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  guardianModeRunning,
}

@freezed
abstract class FallDetectionCubitState with _$FallDetectionCubitState {
  const factory FallDetectionCubitState({
    @Default(FallDetectionStatus.loading) FallDetectionStatus status,
    FallDetectionDisabledReason? disabledReason,
    @Default(false) bool isActivating,
    @Default(false) bool isDeactivating,
    AppFailure? failure,
    @Default(false) bool permissionRequestDenied,
  }) = _FallDetectionCubitState;
}
