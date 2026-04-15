import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/dto/guardian_session_dto.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';

/// Repository for managing [GuardianSession] entities in Firestore.
class GuardianSessionRepositoryImpl implements GuardianSessionRepository {
  GuardianSessionRepositoryImpl({required GuardianSessionApi api}) : _api = api;

  final GuardianSessionApi _api;

  /// Creates a new guardian mode session for [ownerUid].
  @override
  Future<Result<void>> createSession({
    required String ownerUid,
    GuardianCoordinate? destination,
    required Duration estimatedDuration,
    required GuardianCoordinate initialLocation,
    String? description,
  }) async {
    appLogger.fine('Creating guardian session for uid: $ownerUid');
    try {
      await _api.createSession(
        GuardianSessionDto(
          ownerUid: ownerUid,
          trustedContactUids: const [],
          status: GuardianSessionStatus.active.name,
          secondaryStatuses: const [],
          originLocation: GuardianCoordinateDto(
            latitude: initialLocation.latitude,
            longitude: initialLocation.longitude,
          ),
          currentLocation: GuardianCoordinateDto(
            latitude: initialLocation.latitude,
            longitude: initialLocation.longitude,
          ),
          destination: destination != null
              ? GuardianCoordinateDto(
                  latitude: destination.latitude,
                  longitude: destination.longitude,
                )
              : null,
          estimatedDurationSeconds: estimatedDuration.inSeconds,
          description: description,
          activatedAt: DateTime.now(),
        ),
      );
      appLogger.info('Guardian session created for uid: $ownerUid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error creating guardian session', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating guardian session', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Completes the active session for [ownerUid].
  @override
  Future<Result<void>> completeSession({
    required String ownerUid,
    required GuardianSessionSecondaryStatus completionStatus,
    String? completionJustification,
  }) async {
    appLogger.fine(
      'Completing guardian session for uid: $ownerUid '
      '(reason: ${completionStatus.id})',
    );
    try {
      await _api.completeSession(
        ownerUid: ownerUid,
        completionStatus: completionStatus.id,
        completionJustification: completionJustification,
      );
      appLogger.info('Guardian session completed for uid: $ownerUid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error completing guardian session', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error completing guardian session', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  @override
  Future<Result<void>> updateSession({
    required String sessionId,
    required GuardianCoordinate newLocation,
    List<GuardianSessionSecondaryStatus>? newSecondaryStatuses,
  }) async {
    appLogger.fine('Updating guardian session: $sessionId');
    try {
      await _api.updateSession(
        sessionId: sessionId,
        newLocation: {
          'latitude': newLocation.latitude,
          'longitude': newLocation.longitude,
        },
        newSecondaryStatuses: newSecondaryStatuses?.map((s) => s.id).toList(),
      );
      appLogger.info('Guardian session updated: $sessionId');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error updating guardian session', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error updating guardian session', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all sessions where [trustedContactUid] is a monitor.
  @override
  Future<Result<List<GuardianSession>>> getContactsSessions(
    String trustedContactUid,
  ) async {
    appLogger.fine('Fetching contacts\' sessions for uid: $trustedContactUid');
    try {
      final results = await _api.getContactsSessions(trustedContactUid);
      final sessions = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${sessions.length} contacts\' sessions for uid: $trustedContactUid',
      );
      return Result.success(sessions);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching contacts\' sessions', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching contacts\' sessions', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns the full details of the session identified by [sessionId].
  @override
  Future<Result<GuardianSession>> getSessionDetails(String sessionId) async {
    appLogger.fine('Fetching guardian session details for id: $sessionId');
    try {
      final result = await _api.getSessionDetails(sessionId);
      if (result == null) {
        appLogger.warning('Guardian session not found: $sessionId');
        return const Result.failure(AppFailure.notFound('guardian_session'));
      }
      appLogger.info('Guardian session details fetched for id: $sessionId');
      return Result.success(_mapToEntity(result.id, result.dto));
    } on FirebaseException catch (e, st) {
      appLogger.severe(
        'Firebase error fetching guardian session details',
        e,
        st,
      );
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe(
        'Unexpected error fetching guardian session details',
        e,
        st,
      );
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns the active session for [ownerUid], or null if none exists.
  @override
  Future<Result<GuardianSession?>> getActiveSession(String ownerUid) async {
    appLogger.fine('Fetching active guardian session for uid: $ownerUid');
    try {
      final result = await _api.getActiveSession(ownerUid);
      if (result == null) {
        appLogger.info('No active guardian session for uid: $ownerUid');
        return const Result.success(null);
      }
      appLogger.info('Active guardian session found for uid: $ownerUid');
      return Result.success(_mapToEntity(result.id, result.dto));
    } on FirebaseException catch (e, st) {
      appLogger.severe(
        'Firebase error fetching active guardian session',
        e,
        st,
      );
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe(
        'Unexpected error fetching active guardian session',
        e,
        st,
      );
      return const Result.failure(AppFailure.unknown());
    }
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  GuardianSession _mapToEntity(String id, GuardianSessionDto dto) {
    return GuardianSession(
      id: id,
      ownerUid: dto.ownerUid,
      trustedContactUids: dto.trustedContactUids,
      status: GuardianSessionStatus.values.firstWhere(
        (e) => e.name == dto.status,
        orElse: () => GuardianSessionStatus.deactivated,
      ),
      secondaryStatuses: dto.secondaryStatuses
          .map(GuardianSessionSecondaryStatus.fromId)
          .whereType<GuardianSessionSecondaryStatus>()
          .toList(),
      originLocation: GuardianCoordinate(
        latitude: dto.originLocation.latitude,
        longitude: dto.originLocation.longitude,
      ),
      currentLocation: GuardianCoordinate(
        latitude: dto.currentLocation.latitude,
        longitude: dto.currentLocation.longitude,
      ),
      destination: dto.destination != null
          ? GuardianCoordinate(
              latitude: dto.destination!.latitude,
              longitude: dto.destination!.longitude,
            )
          : null,
      estimatedDuration: Duration(seconds: dto.estimatedDurationSeconds),
      description: dto.description,
      completionJustification: dto.completionJustification,
      activatedAt: dto.activatedAt,
      deactivatedAt: dto.deactivatedAt,
      lastLocationTimestamp: dto.lastLocationTimestamp,
    );
  }

  AppFailure _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AppFailure.forbidden();
      case 'unavailable':
        return const AppFailure.network();
      case 'not-found':
        return const AppFailure.notFound();
      default:
        return const AppFailure.unknown();
    }
  }

  AppFailure _mapBusinessError(Exception e, StackTrace st) {
    final message = e.toString();
    if (message.contains('session_already_active')) {
      appLogger.warning(
        'Session creation failed: user already has an active session',
      );
      return const AppFailure.conflict('session_already_active');
    }
    if (message.contains('no_trusted_contacts')) {
      appLogger.warning('Session creation failed: no trusted contacts');
      return const AppFailure.business('no_trusted_contacts');
    }
    if (message.contains('no_active_session')) {
      appLogger.warning('Session completion failed: no active session found');
      return const AppFailure.notFound('guardian_session');
    }
    appLogger.severe(
      'Unexpected business error on guardian session operation',
      e,
      st,
    );
    return const AppFailure.unknown();
  }
}
