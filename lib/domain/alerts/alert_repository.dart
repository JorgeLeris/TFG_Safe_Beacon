import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/result.dart';

/// Contract for Alert repository.
///
/// Defines the operations available for managing alerts.
/// A user can only have one active alert at a time.
/// Creating an alert requires at least one trusted contact.
abstract class AlertRepository {
  /// Creates a new alert for [ownerUid].
  ///
  /// The alert is linked to all current trusted contacts of the owner so they
  /// can see it. The [trustedContactUids] list is resolved server-side from
  /// the contacts collection at creation time.
  ///
  /// Fails with [AppFailure.conflict] if the user already has an active alert.
  /// Fails with [AppFailure.business] if the user has no trusted contacts.
  Future<Result<void>> createAlert({
    required String ownerUid,
    required String ownerUsername,
    required AlertType alertType,
    required double latitude,
    required double longitude,
    required int batteryLevel,
  });

  /// Deactivates the current active alert for [ownerUid].
  ///
  /// Sets the alert status to [AlertStatus.deactivated], records the
  /// deactivation timestamp, and optionally stores a [cancellationReason].
  ///
  /// Fails with [AppFailure.notFound] if the user has no active alert.
  Future<Result<void>> deactivateAlert({
    required String ownerUid,
    String? cancellationReason,
  });

  /// Returns the active alert for [ownerUid], or null if none exists.
  Future<Result<Alert?>> getActiveAlert(String ownerUid);

  /// Returns the full details of the alert identified by [alertId].
  ///
  /// Fails with [AppFailure.notFound] if the alert does not exist.
  Future<Result<Alert>> getAlertDetails(String alertId);

  /// Returns all alerts that involve [trustedContactUid] as a monitor.
  Future<Result<List<Alert>>> getContactsAlerts(String trustedContactUid);
}
