import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_dto.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';

/// Repository for managing [Contact] entities in Firestore.
class ContactRepositoryImpl implements ContactRepository {
  ContactRepositoryImpl({
    required ContactApi api,
    required AlertApi alertApi,
    required GuardianSessionApi guardianSessionApi,
  }) : _api = api,
       _alertApi = alertApi,
       _guardianSessionApi = guardianSessionApi;

  final ContactApi _api;
  final AlertApi _alertApi;
  final GuardianSessionApi _guardianSessionApi;

  /// Creates a contact relationship between [protectedPersonUid] and [trustedContactUid].
  @override
  Future<Result<void>> createContact({
    required String protectedPersonUid,
    required String protectedPersonUsername,
    required String trustedContactUid,
    required String trustedContactUsername,
  }) async {
    appLogger.fine(
      'Creating contact: $protectedPersonUsername ↔ $trustedContactUsername',
    );
    try {
      await _api.createContact(
        ContactDto(
          protectedPersonUid: protectedPersonUid,
          trustedContactUid: trustedContactUid,
          protectedPersonUsername: protectedPersonUsername,
          trustedContactUsername: trustedContactUsername,
          createdAt: DateTime.now(),
        ),
      );
      appLogger.info(
        'Contact created: $protectedPersonUsername ↔ $trustedContactUsername',
      );
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error creating contact', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating contact', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all trusted contacts of [uid].
  @override
  Future<Result<List<Contact>>> getTrustedContacts(String uid) async {
    appLogger.fine('Fetching trusted contacts for uid: $uid');
    try {
      final results = await _api.getTrustedContacts(uid);
      final contacts = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${contacts.length} trusted contacts for uid: $uid',
      );
      return Result.success(contacts);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching trusted contacts', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching trusted contacts', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all people protected by [uid].
  @override
  Future<Result<List<Contact>>> getProtectedPeople(String uid) async {
    appLogger.fine('Fetching protected people for uid: $uid');
    try {
      final results = await _api.getProtectedPeople(uid);
      final contacts = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${contacts.length} protected people for uid: $uid',
      );
      return Result.success(contacts);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching protected people', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching protected people', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Deletes the contact relationship identified by [contactId].
  ///
  /// Also removes the trusted contact from the [trustedContactUids] list on
  /// all alerts belonging to the protected person, so the former trusted
  /// contact loses access to those historical alerts.
  @override
  Future<Result<void>> deleteContact({
    required String contactId,
    required String requesterUid,
  }) async {
    appLogger.fine('Deleting contact $contactId by uid: $requesterUid');
    try {
      // Fetch contact before deletion to obtain both parties for cascade.
      final contact = await _api.getContactById(contactId);
      if (contact == null) {
        appLogger.warning('Contact $contactId not found, nothing to delete');
        return const Result.failure(AppFailure.notFound('contact'));
      }

      await _api.deleteContact(contactId);
      appLogger.info('Contact $contactId deleted successfully');

      // Cascade: remove the trusted contact from all alerts of the protected person.
      await _alertApi.removeContactFromAlerts(
        ownerUid: contact.dto.protectedPersonUid,
        trustedContactUid: contact.dto.trustedContactUid,
      );
      appLogger.fine(
        'Cascade complete: removed ${contact.dto.trustedContactUid} '
        'from alerts of ${contact.dto.protectedPersonUid}',
      );

      // Cascade: remove the trusted contact from all guardian sessions of the protected person.
      await _guardianSessionApi.removeContactFromSessions(
        ownerUid: contact.dto.protectedPersonUid,
        trustedContactUid: contact.dto.trustedContactUid,
      );
      appLogger.fine(
        'Cascade complete: removed ${contact.dto.trustedContactUid} '
        'from guardian sessions of ${contact.dto.protectedPersonUid}',
      );

      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error deleting contact', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error deleting contact', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  Contact _mapToEntity(String id, ContactDto dto) {
    return Contact(
      id: id,
      protectedPersonUid: dto.protectedPersonUid,
      trustedContactUid: dto.trustedContactUid,
      protectedPersonUsername: dto.protectedPersonUsername,
      trustedContactUsername: dto.trustedContactUsername,
      createdAt: dto.createdAt,
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
    if (message.contains('contact_already_exists')) {
      appLogger.warning('Contact creation failed: relationship already exists');
      return const AppFailure.conflict('contact_already_exists');
    }
    appLogger.severe('Unexpected business error creating contact', e, st);
    return const AppFailure.unknown();
  }
}
