import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.dart';
part 'login_cubit.freezed.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void onEmailChanged(String value) {
    emit(state.copyWith(email: value, errorMessage: null));
  }

  void onPasswordChanged(String value) {
    emit(state.copyWith(password: value, errorMessage: null));
  }

  void onSubmit() {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    Future.delayed(const Duration(seconds: 2), () {
      emit(state.copyWith(isLoading: false));
    });
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
