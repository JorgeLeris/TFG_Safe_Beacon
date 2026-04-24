import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/chat.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'chat_list_state.dart';
part 'chat_list_cubit.freezed.dart';

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit({
    required String uid,
    required ChatRepository chatRepository,
    required UserProfileRepository userProfileRepository,
  }) : _uid = uid,
       _chatRepository = chatRepository,
       _userProfileRepository = userProfileRepository,
       super(const ChatListState());

  final String _uid;
  final ChatRepository _chatRepository;
  final UserProfileRepository _userProfileRepository;

  StreamSubscription<List<Chat>>? _chatsSub;

  /// Cache of resolved user profiles.
  final Map<String, ({String displayName, String? profilePhoto})>
  _profileCache = {};

  /// Start listening to the user's chats in real time.
  void watchChats() {
    emit(state.copyWith(isLoading: true, failure: null));

    _chatsSub?.cancel();
    _chatsSub = _chatRepository
        .watchChats(_uid)
        .listen(
          _onChatsUpdated,
          onError: (Object error) {
            emit(
              state.copyWith(
                isLoading: false,
                failure: const AppFailure.unknown(),
              ),
            );
          },
        );
  }

  Future<void> _onChatsUpdated(List<Chat> chats) async {
    final entries = <ChatListEntry>[];

    for (final chat in chats) {
      final otherUid = chat.participantUids.firstWhere(
        (uid) => uid != _uid,
        orElse: () => '',
      );
      if (otherUid.isEmpty) continue;

      // Resolve profile cached.
      var cached = _profileCache[otherUid];
      if (cached == null) {
        final profileResult = await _userProfileRepository.getProfile(otherUid);
        profileResult.when(
          success: (profile) {
            final name = profile.name;
            final surname = profile.surname ?? '';
            cached = (
              displayName: '$name $surname'.trim(),
              profilePhoto: profile.profilePhoto,
            );
          },
          failure: (_) {
            cached = (displayName: otherUid, profilePhoto: null);
          },
        );
        _profileCache[otherUid] = cached!;
      }

      entries.add(
        ChatListEntry(
          chatId: chat.id,
          otherUid: otherUid,
          displayName: cached!.displayName,
          profilePhoto: cached!.profilePhoto,
          lastMessage: chat.lastMessage,
          lastMessageIsFromMe: chat.lastMessageSenderUid == _uid,
          unreadCount: chat.unreadCounts[_uid] ?? 0,
        ),
      );
    }

    if (!isClosed) {
      emit(state.copyWith(isLoading: false, chats: entries));
    }
  }

  @override
  Future<void> close() {
    _chatsSub?.cancel();
    return super.close();
  }
}
