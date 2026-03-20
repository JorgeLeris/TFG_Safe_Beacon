import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
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

  /// Sends a contact request to the user identified by [receiverUsername].
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
      success: (_) => emit(state.copyWith(isSendingRequest: false)),
      failure: (failure) => emit(
        state.copyWith(isSendingRequest: false, sendRequestFailure: failure),
      ),
    );
  }

  /// Clears a previous send request failure from the state.
  void clearSendRequestFailure() {
    emit(state.copyWith(sendRequestFailure: null));
  }
}
