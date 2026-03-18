part of 'protected_people_cubit.dart';

@freezed
abstract class ProtectedPeopleState with _$ProtectedPeopleState {
  const factory ProtectedPeopleState({
    @Default(false) bool isLoading,
    String? username,
    AppFailure? failure,
  }) = _ProtectedPeopleState;
}
