import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDto {
  const ChatDto({
    required this.participantUids,
    this.lastMessage,
    this.lastMessageSenderUid,
    this.lastMessageAt,
    required this.createdAt,
    this.unreadCounts = const {},
  });

  final List<String> participantUids;
  final String? lastMessage;
  final String? lastMessageSenderUid;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  /// Per-user unread counts keyed by UID.
  final Map<String, int> unreadCounts;

  factory ChatDto.fromFirestore(Map<String, dynamic> data) {
    // Extract unreadCount_<uid> fields.
    final unreadCounts = <String, int>{};
    for (final entry in data.entries) {
      if (entry.key.startsWith('unreadCount_')) {
        final uid = entry.key.substring('unreadCount_'.length);
        unreadCounts[uid] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return ChatDto(
      participantUids: List<String>.from(
        data['participantUids'] as List? ?? [],
      ),
      lastMessage: data['lastMessage'] as String?,
      lastMessageSenderUid: data['lastMessageSenderUid'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: unreadCounts,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'participantUids': participantUids,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageSenderUid != null)
        'lastMessageSenderUid': lastMessageSenderUid,
    };

    for (final entry in unreadCounts.entries) {
      json['unreadCount_${entry.key}'] = entry.value;
    }

    return json;
  }
}
