import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_request_dto.dart';

class ContactRequestApi {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('contact_requests');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  // ==============================================
  // MARK: - Create
  // ==============================================

  /// Creates a contact request atomically.
  ///
  /// Within the transaction:
  /// - Resolves [receiverUsername] to a UID via the usernames collection.
  /// - Verifies the sender is not adding themselves.
  /// - Verifies no existing request between this pair already exists.
  /// - Writes the new request document with a server timestamp.
  ///
  /// Throws [Exception] with a descriptive code on business rule violations.
  Future<void> createRequest(ContactRequestDto dto) async {
    await _firestore.runTransaction((tx) async {
      // Resolve receiver UID from username.
      final usernameSnap = await tx.get(_usernames.doc(dto.receiverUsername));
      if (!usernameSnap.exists) {
        throw Exception('username_not_found');
      }

      final receiverUid = usernameSnap.data()!['uid'] as String;

      // Prevent self-request.
      if (receiverUid == dto.senderUid) {
        throw Exception('self_request');
      }

      // Check for existing request between this pair (both directions).
      final existingSent = await _requests
          .where('senderUid', isEqualTo: dto.senderUid)
          .where('receiverUid', isEqualTo: receiverUid)
          .limit(1)
          .get();

      final existingReceived = await _requests
          .where('senderUid', isEqualTo: receiverUid)
          .where('receiverUid', isEqualTo: dto.senderUid)
          .limit(1)
          .get();

      if (existingSent.docs.isNotEmpty || existingReceived.docs.isNotEmpty) {
        throw Exception('request_already_exists');
      }

      // Write the new request.
      final newRef = _requests.doc();
      final data = dto.toJson();
      data['receiverUid'] = receiverUid;
      data['createdAt'] = FieldValue.serverTimestamp();

      tx.set(newRef, data);
    });
  }

  // ==============================================
  // MARK: - Read
  // ==============================================

  /// Returns all requests received by [receiverUid],
  /// ordered by creation date descending.
  Future<List<({String id, ContactRequestDto dto})>> getReceivedRequests(
    String receiverUid,
  ) async {
    final snap = await _requests
        .where('receiverUid', isEqualTo: receiverUid)
        .get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: ContactRequestDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.createdAt.compareTo(a.dto.createdAt));

    return results;
  }

  /// Returns all requests sent by [senderUid].
  Future<List<({String id, ContactRequestDto dto})>> getSentRequests(
    String senderUid,
  ) async {
    final snap = await _requests.where('senderUid', isEqualTo: senderUid).get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: ContactRequestDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.createdAt.compareTo(a.dto.createdAt));

    return results;
  }

  /// Returns the count of requests received by [receiverUid].
  Future<int> getReceivedRequestsCount(String receiverUid) async {
    final snap = await _requests
        .where('receiverUid', isEqualTo: receiverUid)
        .count()
        .get();

    return snap.count ?? 0;
  }

  // ==============================================
  // MARK: - Delete
  // ==============================================

  /// Deletes the contact request document identified by [requestId].
  Future<void> deleteRequest(String requestId) async {
    await _requests.doc(requestId).delete();
  }
}
