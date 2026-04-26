import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    required String senderUid,
    required String text,
    required DateTime createdAt,

    /// UIDs of users who have read this message.
    @Default([]) List<String> readBy,
  }) = _Message;
}
