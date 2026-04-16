import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/dto/alert_dto.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

/// Repository for managing [Alert] entities in Firestore.
class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl({required AlertApi api}) : _api = api;

  final AlertApi _api;

  /// Creates a new alert for [ownerUid].
  @override
  Future<Result<void>> createAlert({
    required String ownerUid,
    required String ownerUsername,
    required AlertType alertType,
    required double latitude,
    required double longitude,
    required int batteryLevel,
    String? guardianSessionId,
  }) async {
    appLogger.fine(
      'Creating alert for uid: $ownerUid (type: ${alertType.name})',
    );
    try {
      await _api.createAlert(
        AlertDto(
          ownerUid: ownerUid,
          ownerUsername: ownerUsername,
          alertType: alertType.name,
          latitude: latitude,
          longitude: longitude,
          batteryLevel: batteryLevel,
          status: AlertStatus.active.name,
          trustedContactUids: const [],
          guardianSessionId: guardianSessionId,
          activatedAt: DateTime.now(),
        ),
      );
      appLogger.info('Alert created for uid: $ownerUid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error creating alert', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating alert', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Deactivates the active alert for [ownerUid].
  @override
  Future<Result<void>> deactivateAlert({
    required String ownerUid,
    String? cancellationReason,
  }) async {
    appLogger.fine('Deactivating alert for uid: $ownerUid');
    try {
      await _api.deactivateAlert(
        ownerUid: ownerUid,
        cancellationReason: cancellationReason,
      );
      appLogger.info('Alert deactivated for uid: $ownerUid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error deactivating alert', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error deactivating alert', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns the active alert for [ownerUid], or null if none exists.
  @override
  Future<Result<Alert?>> getActiveAlert(String ownerUid) async {
    appLogger.fine('Fetching active alert for uid: $ownerUid');
    try {
      final result = await _api.getActiveAlert(ownerUid);
      if (result == null) {
        appLogger.info('No active alert found for uid: $ownerUid');
        return const Result.success(null);
      }
      appLogger.info('Active alert found for uid: $ownerUid');
      return Result.success(_mapToEntity(result.id, result.dto));
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching active alert', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching active alert', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns the full details of the alert identified by [alertId].
  @override
  Future<Result<Alert>> getAlertDetails(String alertId) async {
    appLogger.fine('Fetching alert details for id: $alertId');
    try {
      final result = await _api.getAlertDetails(alertId);
      if (result == null) {
        appLogger.warning('Alert not found: $alertId');
        return const Result.failure(AppFailure.notFound('alert'));
      }
      appLogger.info('Alert details fetched for id: $alertId');
      return Result.success(_mapToEntity(result.id, result.dto));
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching alert details', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching alert details', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all alerts from the protected people of [trustedContactUid].
  @override
  Future<Result<List<Alert>>> getContactsAlerts(
    String trustedContactUid,
  ) async {
    appLogger.fine('Fetching contacts\' alerts for uid: $trustedContactUid');
    try {
      final results = await _api.getContactsAlerts(trustedContactUid);
      final alerts = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${alerts.length} contacts\' alerts for uid: $trustedContactUid',
      );
      return Result.success(alerts);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching contacts\' alerts', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching contacts\' alerts', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Deactivates the active alert associated with [guardianSessionId].
  @override
  Future<Result<void>> deactivateAlertByGuardianSession({
    required String guardianSessionId,
    String? cancellationReason,
  }) async {
    appLogger.fine(
      'Deactivating alert for guardian session: $guardianSessionId',
    );
    try {
      await _api.deactivateAlertByGuardianSession(
        guardianSessionId: guardianSessionId,
        cancellationReason: cancellationReason,
      );
      appLogger.info(
        'Alert deactivated for guardian session: $guardianSessionId',
      );
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe(
        'Firebase error deactivating alert by guardian session',
        e,
        st,
      );
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe(
        'Unexpected error deactivating alert by guardian session',
        e,
        st,
      );
      return const Result.failure(AppFailure.unknown());
    }
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  Alert _mapToEntity(String id, AlertDto dto) {
    return Alert(
      id: id,
      ownerUid: dto.ownerUid,
      ownerUsername: dto.ownerUsername,
      alertType: AlertType.values.firstWhere(
        (e) => e.name == dto.alertType,
        orElse: () => AlertType.other,
      ),
      latitude: dto.latitude,
      longitude: dto.longitude,
      batteryLevel: dto.batteryLevel,
      status: AlertStatus.values.firstWhere(
        (e) => e.name == dto.status,
        orElse: () => AlertStatus.deactivated,
      ),
      trustedContactUids: dto.trustedContactUids,
      cancellationReason: dto.cancellationReason,
      guardianSessionId: dto.guardianSessionId,
      activatedAt: dto.activatedAt,
      deactivatedAt: dto.deactivatedAt,
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
    if (message.contains('alert_already_active')) {
      appLogger.warning(
        'Alert creation failed: user already has an active alert',
      );
      return const AppFailure.conflict('alert_already_active');
    }
    if (message.contains('no_trusted_contacts')) {
      appLogger.warning('Alert creation failed: no trusted contacts');
      return const AppFailure.business('no_trusted_contacts');
    }
    if (message.contains('no_active_alert')) {
      appLogger.warning('Alert deactivation failed: no active alert found');
      return const AppFailure.notFound('alert');
    }
    appLogger.severe('Unexpected business error on alert operation', e, st);
    return const AppFailure.unknown();
  }
}
