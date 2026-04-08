import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  // Factory constructor for creating a UserProfile instance for the app.
  const factory UserProfile({
    required String uid,
    required String name,
    String? username,
    String? surname,
    String? gender,
    String? birthDate,
    String? description,
    String? profilePhoto,
  }) = _UserProfile;

  const UserProfile._();

  /// Returns a map of only the non-null mutable fields.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      if (surname != null) 'surname': surname,
      if (username != null) 'username': username,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birthDate': birthDate,
      if (description != null) 'description': description,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
    };
  }
}
