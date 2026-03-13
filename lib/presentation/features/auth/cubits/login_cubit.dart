import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'login_state.dart';
part 'login_cubit.freezed.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
  }) : _authRepository = authRepository,
       _userProfileRepository = userProfileRepository,
       super(const LoginState());

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

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

      if (!user.emailVerified) {
        // ! Not send anothe one
        // await _authRepository.sendEmailVerificationLink();
        emit(state.copyWith(isLoading: false, requiresEmailVerification: true));
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

  Future<bool> checkEmailVerified() async {
    await _authRepository.reloadUser();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authRepository.sendEmailVerificationLink();
    } catch (_) {}
  }

  void clearVerificationFlag() {
    emit(state.copyWith(requiresEmailVerification: false));
  }

  Future<void> onGoogleLogin(AppLocalizations l10n) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _authRepository.loginWithGoogle();

      final user = result?.user;
      if (result == null || user == null) {
        if (!isClosed) {
          emit(
            state.copyWith(isLoading: false, errorMessage: l10n.loginFailed),
          );
        }
        return;
      }

      if (result.isNewUser) {
        final nameParts = (user.displayName ?? '').trim().split(' ');
        final name = nameParts.isNotEmpty ? nameParts.first : '';
        final surname = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : null;

        final profileResult = await _userProfileRepository.createProfile(
          UserProfile(
            uid: user.uid,
            name: name,
            surname: surname,
            profilePhoto: user.photoURL,
          ),
        );

        if (profileResult.isFailure) {
          if (!isClosed) {
            emit(
              state.copyWith(isLoading: false, errorMessage: l10n.loginFailed),
            );
          }
          return;
        }
      }

      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code, l10n);
      emit(state.copyWith(isLoading: false, errorMessage: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: l10n.loginFailed));
    }
  }

  Future<void> onForgotPassword(AppLocalizations l10n) async {
    final emailError = _validateEmail(state.email, l10n);
    if (emailError != null) {
      emit(state.copyWith(emailError: emailError));
      return;
    }

    emit(state.copyWith(emailError: null, isPasswordResetDialogReady: true));
  }

  Future<void> sendPasswordResetLink(AppLocalizations l10n) async {
    try {
      await _authRepository.sendPasswordResetLink(state.email);
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code, l10n);
      emit(state.copyWith(errorMessage: message));
    } catch (e) {
      emit(state.copyWith(errorMessage: l10n.loginFailed));
    }
  }

  void clearPasswordResetFlag() {
    emit(state.copyWith(isPasswordResetDialogReady: false));
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
