part of 'control_cubit.dart';

@freezed
abstract class ControlState with _$ControlState {
  const factory ControlState({
    @Default(false) bool isLoadingCount,
    @Default(0) int receivedRequestsCount,
    AppFailure? countFailure,
  }) = _ControlState;
}
