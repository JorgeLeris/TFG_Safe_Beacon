import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/profile/dto/user_profile_dto.dart';

class UserProfileApi {
  final _firestore = FirebaseFirestore.instance;

  // Returns a reference to the user_profiles collection.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('user_profiles');

  // Returns a reference to the usernames collection, which maps usernames to uids.
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  // =================================
  // MARK: - User Profile Operations
  // =================================

  // Creates a new user profile document using the uid as the document ID.
  Future<void> createProfile(String uid, UserProfileDto dto) async {
    final data = dto.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _collection.doc(uid).set(data);
  }

  // Retrieves a single user profile document by uid.
  // Throws a [StateError] if no document is found.
  Future<UserProfileDto> getProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('No user profile found for uid: $uid');
    }
    return UserProfileDto.fromFirestore(doc.data()!);
  }

  // Updates only the provided fields of an existing user profile document.
  // Fields with null values are omitted so existing data is preserved.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _collection.doc(uid).update(fields);
  }

  // =================================
  // MARK: - FCM Token Management
  // =================================

  /// Stores [token] as the single FCM token for the user document,
  /// overwriting any previously saved token.
  Future<void> saveFcmToken(String uid, String token) async {
    await _collection.doc(uid).update({'fcmToken': token});
  }

  /// Removes the FCM token field from the user document.
  Future<void> clearFcmToken(String uid, String token) async {
    await _collection.doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  // =================================
  // MARK: - Username Reservation
  // =================================

  /// Returns true if the username document already exists.
  Future<bool> usernameExists(String username) async {
    final doc = await _usernames.doc(username).get();
    return doc.exists;
  }

  /// Creates the user profile and reserves the username atomically.
  /// Throws if the username was taken between the check and the write.
  Future<void> createProfileWithUsername(
    String uid,
    UserProfileDto dto,
    String username,
  ) async {
    final usernameRef = _usernames.doc(username);
    final profileRef = _collection.doc(uid);

    await _firestore.runTransaction((tx) async {
      final usernameSnap = await tx.get(usernameRef);
      if (usernameSnap.exists) {
        throw Exception('username_taken');
      }

      final profileData = dto.toJson();
      profileData['createdAt'] = FieldValue.serverTimestamp();
      profileData['username'] = username;

      tx.set(profileRef, profileData);
      tx.set(usernameRef, {'uid': uid});
    });
  }
}
