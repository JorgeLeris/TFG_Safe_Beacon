part of 'panic_button_cubit.dart';

/// Reason the panic button is in [PanicButtonState.disabled].
enum DisabledReason {
  /// User has no trusted contacts.
  noTrustedContacts,

  /// Location permission was denied but can still be requested via the OS dialog.
  locationPermissionDenied,

  /// Location permission was permanently denied; the user must open app settings.
  locationPermissionDeniedForever,
}

@freezed
abstract class PanicButtonCubitState with _$PanicButtonCubitState {
  const factory PanicButtonCubitState({
    /// True while the initial active-alert query is in progress.
    @Default(true) bool isLoading,

    /// True while the create-alert request is in flight.
    @Default(false) bool isActivating,

    /// True while the deactivate-alert request is in flight.
    @Default(false) bool isDeactivating,

    /// Current logical state of the panic button.
    @Default(PanicButtonState.loading) PanicButtonState buttonState,

    /// Why the button is disabled, when [buttonState] is [PanicButtonState.disabled].
    DisabledReason? disabledReason,

    /// When the current active alert was created.
    DateTime? activeAlertActivatedAt,

    /// Failure from the initial state load.
    AppFailure? failure,

    /// Failure from the last [activateAlert] call.
    AppFailure? activateFailure,

    /// Failure from the last [deactivateAlert] call.
    AppFailure? deactivateFailure,

    /// True if the user has denied location permission at least once in this session.
    @Default(false) bool permissionRequestDenied,
  }) = _PanicButtonCubitState;
}
