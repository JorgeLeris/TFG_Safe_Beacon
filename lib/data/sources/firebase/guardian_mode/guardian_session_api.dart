import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/dto/guardian_session_dto.dart';

class GuardianSessionApi {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('guardian_sessions');

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('contacts');

  // ==============================================
  // MARK: - Create
  // ==============================================

  /// Creates a new guardian mode session atomically.
  ///
  /// Within the transaction:
  /// - Verifies the owner has no other active session.
  /// - Verifies the owner has at least one trusted contact.
  /// - Resolves and embeds the current trusted contact UIDs.
  /// - Writes the session document with server timestamps.
  ///
  /// Throws [Exception] with a descriptive code on business rule violations.
  Future<void> createSession(GuardianSessionDto dto) async {
    final newRef = _sessions.doc();

    await _firestore.runTransaction((tx) async {
      // Check no active session exists for this owner.
      final existingSession = await _sessions
          .where('ownerUid', isEqualTo: dto.ownerUid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existingSession.docs.isNotEmpty) {
        throw Exception('session_already_active');
      }

      // Verify the owner has at least one trusted contact.
      final contactsSnap = await _contacts
          .where('protectedPersonUid', isEqualTo: dto.ownerUid)
          .get();

      if (contactsSnap.docs.isEmpty) {
        throw Exception('no_trusted_contacts');
      }

      // Embed current trusted contact UIDs so they can query this session.
      final trustedContactUids = contactsSnap.docs
          .map((doc) => doc.data()['trustedContactUid'] as String)
          .toList();

      final data = dto.toJson();
      data['trustedContactUids'] = trustedContactUids;
      data['activatedAt'] = FieldValue.serverTimestamp();

      tx.set(newRef, data);
    });
  }

  // ==============================================
  // MARK: - Update
  // ==============================================

  /// Completes the active session for [ownerUid].
  ///
  /// Sets [status] to 'deactivated', appends [completionStatus] to
  /// [secondaryStatuses], records [deactivatedAt], and optionally stores
  /// [completionJustification].
  ///
  /// Throws [Exception] with code 'no_active_session' if none is found.
  Future<void> completeSession({
    required String ownerUid,
    required String completionStatus,
    String? completionJustification,
  }) async {
    final snap = await _sessions
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('no_active_session');
    }

    final updates = <String, dynamic>{
      'status': 'deactivated',
      'deactivatedAt': FieldValue.serverTimestamp(),
      'secondaryStatuses': FieldValue.arrayUnion([completionStatus]),
      'completionJustification': ?completionJustification,
    };

    await snap.docs.first.reference.update(updates);
  }

  /// Appends new tracking data to the session identified by [sessionId].
  ///
  /// Uses [FieldValue.arrayUnion] to append [newLocations] to
  /// [recordedLocations] and updates [lastLocationTimestamp]. Optionally
  /// appends [newSecondaryStatuses].
  Future<void> updateSession({
    required String sessionId,
    required List<Map<String, dynamic>> newLocations,
    List<String>? newSecondaryStatuses,
  }) async {
    final updates = <String, dynamic>{
      'recordedLocations': FieldValue.arrayUnion(newLocations),
      'lastLocationTimestamp': FieldValue.serverTimestamp(),
      if (newSecondaryStatuses != null && newSecondaryStatuses.isNotEmpty)
        'secondaryStatuses': FieldValue.arrayUnion(newSecondaryStatuses),
    };

    await _sessions.doc(sessionId).update(updates);
  }

  // ==============================================
  // MARK: - Read
  // ==============================================

  /// Returns the active session for [ownerUid], or null if none exists.
  Future<({String id, GuardianSessionDto dto})?> getActiveSession(
    String ownerUid,
  ) async {
    final snap = await _sessions
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return (id: doc.id, dto: GuardianSessionDto.fromFirestore(doc.data()));
  }

  /// Returns the session document identified by [sessionId], or null.
  Future<({String id, GuardianSessionDto dto})?> getSessionDetails(
    String sessionId,
  ) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;

    return (id: doc.id, dto: GuardianSessionDto.fromFirestore(doc.data()!));
  }

  /// Returns all sessions where [trustedContactUid] appears as a monitor.
  ///
  /// Results are sorted by [activatedAt] descending (most recent first).
  Future<List<({String id, GuardianSessionDto dto})>> getContactsSessions(
    String trustedContactUid,
  ) async {
    final snap = await _sessions
        .where('trustedContactUids', arrayContains: trustedContactUid)
        .get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: GuardianSessionDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.activatedAt.compareTo(a.dto.activatedAt));

    return results;
  }

  // ==============================================
  // MARK: - Cascade
  // ==============================================

  /// Removes [trustedContactUid] from the [trustedContactUids] array on all
  /// sessions belonging to [ownerUid].
  ///
  /// Called when a contact relationship is deleted so the former trusted
  /// contact loses access to the owner's historical sessions.
  Future<void> removeContactFromSessions({
    required String ownerUid,
    required String trustedContactUid,
  }) async {
    final snap = await _sessions.where('ownerUid', isEqualTo: ownerUid).get();

    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'trustedContactUids': FieldValue.arrayRemove([trustedContactUid]),
      });
    }

    await batch.commit();
  }
}
