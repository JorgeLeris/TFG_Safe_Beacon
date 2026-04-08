import 'package:cloud_firestore/cloud_firestore.dart';

class ContactRequestDto {
  const ContactRequestDto({
    required this.senderUid,
    required this.receiverUid,
    required this.senderUsername,
    required this.receiverUsername,
    required this.createdAt,
  });

  final String senderUid;
  final String receiverUid;
  final String senderUsername;
  final String receiverUsername;
  final DateTime createdAt;

  /// Creates a [ContactRequestDto] from raw Firestore document data.
  factory ContactRequestDto.fromFirestore(Map<String, dynamic> data) {
    return ContactRequestDto(
      senderUid: data['senderUid'] as String,
      receiverUid: data['receiverUid'] as String,
      senderUsername: data['senderUsername'] as String,
      receiverUsername: data['receiverUsername'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this DTO to a JSON map for Firestore storage.
  /// [createdAt] is excluded because it is set server-side.
  Map<String, dynamic> toJson() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'senderUsername': senderUsername,
      'receiverUsername': receiverUsername,
    };
  }
}
