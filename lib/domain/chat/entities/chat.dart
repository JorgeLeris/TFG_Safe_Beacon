import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';

@freezed
abstract class Chat with _$Chat {
  const factory Chat({
    required String id,
    required List<String> participantUids,
    String? lastMessage,
    String? lastMessageSenderUid,
    DateTime? lastMessageAt,
    required DateTime createdAt,

    /// Per-user unread counts keyed by UID.
    @Default({}) Map<String, int> unreadCounts,
  }) = _Chat;
}
