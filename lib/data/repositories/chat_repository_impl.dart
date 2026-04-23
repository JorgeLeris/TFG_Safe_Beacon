import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/chat_dto.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/message_dto.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/chat.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

/// Repository for managing [Chat] and [Message] entities in Firestore.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatApi api}) : _api = api;

  final ChatApi _api;

  /// Returns the existing chat between [currentUid] and [otherUid],
  /// or creates a new one if it doesn't exist.
  ///
  /// Returns the chat ID.
  @override
  Future<Result<String>> getOrCreateChat({
    required String currentUid,
    required String otherUid,
  }) async {
    appLogger.fine(
      'getOrCreateChat between $currentUid and $otherUid',
    );
    try {
      final existing = await _api.findChat(currentUid, otherUid);
      if (existing != null) {
        appLogger.info('Existing chat found: ${existing.id}');
        return Result.success(existing.id);
      }

      final chatId = await _api.createChat(currentUid, otherUid);
      appLogger.info('New chat created: $chatId');
      return Result.success(chatId);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error in getOrCreateChat', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error in getOrCreateChat', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns a real-time stream of all chats where [uid] is a participant,
  /// ordered by the most recent message.
  @override
  Stream<List<Chat>> watchChats(String uid) {
    return _api.watchChats(uid).map((records) {
      return records.map((r) => _mapChatToEntity(r.id, r.dto)).toList();
    });
  }

  /// Returns a real-time stream of messages in [chatId],
  /// ordered by creation time ascending.
  @override
  Stream<List<Message>> watchMessages(String chatId) {
    return _api.watchMessages(chatId).map((records) {
      return records.map((r) => _mapMessageToEntity(r.id, r.dto)).toList();
    });
  }

  /// Sends a new message in [chatId] from [senderUid].
  ///
  /// Also updates the chat document with the latest message metadata
  /// and increments the unread count for the other participant.
  @override
  Future<Result<void>> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    appLogger.fine('Sending message in chat $chatId from $senderUid');
    try {
      // Resolve the other participant to increment their unread count.
      final chatRecord = await _api.findChatById(chatId);
      if (chatRecord == null) {
        return const Result.failure(AppFailure.notFound('chat'));
      }

      final otherUid = chatRecord.dto.participantUids.firstWhere(
        (uid) => uid != senderUid,
      );

      await _api.sendMessage(
        chatId: chatId,
        senderUid: senderUid,
        text: text,
        otherUid: otherUid,
      );
      appLogger.info('Message sent in chat $chatId');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error sending message', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error sending message', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Marks all unread messages in [chatId] as read for [uid]
  /// and resets the unread counter on the chat document.
  @override
  Future<Result<void>> markAsRead({
    required String chatId,
    required String uid,
  }) async {
    appLogger.fine('Marking chat $chatId as read for $uid');
    try {
      await _api.markAsRead(chatId: chatId, uid: uid);
      appLogger.info('Chat $chatId marked as read for $uid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error marking as read', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error marking as read', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  Chat _mapChatToEntity(String id, ChatDto dto) {
    return Chat(
      id: id,
      participantUids: dto.participantUids,
      lastMessage: dto.lastMessage,
      lastMessageSenderUid: dto.lastMessageSenderUid,
      lastMessageAt: dto.lastMessageAt,
      createdAt: dto.createdAt,
      unreadCounts: dto.unreadCounts,
    );
  }

  Message _mapMessageToEntity(String id, MessageDto dto) {
    return Message(
      id: id,
      senderUid: dto.senderUid,
      text: dto.text,
      createdAt: dto.createdAt,
      readBy: dto.readBy,
    );
  }

  AppFailure _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AppFailure.forbidden();
      case 'unavailable':
        return const AppFailure.network();
      case 'not-found':
        return const AppFailure.notFound();
      default:
        return const AppFailure.unknown();
    }
  }
}
