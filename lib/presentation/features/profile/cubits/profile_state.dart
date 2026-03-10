part of 'profile_cubit.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    UserProfile? userProfile,
    AppFailure? failure,
  }) = _ProfileState;
}
