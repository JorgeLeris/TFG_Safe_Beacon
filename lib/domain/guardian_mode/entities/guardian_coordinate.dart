import 'package:freezed_annotation/freezed_annotation.dart';

part 'guardian_coordinate.freezed.dart';

/// A geographic coordinate (latitude/longitude pair) used in guardian sessions.
@freezed
abstract class GuardianCoordinate with _$GuardianCoordinate {
  const factory GuardianCoordinate({
    required double latitude,
    required double longitude,
  }) = _GuardianCoordinate;
}
