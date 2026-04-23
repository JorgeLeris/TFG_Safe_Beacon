import 'package:cloud_firestore/cloud_firestore.dart';

class MessageDto {
  const MessageDto({
    required this.senderUid,
    required this.text,
    required this.createdAt,
    this.readBy = const [],
  });

  final String senderUid;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;

  factory MessageDto.fromFirestore(Map<String, dynamic> data) {
    return MessageDto(
      senderUid: data['senderUid'] as String,
      text: data['text'] as String,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderUid': senderUid,
      'text': text,
      'readBy': readBy,
    };
  }
}
