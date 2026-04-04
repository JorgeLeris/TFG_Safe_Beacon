import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'logout_state.dart';
part 'logout_cubit.freezed.dart';

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit({
    required AuthRepository authRepository,
    required UserProfileRepository userProfileRepository,
  }) : _authRepository = authRepository,
       _userProfileRepository = userProfileRepository,
       super(const LogoutState());

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  Future<void> onLogout(AppLocalizations l10n) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Clear FCM token before signing out.
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _userProfileRepository.clearFcmToken(uid, token);
        }
      }
    } catch (_) {}

    try {
      await _authRepository.logout();
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: l10n.logoutFailed));
    }
  }
}
