import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/profile/dto/user_profile_dto.dart';

class UserProfileApi {
  final _firestore = FirebaseFirestore.instance;

  // Returns a reference to the user_profiles collection.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('user_profiles');

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
}
