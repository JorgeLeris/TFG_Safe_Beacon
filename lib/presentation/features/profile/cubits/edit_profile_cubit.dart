import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'edit_profile_state.dart';
part 'edit_profile_cubit.freezed.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({
    required String uid,
    required UserProfileRepository userProfileRepository,
  }) : _uid = uid,
       _userProfileRepository = userProfileRepository,
       super(const EditProfileState());

  final String _uid;
  final UserProfileRepository _userProfileRepository;

  /// Saves the updated profile fields to the repository.
  Future<void> saveProfile({
    required String name,
    required String? surname,
    required String? birthDate,
    required String? gender,
    required String? description,
    required String? profilePhoto,
  }) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _userProfileRepository.updateProfile(
      UserProfile(
        uid: _uid,
        name: name,
        surname: surname,
        birthDate: birthDate,
        gender: gender,
        description: description,
        profilePhoto: profilePhoto,
      ),
    );

    result.when(
      success: (_) => emit(state.copyWith(isLoading: false, isSaved: true)),
      failure: (failure) =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }
}
