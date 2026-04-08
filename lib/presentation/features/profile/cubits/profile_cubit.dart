import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'profile_state.dart';
part 'profile_cubit.freezed.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required String uid,
    required UserProfileRepository userProfileRepository,
  }) : _uid = uid,
       _userProfileRepository = userProfileRepository,
       super(const ProfileState());

  final String _uid;
  final UserProfileRepository _userProfileRepository;

  /// Loads the current user's profile from the repository.
  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _userProfileRepository.getProfile(_uid);

    result.when(
      success: (profile) =>
          emit(state.copyWith(isLoading: false, userProfile: profile)),
      failure: (failure) =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }
}
