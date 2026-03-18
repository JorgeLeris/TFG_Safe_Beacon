import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'protected_people_state.dart';
part 'protected_people_cubit.freezed.dart';

class ProtectedPeopleCubit extends Cubit<ProtectedPeopleState> {
  ProtectedPeopleCubit({
    required String uid,
    required UserProfileRepository userProfileRepository,
  }) : _uid = uid,
       _userProfileRepository = userProfileRepository,
       super(const ProtectedPeopleState());

  final String _uid;
  final UserProfileRepository _userProfileRepository;

  /// Loads the current user's username to display as a contact code.
  Future<void> loadUserCode() async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _userProfileRepository.getProfile(_uid);

    result.when(
      success: (profile) =>
          emit(state.copyWith(isLoading: false, username: profile.username)),
      failure: (failure) =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }
}
