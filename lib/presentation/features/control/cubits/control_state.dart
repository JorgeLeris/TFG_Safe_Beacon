part of 'control_cubit.dart';

@freezed
abstract class ControlState with _$ControlState {
  const factory ControlState({
    @Default(false) bool isLoadingCount,
    @Default(false) bool isApplyingFilters,
    @Default(0) int receivedRequestsCount,
    AppFailure? countFailure,
    @Default(false) bool isLoadingAlerts,
    @Default([]) List<Alert> alerts,
    AppFailure? alertsFailure,
    @Default({}) Map<String, String> alertDisplayNames,
    @Default({}) Map<String, String> alertProfilePhotos,
    @Default(false) bool isLoadingFollowUps,
    @Default([]) List<GuardianSession> followUps,
    AppFailure? followUpsFailure,
    @Default({}) Map<String, String> followUpDisplayNames,
    @Default({}) Map<String, String> followUpProfilePhotos,
  }) = _ControlState;
}
