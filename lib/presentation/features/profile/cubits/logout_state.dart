part of 'logout_cubit.dart';

@freezed
abstract class LogoutState with _$LogoutState {
  const factory LogoutState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _LogoutState;
}
