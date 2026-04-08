import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_item.freezed.dart';

@freezed
abstract class TestItem with _$TestItem {
  // Factory constructor for creating a TestItem instance for app.
  const factory TestItem({required String name, required DateTime createdAt}) =
      _TestItem;
}
