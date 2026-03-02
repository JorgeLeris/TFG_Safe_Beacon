import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/test/test_repository.dart';
import 'package:safe_beacon/presentation/features/test/cubit/test_state.dart';

/// Cubit for managing the state of the Test feature.
class TestCubit extends Cubit<TestState> {
  TestCubit(this._repository) : super(const TestState.initial());

  // Repository for accessing Test data.
  final TestRepository _repository;

  /// Loads the list of items from the repository and updates the state accordingly.
  Future<void> load() async {
    emit(const TestState.loading());
    final result = await _repository.getItems();

    result.when(
      success: (items) => emit(TestState.loaded(items)),
      failure: (failure) => emit(TestState.error(failure)),
    );
  }

  // Adds a new item to the repository and reloads the list.
  Future<void> addItem() async {
    await _repository.createItem(
      'Item ${DateTime.now().millisecondsSinceEpoch}',
    );
    await load();
  }
}
