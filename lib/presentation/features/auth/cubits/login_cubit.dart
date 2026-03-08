import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';

part 'login_state.dart';
part 'login_cubit.freezed.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const LoginState());

  final AuthRepository _authRepository;

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
      final user = await _authRepository.loginWithCredential(
        state.email,
        state.password,
      );

      if (user == null) {
        emit(state.copyWith(isLoading: false, errorMessage: l10n.loginFailed));
        return;
      }

      emit(state.copyWith(isLoading: false));
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code, l10n);
      emit(state.copyWith(isLoading: false, errorMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: l10n.loginFailed));
    }
  }

  Future<void> onGoogleLogin(AppLocalizations l10n) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await _authRepository.loginWithGoogle();

      // TODO: Save all posible data from google user, the data other null

      if (user == null) {
        emit(state.copyWith(isLoading: false, errorMessage: l10n.loginFailed));
        return;
      }

      emit(state.copyWith(isLoading: false));
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code, l10n);
      emit(state.copyWith(isLoading: false, errorMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: l10n.loginFailed));
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

  // MARK: Map Firebase errors

  String _mapFirebaseError(String code, AppLocalizations l10n) {
    switch (code) {
      case 'user-not-found':
        return l10n.loginUserNotFound;
      case 'wrong-password':
        return l10n.loginInvalidPassword;
      case 'invalid-credential':
        return l10n.loginInvalidCredentials;
      case 'user-disabled':
        return l10n.loginUserDisabled;
      case 'too-many-requests':
        return l10n.loginTooManyRequests;
      default:
        return l10n.loginFailed;
    }
  }
}
