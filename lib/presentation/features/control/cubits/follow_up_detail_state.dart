part of 'follow_up_detail_cubit.dart';

@freezed
abstract class FollowUpDetailState with _$FollowUpDetailState {
  const factory FollowUpDetailState({
    @Default(true) bool isLoading,
    GuardianSession? session,
    AppFailure? failure,
    @Default('') String displayName,
    String? profilePhoto,
  }) = _FollowUpDetailState;
}
