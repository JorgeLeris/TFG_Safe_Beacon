import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'register_state.dart';
part 'register_cubit.freezed.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
  }) : _authRepository = authRepository,
       _userProfileRepository = userProfileRepository,
       super(const RegisterState());

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  // MARK: Step 1 - RegisterScreen

  void onEmailChanged(String value) => emit(state.copyWith(email: value));

  void onPasswordChanged(String value) => emit(state.copyWith(password: value));

  void onConfirmPasswordChanged(String value) =>
      emit(state.copyWith(confirmPassword: value));

  /// Validate step 1.
  void onNextStep(AppLocalizations l10n) {
    clearErrors();

    final emailError = _validateEmail(state.email, l10n);
    final passwordError = _validatePassword(state.password, l10n);
    final confirmPasswordError = _validateConfirmPassword(
      state.password,
      state.confirmPassword,
      l10n,
    );

    if (emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      emit(
        state.copyWith(
          emailError: emailError,
          passwordError: passwordError,
          confirmPasswordError: confirmPasswordError,
        ),
      );
      return;
    }

    emit(state.copyWith(step1Completed: true));
  }

  // MARK: Step 2 - RegisterAddDataScreen

  void onNameChanged(String value) => emit(state.copyWith(name: value));

  void onSurnameChanged(String value) => emit(state.copyWith(surname: value));

  void onBirthDateChanged(DateTime? value) =>
      emit(state.copyWith(birthDate: value));

  void onGenderChanged(String? value) => emit(state.copyWith(gender: value));

  void onDescriptionChanged(String value) =>
      emit(state.copyWith(description: value));

  /// Validate step 2 and submit registration.
  Future<void> onSubmit(AppLocalizations l10n) async {
    clearErrors();

    final nameError = _validateRequired(state.name, l10n.nameRequired);
    final surnameError = _validateRequired(state.surname, l10n.surnameRequired);
    final birthDateError = state.birthDate == null
        ? l10n.birthDateRequired
        : null;
    final genderError = state.gender == null ? l10n.genderRequired : null;

    if (nameError != null ||
        surnameError != null ||
        birthDateError != null ||
        genderError != null) {
      emit(
        state.copyWith(
          nameError: nameError,
          surnameError: surnameError,
          birthDateError: birthDateError,
          genderError: genderError,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await _authRepository.createUserWithCredential(
        state.email,
        state.password,
      );

      if (user == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: l10n.registrationFailed,
          ),
        );
        return;
      }

      final profileResult = await _userProfileRepository.createProfile(
        UserProfile(
          uid: user.uid,
          name: state.name.trim(),
          surname: state.surname.trim(),
          gender: state.gender,
          birthDate: state.birthDate?.toStringDate(),
          description: state.description.trim(),
        ),
      );

      if (profileResult.isFailure) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: l10n.registrationFailed,
          ),
        );
        return;
      }

      emit(state.copyWith(isLoading: false));
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code, l10n);
      emit(state.copyWith(isLoading: false, errorMessage: message));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: l10n.registrationFailed),
      );
    }
  }

  void clearErrors() {
    emit(
      state.copyWith(
        errorMessage: null,
        emailError: null,
        passwordError: null,
        confirmPasswordError: null,
        nameError: null,
        surnameError: null,
        birthDateError: null,
        genderError: null,
        step1Completed: false,
      ),
    );
  }

  // MARK: Validation fields

  String? _validateEmail(String value, AppLocalizations l10n) {
    if (value.trim().isEmpty) return l10n.emailRequired;
    if (!Constants.emailRegex.hasMatch(value.trim())) return l10n.emailInvalid;
    return null;
  }

  String? _validatePassword(String value, AppLocalizations l10n) {
    if (value.isEmpty) return l10n.passwordRequired;
    if (value.length < 6) return l10n.passwordInvalid;
    return null;
  }

  String? _validateConfirmPassword(
    String password,
    String confirm,
    AppLocalizations l10n,
  ) {
    if (confirm.isEmpty) return l10n.confirmPasswordRequired;
    if (confirm != password) return l10n.passwordsDoNotMatch;
    return null;
  }

  String? _validateRequired(String value, String errorMessage) {
    if (value.trim().isEmpty) return errorMessage;
    return null;
  }

  // MARK: Map Firebase errors
  String _mapFirebaseError(String code, AppLocalizations l10n) {
    switch (code) {
      case 'email-already-in-use':
        return l10n.registerEmailAlreadyInUse;
      case 'invalid-email':
        return l10n.emailInvalid;
      case 'weak-password':
        return l10n.registerWeakPassword;
      case 'too-many-requests':
        return l10n.loginTooManyRequests;
      default:
        return l10n.registrationFailed;
    }
  }
}
