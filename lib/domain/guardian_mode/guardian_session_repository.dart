import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';

/// Contract for the Guardian Mode session repository.
///
/// Each user can only have one active session at a time.
/// Creating a session requires at least one trusted contact.
abstract class GuardianSessionRepository {
  /// Creates a new guardian mode session for [ownerUid].
  ///
  /// The session starts with [GuardianSessionStatus.active] and no secondary
  /// statuses. The [trustedContactUids] list is resolved server-side from the
  /// contacts collection at creation time.
  ///
  /// Fails with [AppFailure.conflict] if the user already has an active session.
  /// Fails with [AppFailure.business] if the user has no trusted contacts.
  Future<Result<void>> createSession({
    required String ownerUid,
    GuardianCoordinate? destination,
    required Duration estimatedDuration,
    required GuardianCoordinate initialLocation,
    String? description,
  });

  /// Completes the active session for [ownerUid].
  ///
  /// Sets the session status to [GuardianSessionStatus.deactivated], appends
  /// [completionStatus] (must be [GuardianSessionSecondaryStatus.completedByArrival]
  /// or [GuardianSessionSecondaryStatus.completedByCancellation]), records the
  /// deactivation timestamp, and optionally stores a [completionJustification].
  ///
  /// Fails with [AppFailure.notFound] if the user has no active session.
  Future<Result<void>> completeSession({
    required String ownerUid,
    required GuardianSessionSecondaryStatus completionStatus,
    String? completionJustification,
  });

  /// Updates an active session with new tracking data.
  ///
  /// Appends [newLocations] to the recorded locations list and updates the
  /// last-location timestamp. Optionally appends [newSecondaryStatuses] to
  /// the existing secondary statuses (e.g. route deviation detected).
  ///
  /// Fails with [AppFailure.notFound] if the session does not exist.
  Future<Result<void>> updateSession({
    required String sessionId,
    required List<GuardianCoordinate> newLocations,
    List<GuardianSessionSecondaryStatus>? newSecondaryStatuses,
  });

  /// Returns all sessions where [trustedContactUid] appears as a monitor,
  /// sorted by [activatedAt] descending.
  Future<Result<List<GuardianSession>>> getContactsSessions(
    String trustedContactUid,
  );

  /// Returns the full details of the session identified by [sessionId].
  ///
  /// Fails with [AppFailure.notFound] if the session does not exist.
  Future<Result<GuardianSession>> getSessionDetails(String sessionId);

  /// Returns the active session for [ownerUid], or null if none exists.
  Future<Result<GuardianSession?>> getActiveSession(String ownerUid);
}
