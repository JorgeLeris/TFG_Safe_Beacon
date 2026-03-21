import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';

/// Contract for Contact repository.
///
/// Defines the operations available for managing contact relationships.
abstract class ContactRepository {
  /// Creates a new contact relationship.
  ///
  /// [protectedPersonUid] is the user who sent the original request
  /// (the protected person). [trustedContactUid] is the user who
  /// accepted it (the trusted contact).
  /// Fails with [AppFailure.conflict] if the relationship already exists.
  Future<Result<void>> createContact({
    required String protectedPersonUid,
    required String protectedPersonUsername,
    required String trustedContactUid,
    required String trustedContactUsername,
  });

  /// Returns all trusted contacts of [uid].
  Future<Result<List<Contact>>> getTrustedContacts(String uid);

  /// Returns all people protected by [uid].
  Future<Result<List<Contact>>> getProtectedPeople(String uid);

  /// Deletes the contact relationship identified by [contactId].
  Future<Result<void>> deleteContact({
    required String contactId,
    required String requesterUid,
  });
}
