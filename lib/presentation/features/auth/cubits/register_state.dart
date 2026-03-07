part of 'register_cubit.dart';

@freezed
abstract class RegisterState with _$RegisterState {
  const factory RegisterState({
    // Step 1 - RegisterScreen
    @Default('') String email,
    @Default('') String password,
    @Default('') String confirmPassword,

    // Step 2 - RegisterAddDataScreen
    @Default('') String name,
    @Default('') String surname,
    DateTime? birthDate,
    String? gender,
    @Default('') String description,

    // Common
    @Default(false) bool isGoogleRegister,
    @Default(false) bool isLoading,
    String? errorMessage,

    // Errors step 1
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,

    // Errors step 2
    String? nameError,
    String? surnameError,
    String? birthDateError,
    String? genderError,

    // Navigation trigger
    @Default(false) bool step1Completed,
  }) = _RegisterState;
}
