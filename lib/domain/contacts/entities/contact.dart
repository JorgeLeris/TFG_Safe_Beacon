import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';

@freezed
abstract class Contact with _$Contact {
  const factory Contact({
    required String id,
    required String protectedPersonUid,
    required String trustedContactUid,
    required String protectedPersonUsername,
    required String trustedContactUsername,
    required DateTime createdAt,
  }) = _Contact;
}
