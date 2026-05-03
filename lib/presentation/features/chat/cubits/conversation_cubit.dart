import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/notification_service.dart';

part 'conversation_state.dart';
part 'conversation_cubit.freezed.dart';

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required String chatId,
    required String currentUid,
    required ChatRepository chatRepository,
    required UserProfileRepository userProfileRepository,
    required List<String> participantUids,
  }) : _chatId = chatId,
       _currentUid = currentUid,
       _chatRepository = chatRepository,
       _userProfileRepository = userProfileRepository,
       _participantUids = participantUids,
       super(const ConversationState());

  final String _chatId;
  final String _currentUid;
  final ChatRepository _chatRepository;
  final UserProfileRepository _userProfileRepository;
  final List<String> _participantUids;

  StreamSubscription<List<Message>>? _messagesSub;

  /// Start listening to messages in this chat in real time.
  void watchMessages() {
    emit(state.copyWith(isLoading: true, failure: null));
    _loadOtherProfilePhoto();

    // Mark existing unread messages as read when opening the chat.
    _chatRepository.markAsRead(chatId: _chatId, uid: _currentUid);

    _messagesSub?.cancel();
    _messagesSub = _chatRepository
        .watchMessages(_chatId)
        .listen(
          (messages) {
            if (!isClosed) {
              emit(state.copyWith(isLoading: false, messages: messages));

              // Mark new messages as read automatically while the chat is open.
              _chatRepository.markAsRead(chatId: _chatId, uid: _currentUid);
            }
          },
          onError: (Object error) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  isLoading: false,
                  failure: const AppFailure.unknown(),
                ),
              );
            }
          },
        );
  }

  /// Sends a text message in the current chat and notifies the other participant.
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
      success: (_) {
        emit(state.copyWith(isSending: false));
        _sendPushToOtherParticipant(trimmed);
      },
      failure: (failure) =>
          emit(state.copyWith(isSending: false, failure: failure)),
    );
  }

  /// Loads the other participant's profile photo from Firestore and emits it.
  Future<void> _loadOtherProfilePhoto() async {
    final otherUid = _participantUids.firstWhere(
      (uid) => uid != _currentUid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return;

    final result = await _userProfileRepository.getProfile(otherUid);
    result.when(
      success: (profile) {
        if (!isClosed) {
          emit(state.copyWith(otherProfilePhoto: profile.profilePhoto));
        }
      },
      failure: (_) {},
    );
  }

  /// Sends a push notification to the other chat participant.
  Future<void> _sendPushToOtherParticipant(String messageText) async {
    try {
      final otherUid = _participantUids.firstWhere(
        (uid) => uid != _currentUid,
        orElse: () => '',
      );
      if (otherUid.isEmpty) return;

      // Resolve sender username for the notification title.
      final profileResult = await _userProfileRepository.getProfile(
        _currentUid,
      );
      String senderName = '';
      profileResult.when(
        success: (profile) {
          final namePart = profile.name.capitalized();
          final surnamePart = profile.surname?.capitalized() ?? '';
          senderName =
              surnamePart.isNotEmpty ? '$namePart $surnamePart' : namePart;
        },
        failure: (_) {},
      );

      // Fetch FCM tokens for the other participant.
      final tokensResult = await _userProfileRepository.getFcmTokensForUsers([
        otherUid,
      ]);
      tokensResult.when(
        success: (tokens) {
          final notificationService = NotificationService();
          for (final token in tokens) {
            notificationService.sendPushNotification(
              deviceToken: token,
              title: senderName.isNotEmpty ? senderName : 'New message',
              body: messageText,
              data: {'chatId': _chatId, 'username': senderName},
            );
          }
        },
        failure: (f) => appLogger.warning(
          'Failed to fetch FCM tokens for chat notification: $f',
        ),
      );
    } catch (e, st) {
      appLogger.warning('Failed to send chat push notification', e, st);
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}
