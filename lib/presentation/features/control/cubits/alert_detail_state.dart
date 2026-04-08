part of 'alert_detail_cubit.dart';

@freezed
abstract class AlertDetailState with _$AlertDetailState {
  const factory AlertDetailState({
    @Default(true) bool isLoading,
    Alert? alert,
    AppFailure? failure,
    @Default('') String displayName,
  }) = _AlertDetailState;
}
