import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/dto/alert_dto.dart';

class AlertApi {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _firestore.collection('alerts');

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('contacts');

  // ==============================================
  // MARK: - Create
  // ==============================================

  /// Creates a new alert atomically.
  ///
  /// Within the transaction:
  /// - Verifies the owner has no other active alert.
  /// - Verifies the owner has at least one trusted contact.
  /// - Resolves and embeds the current trusted contact UIDs.
  /// - Writes the alert document with a server timestamp for [activatedAt].
  ///
  /// Throws [Exception] with a descriptive code on business rule violations.
  Future<void> createAlert(AlertDto dto) async {
    final newRef = _alerts.doc();

    await _firestore.runTransaction((tx) async {
      // Check no active alert exists for this owner.
      final existingAlert = await _alerts
          .where('ownerUid', isEqualTo: dto.ownerUid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existingAlert.docs.isNotEmpty) {
        throw Exception('alert_already_active');
      }

      // Verify the owner has at least one trusted contact.
      final contactsSnap = await _contacts
          .where('protectedPersonUid', isEqualTo: dto.ownerUid)
          .get();

      if (contactsSnap.docs.isEmpty) {
        throw Exception('no_trusted_contacts');
      }

      // Embed current trusted contact UIDs so they can query this alert.
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

  /// Deactivates the active alert for [ownerUid].
  ///
  /// Looks up the active alert and updates its [status], [deactivatedAt],
  /// and optionally [cancellationReason].
  ///
  /// Throws [Exception] with code 'no_active_alert' if none is found.
  Future<void> deactivateAlert({
    required String ownerUid,
    String? cancellationReason,
  }) async {
    final snap = await _alerts
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('no_active_alert');
    }

    final updates = <String, dynamic>{
      'status': 'deactivated',
      'deactivatedAt': FieldValue.serverTimestamp(),
      'cancellationReason': ?cancellationReason,
    };

    await snap.docs.first.reference.update(updates);
  }

  // ==============================================
  // MARK: - Read
  // ==============================================

  /// Returns the active alert for [ownerUid], or null if none exists.
  Future<({String id, AlertDto dto})?> getActiveAlert(String ownerUid) async {
    final snap = await _alerts
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return (id: doc.id, dto: AlertDto.fromFirestore(doc.data()));
  }

  /// Returns the alert document identified by [alertId], or null if not found.
  Future<({String id, AlertDto dto})?> getAlertDetails(String alertId) async {
    final doc = await _alerts.doc(alertId).get();
    if (!doc.exists) return null;

    return (id: doc.id, dto: AlertDto.fromFirestore(doc.data()!));
  }

  /// Returns all alerts where [trustedContactUid] appears as a monitor.
  ///
  /// Results are sorted by [activatedAt] descending (most recent first).
  Future<List<({String id, AlertDto dto})>> getContactsAlerts(
    String trustedContactUid,
  ) async {
    final snap = await _alerts
        .where('trustedContactUids', arrayContains: trustedContactUid)
        .get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: AlertDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.activatedAt.compareTo(a.dto.activatedAt));

    return results;
  }

  // ==============================================
  // MARK: - Cascade
  // ==============================================

  /// Removes [trustedContactUid] from the [trustedContactUids] array on all
  /// alerts belonging to [ownerUid].
  ///
  /// Called when a contact relationship is deleted so the former trusted
  /// contact loses access to the owner's historical alerts.
  Future<void> removeContactFromAlerts({
    required String ownerUid,
    required String trustedContactUid,
  }) async {
    final snap = await _alerts.where('ownerUid', isEqualTo: ownerUid).get();

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
