import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';

part 'logout_state.dart';
part 'logout_cubit.freezed.dart';

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const LogoutState());

  final AuthRepository _authRepository;

  Future<void> onLogout(AppLocalizations l10n) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await _authRepository.logout();
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: l10n.logoutFailed));
    }
  }
}
