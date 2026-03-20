import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_request_item.freezed.dart';

enum ContactRequestDirection { sent, received }

@freezed
abstract class ContactRequestItem with _$ContactRequestItem {
  const factory ContactRequestItem({
    required String requestId,
    required ContactRequestDirection direction,
    required String peerUid,
    required String peerUsername,
    String? peerPhoto,
  }) = _ContactRequestItem;
}
