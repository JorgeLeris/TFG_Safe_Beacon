import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/test/entities/test_item.dart';

/// Contract for Test repository.
///
/// Defines the operations available for TestItems.
abstract class TestRepository {
  /// Creates a new item.
  Future<Result<void>> createItem(String name);

  /// Retrieves all items.
  Future<Result<List<TestItem>>> getItems();
}
