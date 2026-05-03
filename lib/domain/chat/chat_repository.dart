import 'package:safe_beacon/domain/chat/entities/chat.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/result.dart';

/// Contract for Chat repository.
///
/// Manages chat conversations and messages between users.
/// A chat is created automatically when the first message is sent between two users.
abstract class ChatRepository {
  /// Returns the existing chat between [currentUid] and [otherUid],
  /// or creates a new one if it doesn't exist.
  ///
  /// Returns the chat ID.
  Future<Result<String>> getOrCreateChat({
    required String currentUid,
    required String otherUid,
  });

  /// Returns a real-time stream of all chats where [uid] is a participant,
  /// ordered by the most recent message.
  Stream<List<Chat>> watchChats(String uid);

  /// Returns a real-time stream of messages in [chatId],
  /// ordered by creation time ascending.
  Stream<List<Message>> watchMessages(String chatId);

  /// Sends a new message in [chatId] from [senderUid].
  ///
  /// Also updates the chat document with the latest message metadata
  /// and increments the unread count for the other participant.
  Future<Result<void>> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  });

  /// Marks all unread messages in [chatId] as read for [uid]
  /// and resets the unread counter on the chat document.
  Future<Result<void>> markAsRead({
    required String chatId,
    required String uid,
  });
}
