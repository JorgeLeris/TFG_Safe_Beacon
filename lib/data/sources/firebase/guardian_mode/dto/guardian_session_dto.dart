import 'package:cloud_firestore/cloud_firestore.dart';

/// Transfer coordinate object for Firestore storage.
class GuardianCoordinateDto {
  const GuardianCoordinateDto({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory GuardianCoordinateDto.fromMap(Map<String, dynamic> map) {
    return GuardianCoordinateDto(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class GuardianSessionDto {
  const GuardianSessionDto({
    required this.ownerUid,
    required this.trustedContactUids,
    required this.status,
    required this.secondaryStatuses,
    required this.recordedLocations,
    this.destination,
    required this.estimatedDurationSeconds,
    this.description,
    this.completionJustification,
    required this.activatedAt,
    this.deactivatedAt,
    this.lastLocationTimestamp,
  });

  final String ownerUid;

  /// UIDs of the trusted contacts who can see this session.
  final List<String> trustedContactUids;

  /// Stored as the enum name, e.g. 'active' or 'deactivated'.
  final String status;

  /// Stored as text identifiers, e.g. 'route_deviation'.
  final List<String> secondaryStatuses;

  final List<GuardianCoordinateDto> recordedLocations;
  final GuardianCoordinateDto? destination;

  /// Estimated route duration stored as total seconds.
  final int estimatedDurationSeconds;

  final String? description;
  final String? completionJustification;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;
  final DateTime? lastLocationTimestamp;

  /// Creates a [GuardianSessionDto] from raw Firestore document data.
  factory GuardianSessionDto.fromFirestore(Map<String, dynamic> data) {
    return GuardianSessionDto(
      ownerUid: data['ownerUid'] as String,
      trustedContactUids: List<String>.from(
        data['trustedContactUids'] as List? ?? [],
      ),
      status: data['status'] as String,
      secondaryStatuses: List<String>.from(
        data['secondaryStatuses'] as List? ?? [],
      ),
      recordedLocations: (data['recordedLocations'] as List? ?? [])
          .map((e) => GuardianCoordinateDto.fromMap(e as Map<String, dynamic>))
          .toList(),
      destination: data['destination'] != null
          ? GuardianCoordinateDto.fromMap(
              data['destination'] as Map<String, dynamic>,
            )
          : null,
      estimatedDurationSeconds: data['estimatedDurationSeconds'] as int,
      description: data['description'] as String?,
      completionJustification: data['completionJustification'] as String?,
      activatedAt:
          (data['activatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deactivatedAt: (data['deactivatedAt'] as Timestamp?)?.toDate(),
      lastLocationTimestamp: (data['lastLocationTimestamp'] as Timestamp?)
          ?.toDate(),
    );
  }

  /// Converts this DTO to a JSON map for Firestore storage.
  ///
  /// [trustedContactUids] and [activatedAt] are excluded because they are
  /// set server-side inside the creation transaction.
  Map<String, dynamic> toJson() {
    return {
      'ownerUid': ownerUid,
      'status': status,
      'secondaryStatuses': secondaryStatuses,
      'recordedLocations': recordedLocations.map((c) => c.toMap()).toList(),
      if (destination != null) 'destination': destination!.toMap(),
      'estimatedDurationSeconds': estimatedDurationSeconds,
      if (description != null) 'description': description,
    };
  }
}
