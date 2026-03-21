import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request_item.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'protected_people_state.dart';
part 'protected_people_cubit.freezed.dart';

class ProtectedPeopleCubit extends Cubit<ProtectedPeopleState> {
  ProtectedPeopleCubit({
    required String uid,
    required UserProfileRepository userProfileRepository,
    required ContactRequestRepository contactRequestRepository,
  }) : _uid = uid,
       _userProfileRepository = userProfileRepository,
       _contactRequestRepository = contactRequestRepository,
       super(const ProtectedPeopleState());

  final String _uid;
  final UserProfileRepository _userProfileRepository;
  final ContactRequestRepository _contactRequestRepository;

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

  /// Loads the list of contact requests received by the current user.
  Future<void> loadReceivedRequests() async {
    emit(
      state.copyWith(
        isLoadingReceivedRequests: true,
        receivedRequestsFailure: null,
      ),
    );

    final result = await _contactRequestRepository.getReceivedRequests(_uid);

    await result.when(
      success: (requests) async {
        final items = await Future.wait(
          requests.map((r) async {
            String? photo;
            String? name;
            final profileResult = await _userProfileRepository.getProfile(
              r.senderUid,
            );
            profileResult.when(
              success: (profile) {
                photo = profile.profilePhoto;
                name = '${profile.name} ${profile.surname}'.capitalized();
              },
              failure: (_) {
                photo = null;
                name = null;
              },
            );
            return ContactRequestItem(
              requestId: r.id,
              direction: ContactRequestDirection.received,
              peerUid: r.senderUid,
              peerUsername: name ?? r.senderUsername,
              peerPhoto: photo,
            );
          }),
        );
        emit(
          state.copyWith(
            isLoadingReceivedRequests: false,
            receivedRequests: items,
          ),
        );
      },
      failure: (failure) async => emit(
        state.copyWith(
          isLoadingReceivedRequests: false,
          receivedRequestsFailure: failure,
        ),
      ),
    );
  }

  /// Deletes a received contact request identified by [requestId].
  Future<void> deleteReceivedRequest(String requestId) async {
    emit(state.copyWith(isDeletingRequest: true, deleteRequestFailure: null));

    final result = await _contactRequestRepository.deleteRequest(
      requestId: requestId,
      requesterUid: _uid,
    );

    result.when(
      success: (_) {
        final updated = state.receivedRequests
            .where((r) => r.requestId != requestId)
            .toList();
        emit(
          state.copyWith(isDeletingRequest: false, receivedRequests: updated),
        );
      },
      failure: (failure) => emit(
        state.copyWith(isDeletingRequest: false, deleteRequestFailure: failure),
      ),
    );
  }

  /// Clears a previous delete request failure from the state.
  void clearDeleteRequestFailure() {
    emit(state.copyWith(deleteRequestFailure: null));
  }
}
