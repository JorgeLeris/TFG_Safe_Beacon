import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request.dart';

/// Contract for ContactRequest repository.
///
/// Defines the operations available for contact request management.
abstract class ContactRequestRepository {
  /// Creates a new contact request from [senderUid] to the user
  /// identified by [receiverUsername].
  ///
  /// Resolves the receiver's UID from [receiverUsername] using the
  /// usernames collection. Fails if the username does not exist,
  /// if the sender tries to add themselves, or if a request between
  /// this pair already exists.
  Future<Result<void>> createRequest({
    required String senderUid,
    required String senderUsername,
    required String receiverUsername,
  });

  /// Returns all contact requests received by [receiverUid],
  /// ordered by creation date descending.
  Future<Result<List<ContactRequest>>> getReceivedRequests(String receiverUid);

  /// Returns all contact requests sent by [senderUid],
  /// ordered by creation date descending.
  Future<Result<List<ContactRequest>>> getSentRequests(String senderUid);

  /// Returns the total number of pending requests received by [receiverUid].
  Future<Result<int>> getReceivedRequestsCount(String receiverUid);

  /// Deletes the contact request identified by [requestId].
  Future<Result<void>> deleteRequest({
    required String requestId,
    required String requesterUid,
  });
}
