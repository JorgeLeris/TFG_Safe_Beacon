import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'follow_up_detail_state.dart';
part 'follow_up_detail_cubit.freezed.dart';

class FollowUpDetailCubit extends Cubit<FollowUpDetailState> {
  FollowUpDetailCubit({
    required String sessionId,
    required GuardianSessionRepository guardianSessionRepository,
    required UserProfileRepository userProfileRepository,
  }) : _sessionId = sessionId,
       _guardianSessionRepository = guardianSessionRepository,
       _userProfileRepository = userProfileRepository,
       super(const FollowUpDetailState());

  final String _sessionId;
  final GuardianSessionRepository _guardianSessionRepository;
  final UserProfileRepository _userProfileRepository;

  /// Loads the session details and resolves the owner's display name and photo.
  Future<void> loadFollowUpDetail() async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _guardianSessionRepository.getSessionDetails(
      _sessionId,
    );

    await result.when(
      success: (session) async {
        String displayName = session.ownerUid;
        String? profilePhoto;

        final profileResult = await _userProfileRepository.getProfile(
          session.ownerUid,
        );
        profileResult.when(
          success: (profile) {
            final name = profile.name;
            final surname = profile.surname ?? '';
            displayName = '$name $surname'.trim();
            profilePhoto = profile.profilePhoto;
          },
          failure: (_) {},
        );

        emit(
          state.copyWith(
            isLoading: false,
            session: session,
            displayName: displayName,
            profilePhoto: profilePhoto,
          ),
        );
      },
      failure: (failure) async =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }
}
