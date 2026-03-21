import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_request_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_request_dto.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request.dart';

/// Repository for managing [ContactRequest] entities in Firestore.
class ContactRequestRepositoryImpl implements ContactRequestRepository {
  ContactRequestRepositoryImpl({required ContactRequestApi api}) : _api = api;

  final ContactRequestApi _api;

  /// Creates a contact request from [senderUid] to the user identified
  /// by [receiverUsername].
  ///
  /// Fails with [AppFailure.notFound] if the username does not exist,
  /// [AppFailure.conflict] if a request between the pair already exists
  /// or an active contact relationship already exists,
  /// [AppFailure.business] if the sender tries to add themselves.
  @override
  Future<Result<void>> createRequest({
    required String senderUid,
    required String senderUsername,
    required String receiverUsername,
  }) async {
    appLogger.fine(
      'Creating contact request from $senderUsername to $receiverUsername',
    );
    try {
      await _api.createRequest(
        ContactRequestDto(
          senderUid: senderUid,
          receiverUid: '',
          senderUsername: senderUsername,
          receiverUsername: receiverUsername,
          createdAt: DateTime.now(),
        ),
      );
      appLogger.info(
        'Contact request created: $senderUsername → $receiverUsername',
      );
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error creating contact request', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on Exception catch (e, st) {
      return Result.failure(_mapBusinessError(e, st));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating contact request', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all contact requests received by [receiverUid].
  @override
  Future<Result<List<ContactRequest>>> getReceivedRequests(
    String receiverUid,
  ) async {
    appLogger.fine('Fetching received requests for uid: $receiverUid');
    try {
      final results = await _api.getReceivedRequests(receiverUid);
      final requests = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${requests.length} received requests for uid: $receiverUid',
      );
      return Result.success(requests);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching received requests', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching received requests', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns all contact requests sent by [senderUid].
  @override
  Future<Result<List<ContactRequest>>> getSentRequests(String senderUid) async {
    appLogger.fine('Fetching sent requests for uid: $senderUid');
    try {
      final results = await _api.getSentRequests(senderUid);
      final requests = results.map((r) => _mapToEntity(r.id, r.dto)).toList();
      appLogger.info(
        'Fetched ${requests.length} sent requests for uid: $senderUid',
      );
      return Result.success(requests);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error fetching sent requests', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching sent requests', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Returns the count of pending requests received by [receiverUid].
  @override
  Future<Result<int>> getReceivedRequestsCount(String receiverUid) async {
    appLogger.fine('Fetching received requests count for uid: $receiverUid');
    try {
      final count = await _api.getReceivedRequestsCount(receiverUid);
      appLogger.info('Received requests count for uid $receiverUid: $count');
      return Result.success(count);
    } on FirebaseException catch (e, st) {
      appLogger.severe(
        'Firebase error fetching received requests count',
        e,
        st,
      );
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe(
        'Unexpected error fetching received requests count',
        e,
        st,
      );
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Deletes the contact request identified by [requestId].
  @override
  Future<Result<void>> deleteRequest({
    required String requestId,
    required String requesterUid,
  }) async {
    appLogger.fine('Deleting contact request $requestId by uid: $requesterUid');
    try {
      await _api.deleteRequest(requestId);
      appLogger.info('Contact request $requestId deleted successfully');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error deleting contact request', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error deleting contact request', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  ContactRequest _mapToEntity(String id, ContactRequestDto dto) {
    return ContactRequest(
      id: id,
      senderUid: dto.senderUid,
      receiverUid: dto.receiverUid,
      senderUsername: dto.senderUsername,
      receiverUsername: dto.receiverUsername,
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
    if (message.contains('username_not_found')) {
      appLogger.warning('Contact request failed: receiver username not found');
      return const AppFailure.notFound();
    }
    if (message.contains('self_request')) {
      appLogger.warning('Contact request failed: sender equals receiver');
      return const AppFailure.business('self_request');
    }
    if (message.contains('request_already_exists')) {
      appLogger.warning('Contact request failed: request already exists');
      return const AppFailure.conflict('request_already_exists');
    }
    if (message.contains('contact_already_exists')) {
      appLogger.warning(
        'Contact request failed: contact relationship already exists',
      );
      return const AppFailure.conflict('contact_already_exists');
    }
    appLogger.severe(
      'Unexpected business error creating contact request',
      e,
      st,
    );
    return const AppFailure.unknown();
  }
}
