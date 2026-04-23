import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

part 'conversation_state.dart';
part 'conversation_cubit.freezed.dart';

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required String chatId,
    required String currentUid,
    required ChatRepository chatRepository,
  })  : _chatId = chatId,
        _currentUid = currentUid,
        _chatRepository = chatRepository,
        super(const ConversationState());

  final String _chatId;
  final String _currentUid;
  final ChatRepository _chatRepository;

  StreamSubscription<List<Message>>? _messagesSub;

  /// Start listening to messages in this chat in real time.
  void watchMessages() {
    emit(state.copyWith(isLoading: true, failure: null));

    // Mark existing unread messages as read when opening the chat.
    _chatRepository.markAsRead(chatId: _chatId, uid: _currentUid);

    _messagesSub?.cancel();
    _messagesSub = _chatRepository.watchMessages(_chatId).listen(
      (messages) {
        if (!isClosed) {
          emit(state.copyWith(isLoading: false, messages: messages));

          // Mark new messages as read automatically while the chat is open.
          _chatRepository.markAsRead(chatId: _chatId, uid: _currentUid);
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(state.copyWith(
            isLoading: false,
            failure: const AppFailure.unknown(),
          ));
        }
      },
    );
  }

  /// Sends a text message in the current chat.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(isSending: true));

    final result = await _chatRepository.sendMessage(
      chatId: _chatId,
      senderUid: _currentUid,
      text: trimmed,
    );

    result.when(
      success: (_) => emit(state.copyWith(isSending: false)),
      failure: (failure) =>
          emit(state.copyWith(isSending: false, failure: failure)),
    );
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
