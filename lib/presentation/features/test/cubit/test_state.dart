import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/test/entities/test_item.dart';

part 'test_state.freezed.dart';

@freezed
abstract class TestState with _$TestState {
  const factory TestState.initial() = _Initial;
  const factory TestState.loading() = _Loading;
  const factory TestState.loaded(List<TestItem> items) = _Loaded;
  const factory TestState.error(AppFailure failure) = _Error;
}
