import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    required this.name,
    this.surname,
    this.gender,
    this.birthDate,
    this.description,
    this.profilePhoto,
    this.createdAt,
    required this.username,
  });

  final String name;
  final String? surname;
  final String username;

  /// One of: "male", "female", "other".
  final String? gender;

  /// Date string with format DD/MM/AAAA.
  final String? birthDate;

  final String? description;

  /// A base64 String, or a remote URL String.
  final String? profilePhoto;

  final DateTime? createdAt;

  // Factory constructor to create a UserProfileDto from a JSON map.
  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  // Converts this DTO to a JSON map for Firestore storage.
  Map<String, dynamic> toJson() {
    final json = _$UserProfileDtoToJson(this);
    json.remove('createdAt');
    return json;
  }

  // Factory constructor to create a UserProfileDto from raw
  // Firestore document data, including the server-generated createdAt.
  factory UserProfileDto.fromFirestore(Map<String, dynamic> data) {
    return UserProfileDto(
      name: data['name'] as String? ?? '',
      surname: data['surname'] as String?,
      username: data['username'] as String? ?? '',
      gender: data['gender'] as String?,
      birthDate: data['birthDate'] as String?,
      description: data['description'] as String?,
      profilePhoto: data['profilePhoto'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
