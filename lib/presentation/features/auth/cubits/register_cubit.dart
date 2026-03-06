import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_state.dart';
part 'register_cubit.freezed.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({bool isGoogleRegister = false})
    : super(RegisterState(isGoogleRegister: isGoogleRegister));

  // Step 1
  void onEmailChanged(String value) =>
      emit(state.copyWith(email: value, errorMessage: null));

  void onPasswordChanged(String value) =>
      emit(state.copyWith(password: value, errorMessage: null));

  void onConfirmPasswordChanged(String value) =>
      emit(state.copyWith(confirmPassword: value, errorMessage: null));

  // Step 2
  void onNameChanged(String value) =>
      emit(state.copyWith(name: value, errorMessage: null));

  void onSurnameChanged(String value) =>
      emit(state.copyWith(surname: value, errorMessage: null));

  void onBirthDateChanged(DateTime? value) =>
      emit(state.copyWith(birthDate: value, errorMessage: null));

  void onGenderChanged(String? value) =>
      emit(state.copyWith(gender: value, errorMessage: null));

  void onDescriptionChanged(String value) =>
      emit(state.copyWith(description: value, errorMessage: null));

  // Common
  void onSubmit() {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    Future.delayed(const Duration(seconds: 2), () {
      emit(state.copyWith(isLoading: false));
    });
  }

  void clearError() => emit(state.copyWith(errorMessage: null));
}
