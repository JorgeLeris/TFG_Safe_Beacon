part of 'panic_button_cubit.dart';

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
    @Default(PanicButtonState.normal) PanicButtonState buttonState,

    /// When the current active alert was created.
    DateTime? activeAlertActivatedAt,

    /// Failure from the initial state load.
    AppFailure? failure,

    /// Failure from the last [activateAlert] call.
    AppFailure? activateFailure,

    /// Failure from the last [deactivateAlert] call.
    AppFailure? deactivateFailure,
  }) = _PanicButtonCubitState;
}
