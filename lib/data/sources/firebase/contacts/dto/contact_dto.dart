import 'package:cloud_firestore/cloud_firestore.dart';

class ContactDto {
  const ContactDto({
    required this.protectedPersonUid,
    required this.trustedContactUid,
    required this.protectedPersonUsername,
    required this.trustedContactUsername,
    required this.createdAt,
  });

  final String protectedPersonUid;
  final String trustedContactUid;
  final String protectedPersonUsername;
  final String trustedContactUsername;
  final DateTime createdAt;

  /// Creates a [ContactDto] from raw Firestore document data.
  factory ContactDto.fromFirestore(Map<String, dynamic> data) {
    return ContactDto(
      protectedPersonUid: data['protectedPersonUid'] as String,
      trustedContactUid: data['trustedContactUid'] as String,
      protectedPersonUsername: data['protectedPersonUsername'] as String,
      trustedContactUsername: data['trustedContactUsername'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this DTO to a JSON map for Firestore storage.
  /// [createdAt] is excluded because it is set server-side.
  Map<String, dynamic> toJson() {
    return {
      'protectedPersonUid': protectedPersonUid,
      'trustedContactUid': trustedContactUid,
      'protectedPersonUsername': protectedPersonUsername,
      'trustedContactUsername': trustedContactUsername,
    };
  }
}
