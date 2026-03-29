import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert.freezed.dart';

enum AlertType { panic, guardian, sensors, other }

enum AlertStatus { active, deactivated }

@freezed
abstract class Alert with _$Alert {
  const factory Alert({
    required String id,
    required String ownerUid,
    required String ownerUsername,
    required AlertType alertType,
    required double latitude,
    required double longitude,
    required int batteryLevel,
    required AlertStatus status,
    required List<String> trustedContactUids,
    String? cancellationReason,
    required DateTime activatedAt,
    DateTime? deactivatedAt,
  }) = _Alert;
}
