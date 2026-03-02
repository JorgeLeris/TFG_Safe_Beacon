import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/test/dto/test_firestore_dto.dart';

class TestFirestoreApi {
  final FirebaseFirestore _firestore;

  TestFirestoreApi(this._firestore);

  // Creates a new item in the Firestore collection.
  Future<DocumentReference> createItem(TestFirestoreDto dto) {
    final data = dto.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();

    return _firestore.collection('test_items').add(data);
  }

  // Retrieves all items from the Firestore collection, ordered by creation date.
  Future<List<TestFirestoreDto>> getItems() async {
    final snapshot = await _firestore
        .collection('test_items')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TestFirestoreDto.fromFirestore(doc.data()))
        .toList();
  }
}
