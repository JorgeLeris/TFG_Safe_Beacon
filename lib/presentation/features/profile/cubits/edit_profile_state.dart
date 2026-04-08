part of 'edit_profile_cubit.dart';

@freezed
abstract class EditProfileState with _$EditProfileState {
  const factory EditProfileState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaved,
    AppFailure? failure,
  }) = _EditProfileState;
}
