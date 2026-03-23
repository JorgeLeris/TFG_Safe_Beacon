import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_request.freezed.dart';

@freezed
abstract class ContactRequest with _$ContactRequest {
  const factory ContactRequest({
    required String id,
    required String senderUid,
    required String receiverUid,
    required String senderUsername,
    required String receiverUsername,
    required DateTime createdAt,
  }) = _ContactRequest;
}
