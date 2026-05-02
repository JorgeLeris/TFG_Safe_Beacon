import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/presentation/features/fall_detection/services/fall_detection_background_service.dart';

part 'fall_detection_state.dart';
part 'fall_detection_cubit.freezed.dart';

/// Manages the fall detection feature lifecycle.
///
/// Responsibilities:
/// * Checking prerequisites (location permission, trusted contacts).
/// * Detecting whether the background fall-detection service is already active on app start.
/// * Starting / stopping the background service.
/// * Listening for alert-generated events from the background service.
class FallDetectionCubit extends Cubit<FallDetectionCubitState> {
  FallDetectionCubit({
    required String uid,
    required ContactRepository contactRepository,
    required AlertRepository alertRepository,
  })  : _uid = uid,
        _contactRepository = contactRepository,
        _alertRepository = alertRepository,
        super(const FallDetectionCubitState()) {
    // Listen for fall alert events from the background service.
    _alertSubscription = FallDetectionBackgroundServiceManager.onAlertGenerated
        .listen(_onFallAlertGenerated);
  }

  final String _uid;
  final ContactRepository _contactRepository;
  final AlertRepository _alertRepository;

  late final StreamSubscription<void> _alertSubscription;

  // ==============================================
  // MARK: - State loading
  // ==============================================

  /// Checks prerequisites and whether the fall detection service is running.
  ///
  /// Should be called on home screen init and after returning from any settings/contacts screen.
  Future<void> loadState() async {
    emit(state.copyWith(status: FallDetectionStatus.loading, failure: null));

    // 1. Check if the background service is already running for fall detection.
    final isRunning = await FallDetectionBackgroundServiceManager.isRunning();

    if (isRunning) {
      // Determine whether there is an active sensor alert.
      final alertResult = await _alertRepository.getActiveAlert(
        _uid,
        alertType: AlertType.sensors,
      );
      final hasActiveAlert = alertResult.valueOrNull != null;
      emit(
        state.copyWith(
          status: hasActiveAlert
              ? FallDetectionStatus.alertActive
              : FallDetectionStatus.active,
          disabledReason: null,
        ),
      );
      return;
    }

    // 2. Not running — check prerequisites before showing the inactive state.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      emit(
        state.copyWith(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.locationPermissionDenied,
        ),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          status: FallDetectionStatus.disabled,
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
        ),
      );
      return;
    }

    final contactsResult = await _contactRepository.getTrustedContacts(_uid);
    final hasContacts = contactsResult.when(
      success: (list) => list.isNotEmpty,
      failure: (_) => true,
    );

    if (!hasContacts) {
      emit(
        state.copyWith(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.noTrustedContacts,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: FallDetectionStatus.inactive,
        disabledReason: null,
      ),
    );
  }

  // ==============================================
  // MARK: - Activation
  // ==============================================

  /// Starts the background fall detection service.
  ///
  /// [locale] is used inside the background isolate to produce localised notification strings.
  Future<void> activate(String locale) async {
    emit(state.copyWith(isActivating: true, failure: null));

    final started = await FallDetectionBackgroundServiceManager.startChecks(
      uid: _uid,
      locale: locale,
    );

    if (!started) {
      appLogger.warning('Fall detection: failed to start background service');
      emit(
        state.copyWith(
          isActivating: false,
          failure: const UnknownFailure('Could not start fall detection'),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isActivating: false,
        status: FallDetectionStatus.active,
        disabledReason: null,
      ),
    );
  }

  // ==============================================
  // MARK: - Deactivation
  // ==============================================

  /// Stops the background service and deactivates any active sensor alert.
  Future<void> deactivate({String? reason}) async {
    emit(state.copyWith(isDeactivating: true, failure: null));

    // Stop the background service first.
    await FallDetectionBackgroundServiceManager.stopChecks();

    // Deactivate the active sensor alert if one exists.
    final deactivateResult = await _alertRepository.deactivateAlert(
      ownerUid: _uid,
      alertType: AlertType.sensors,
      cancellationReason: (reason?.trim().isNotEmpty == true) ? reason : null,
    );

    deactivateResult.onFailure((f) {
      // Not-found is expected when no alert was generated, ignore it.
      appLogger.fine(
        'Fall detection: deactivate alert result — $f (may be expected)',
      );
    });

    emit(
      state.copyWith(
        isDeactivating: false,
        status: FallDetectionStatus.inactive,
        disabledReason: null,
      ),
    );
  }

  // ==============================================
  // MARK: - Permission helpers
  // ==============================================

  /// Triggers the OS location-permission dialog and re-runs [loadState].
  Future<void> requestLocationPermission() async {
    final result = await Geolocator.requestPermission();
    if (result == LocationPermission.denied ||
        result == LocationPermission.deniedForever) {
      emit(state.copyWith(permissionRequestDenied: true));
    }
    await loadState();
  }

  /// Opens app settings so the user can re-enable location permission.
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
    await loadState();
  }

  /// Clears [permissionRequestDenied] after the dialog has been consumed.
  void consumePermissionRequestDenied() {
    emit(state.copyWith(permissionRequestDenied: false));
  }

  // ==============================================
  // MARK: - Alert event
  // ==============================================

  void _onFallAlertGenerated(void _) {
    appLogger.info('Fall detection: alert generated — updating state');
    emit(state.copyWith(status: FallDetectionStatus.alertActive));
  }

  @override
  Future<void> close() {
    _alertSubscription.cancel();
    return super.close();
  }
}
