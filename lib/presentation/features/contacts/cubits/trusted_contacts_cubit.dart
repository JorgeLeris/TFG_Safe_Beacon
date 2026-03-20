import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request_item.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'trusted_contacts_state.dart';
part 'trusted_contacts_cubit.freezed.dart';

class TrustedContactsCubit extends Cubit<TrustedContactsState> {
  TrustedContactsCubit({
    required String uid,
    required UserProfileRepository userProfileRepository,
    required ContactRequestRepository contactRequestRepository,
  }) : _uid = uid,
       _userProfileRepository = userProfileRepository,
       _contactRequestRepository = contactRequestRepository,
       super(const TrustedContactsState());

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

  /// Loads the list of contact requests sent by the current user.
  Future<void> loadSentRequests() async {
    emit(
      state.copyWith(isLoadingSentRequests: true, sentRequestsFailure: null),
    );

    final result = await _contactRequestRepository.getSentRequests(_uid);

    await result.when(
      success: (requests) async {
        final items = await Future.wait(
          requests.map((r) async {
            String? photo;
            String? name;
            final profileResult = await _userProfileRepository.getProfile(
              r.receiverUid,
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
              direction: ContactRequestDirection.sent,
              peerUid: r.receiverUid,
              peerUsername: name ?? r.receiverUsername,
              peerPhoto: photo,
            );
          }),
        );
        emit(state.copyWith(isLoadingSentRequests: false, sentRequests: items));
      },
      failure: (failure) async => emit(
        state.copyWith(
          isLoadingSentRequests: false,
          sentRequestsFailure: failure,
        ),
      ),
    );
  }

  /// Sends a contact request to the user identified by [receiverUsername].
  /// On success reloads the sent requests list.
  Future<void> sendRequest(String receiverUsername) async {
    final senderUsername = state.username;
    if (senderUsername == null) return;

    emit(state.copyWith(isSendingRequest: true, sendRequestFailure: null));

    final result = await _contactRequestRepository.createRequest(
      senderUid: _uid,
      senderUsername: senderUsername,
      receiverUsername: receiverUsername,
    );

    result.when(
      success: (_) {
        emit(state.copyWith(isSendingRequest: false));
        loadSentRequests();
      },
      failure: (failure) => emit(
        state.copyWith(isSendingRequest: false, sendRequestFailure: failure),
      ),
    );
  }

  /// Clears a previous send request failure from the state.
  void clearSendRequestFailure() {
    emit(state.copyWith(sendRequestFailure: null));
  }

  /// Deletes a sent contact request identified by [requestId].
  /// On success removes the item from the list without reloading.
  Future<void> deleteSentRequest(String requestId) async {
    emit(state.copyWith(isDeletingRequest: true, deleteRequestFailure: null));

    final result = await _contactRequestRepository.deleteRequest(
      requestId: requestId,
      requesterUid: _uid,
    );

    result.when(
      success: (_) {
        final updated = state.sentRequests
            .where((r) => r.requestId != requestId)
            .toList();
        emit(state.copyWith(isDeletingRequest: false, sentRequests: updated));
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
