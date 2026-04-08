import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDto {
  const AlertDto({
    required this.ownerUid,
    required this.ownerUsername,
    required this.alertType,
    required this.latitude,
    required this.longitude,
    required this.batteryLevel,
    required this.status,
    required this.trustedContactUids,
    this.cancellationReason,
    required this.activatedAt,
    this.deactivatedAt,
  });

  final String ownerUid;
  final String ownerUsername;

  /// Stored as the enum name, e.g. 'panic', 'guardian', 'sensors', 'other'.
  final String alertType;

  final double latitude;
  final double longitude;
  final int batteryLevel;

  /// Stored as the enum name, e.g. 'active' or 'deactivated'.
  final String status;

  /// UIDs of the trusted contacts who can see this alert.
  final List<String> trustedContactUids;

  final String? cancellationReason;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;

  /// Creates an [AlertDto] from raw Firestore document data.
  factory AlertDto.fromFirestore(Map<String, dynamic> data) {
    return AlertDto(
      ownerUid: data['ownerUid'] as String,
      ownerUsername: data['ownerUsername'] as String,
      alertType: data['alertType'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      batteryLevel: data['batteryLevel'] as int,
      status: data['status'] as String,
      trustedContactUids: List<String>.from(
        data['trustedContactUids'] as List? ?? [],
      ),
      cancellationReason: data['cancellationReason'] as String?,
      activatedAt:
          (data['activatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deactivatedAt: (data['deactivatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts this DTO to a JSON map for Firestore storage.
  ///
  /// [trustedContactUids] and [activatedAt] are excluded because they are
  /// set server-side inside the creation transaction.
  Map<String, dynamic> toJson() {
    return {
      'ownerUid': ownerUid,
      'ownerUsername': ownerUsername,
      'alertType': alertType,
      'latitude': latitude,
      'longitude': longitude,
      'batteryLevel': batteryLevel,
      'status': status,
    };
  }
}
