import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/test/dto/test_firestore_dto.dart';
import 'package:safe_beacon/data/sources/firebase/test/test_firestore_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/test/entities/test_item.dart';
import 'package:safe_beacon/domain/test/test_repository.dart';

/// Repository for managing `TestItem` entities in Firestore.
class TestRepositoryImpl implements TestRepository {
  /// Creates an instance of [TestRepositoryImpl] using the given
  /// [TestFirestoreApi].
  ///
  /// The [_api] parameter is required and represents the low-level
  TestRepositoryImpl(this._api);

  /// The Firestore api used for CRUD operations.
  final TestFirestoreApi _api;

  /// Creates a new [TestItem] in Firestore.
  ///
  /// The [name] parameter specifies the name of the item to be created.
  /// Returns a [Result] containing `null` on success or an [AppFailure]
  /// if an error occurs.
  @override
  Future<Result<void>> createItem(String name) async {
    appLogger.fine('Creating TestItem with name: $name');

    try {
      await _api.createItem(
        TestFirestoreDto(name: name, createdAt: DateTime.now()),
      );

      appLogger.info('TestItem created successfully: $name');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.warning('Firebase error creating TestItem (code: ${e.code})');
      appLogger.severe('Exception while creating TestItem', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating TestItem', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Retrieves all [TestItem]s from Firestore.
  ///
  /// Returns a [Result] containing a list of [TestItem] on success,
  /// or an [AppFailure] if an error occurs.
  @override
  Future<Result<List<TestItem>>> getItems() async {
    appLogger.fine('Fetching TestItems from Firestore');
    try {
      final docs = await _api.getItems();

      final items = docs
          .map((doc) => TestItem(name: doc.name, createdAt: doc.createdAt))
          .toList();

      appLogger.info('Fetched ${items.length} TestItems');
      return Result.success(items);
    } on FirebaseException catch (e, st) {
      appLogger.warning('Firebase error fetching TestItems (code: ${e.code})');
      appLogger.severe('Exception while fetching TestItems', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching TestItems', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Maps a [FirebaseException] to an [AppFailure].
  ///
  /// This is used internally to convert Firestore-specific errors
  /// into the app's generic failure type.
  AppFailure _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AppFailure.forbidden();
      case 'unavailable':
        return const AppFailure.network();
      default:
        return const AppFailure.unknown();
    }
  }
}
