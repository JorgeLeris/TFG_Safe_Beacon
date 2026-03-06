import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

part 'login_state.dart';
part 'login_cubit.freezed.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void onEmailChanged(String value) {
    emit(state.copyWith(email: value));
  }

  void onPasswordChanged(String value) {
    emit(state.copyWith(password: value));
  }

  Future<void> onSubmit(AppLocalizations l10n) async {
    clearErrors();

    final emailError = _validateEmail(state.email, l10n);
    final passwordError = _validatePassword(state.password, l10n);

    if (emailError != null || passwordError != null) {
      emit(
        state.copyWith(emailError: emailError, passwordError: passwordError),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // TODO: reemplazar con el caso de uso real
      await Future.delayed(const Duration(seconds: 2));

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearErrors() {
    emit(
      state.copyWith(errorMessage: null, emailError: null, passwordError: null),
    );
  }

  // MARK: Validation fields

  String? _validateEmail(String value, AppLocalizations l10n) {
    if (value.trim().isEmpty) return l10n.emailRequired;
    final emailRegex = Constants.emailRegex;
    if (!emailRegex.hasMatch(value.trim())) return l10n.emailInvalid;
    return null;
  }

  String? _validatePassword(String value, AppLocalizations l10n) {
    if (value.isEmpty) return l10n.passwordRequired;
    if (value.length < 6) return l10n.passwordInvalid;
    return null;
  }
}
