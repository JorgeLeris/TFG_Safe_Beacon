import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_dto.dart';

class ContactApi {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('contacts');

  // ==============================================
  // MARK: - Create
  // ==============================================

  /// Creates a contact relationship atomically.
  ///
  /// Within the transaction:
  /// - Verifies no existing relationship between this pair already exists.
  /// - Writes the new contact document with a server timestamp.
  ///
  /// Throws [Exception] with a descriptive code on business rule violations.
  Future<void> createContact(ContactDto dto) async {
    await _firestore.runTransaction((tx) async {
      // Only check the exact same direction — reversed roles are allowed.
      final existing = await _contacts
          .where('protectedPersonUid', isEqualTo: dto.protectedPersonUid)
          .where('trustedContactUid', isEqualTo: dto.trustedContactUid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('contact_already_exists');
      }

      final newRef = _contacts.doc();
      final data = dto.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();

      tx.set(newRef, data);
    });
  }

  // ==============================================
  // MARK: - Read
  // ==============================================

  /// Returns all contacts where [uid] is the protected person.
  Future<List<({String id, ContactDto dto})>> getTrustedContacts(
    String uid,
  ) async {
    final snap = await _contacts
        .where('protectedPersonUid', isEqualTo: uid)
        .get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: ContactDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.createdAt.compareTo(a.dto.createdAt));

    return results;
  }

  /// Returns all contacts where [uid] is the trusted contact.
  Future<List<({String id, ContactDto dto})>> getProtectedPeople(
    String uid,
  ) async {
    final snap = await _contacts
        .where('trustedContactUid', isEqualTo: uid)
        .get();

    final results = snap.docs.map((doc) {
      return (id: doc.id, dto: ContactDto.fromFirestore(doc.data()));
    }).toList();

    results.sort((a, b) => b.dto.createdAt.compareTo(a.dto.createdAt));

    return results;
  }

  // ==============================================
  // MARK: - Delete
  // ==============================================

  /// Deletes the contact relationship identified by [contactId].
  Future<void> deleteContact(String contactId) async {
    await _contacts.doc(contactId).delete();
  }
}
