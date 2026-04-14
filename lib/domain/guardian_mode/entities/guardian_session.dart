import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';

part 'guardian_session.freezed.dart';

/// Status of a guardian mode session.
enum GuardianSessionStatus { active, deactivated }

/// Secondary statuses that can be appended during the lifetime of a session.
enum GuardianSessionSecondaryStatus {
  /// The user deviated from the planned route.
  routeDeviation,

  /// The estimated travel time was exceeded.
  estimatedTimeExceeded,

  /// The session ended because the user reached their destination.
  completedByArrival,

  /// The session ended because the user cancelled it.
  completedByCancellation;

  /// Text identifier used for Firestore storage.
  String get id => switch (this) {
    GuardianSessionSecondaryStatus.routeDeviation => 'route_deviation',
    GuardianSessionSecondaryStatus.estimatedTimeExceeded =>
      'estimated_time_exceeded',
    GuardianSessionSecondaryStatus.completedByArrival => 'completed_by_arrival',
    GuardianSessionSecondaryStatus.completedByCancellation =>
      'completed_by_cancellation',
  };

  /// Returns the [GuardianSessionSecondaryStatus] matching [id], or null.
  static GuardianSessionSecondaryStatus? fromId(String id) {
    return GuardianSessionSecondaryStatus.values
        .where((e) => e.id == id)
        .firstOrNull;
  }
}

@freezed
abstract class GuardianSession with _$GuardianSession {
  const factory GuardianSession({
    required String id,
    required String ownerUid,
    required List<String> trustedContactUids,
    required GuardianSessionStatus status,
    required List<GuardianSessionSecondaryStatus> secondaryStatuses,
    required List<GuardianCoordinate> recordedLocations,
    GuardianCoordinate? destination,
    required Duration estimatedDuration,
    String? description,
    String? completionJustification,
    required DateTime activatedAt,
    DateTime? deactivatedAt,
    DateTime? lastLocationTimestamp,
  }) = _GuardianSession;
}
