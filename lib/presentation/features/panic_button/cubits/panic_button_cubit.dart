import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

part 'panic_button_state.dart';
part 'panic_button_cubit.freezed.dart';

class PanicButtonCubit extends Cubit<PanicButtonCubitState> {
  PanicButtonCubit({
    required String uid,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
  }) : _uid = uid,
       _alertRepository = alertRepository,
       _userProfileRepository = userProfileRepository,
       super(const PanicButtonCubitState());

  final String _uid;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;

  /// Queries Firestore for an active alert and sets the initial button state.
  Future<void> loadAlertState() async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _alertRepository.getActiveAlert(_uid);

    result.when(
      success: (alert) {
        if (alert != null) {
          emit(
            state.copyWith(
              isLoading: false,
              buttonState: PanicButtonState.active,
              activeAlertActivatedAt: alert.activatedAt,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              buttonState: PanicButtonState.normal,
              activeAlertActivatedAt: null,
            ),
          );
        }
      },
      failure: (failure) =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }

  /// Creates a new panic alert for the current user.
  Future<void> activateAlert() async {
    emit(state.copyWith(isActivating: true, activateFailure: null));

    // Resolve owner username before creating the alert.
    final profileResult = await _userProfileRepository.getProfile(_uid);
    String? username;
    profileResult.when(
      success: (profile) => username = profile.username ?? _uid,
      failure: (failure) =>
          emit(state.copyWith(isActivating: false, activateFailure: failure)),
    );
    if (username == null) return;

    // Gather location and battery concurrently.
    final (position, batteryLevel) = await (
      _fetchPosition(),
      _fetchBatteryLevel(),
    ).wait;

    final result = await _alertRepository.createAlert(
      ownerUid: _uid,
      ownerUsername: username!,
      alertType: AlertType.panic,
      latitude: position?.latitude ?? 0.0,
      longitude: position?.longitude ?? 0.0,
      batteryLevel: batteryLevel,
    );

    result.when(
      success: (_) => emit(
        state.copyWith(
          isActivating: false,
          buttonState: PanicButtonState.active,
          activeAlertActivatedAt: DateTime.now(),
        ),
      ),
      failure: (failure) =>
          emit(state.copyWith(isActivating: false, activateFailure: failure)),
    );
  }

  /// Deactivates the current active alert with an optional [reason].
  Future<void> deactivateAlert({String? reason}) async {
    emit(state.copyWith(isDeactivating: true, deactivateFailure: null));

    final result = await _alertRepository.deactivateAlert(
      ownerUid: _uid,
      cancellationReason: (reason?.trim().isNotEmpty == true) ? reason : null,
    );

    result.when(
      success: (_) => emit(
        state.copyWith(
          isDeactivating: false,
          buttonState: PanicButtonState.normal,
          activeAlertActivatedAt: null,
        ),
      ),
      failure: (failure) => emit(
        state.copyWith(isDeactivating: false, deactivateFailure: failure),
      ),
    );
  }

  // ==============================================
  // MARK: - Private helpers
  // ==============================================

  /// Requests location permission if needed and returns the current position.
  ///
  /// Returns null if permission is denied or location
  /// services are disabled, so the alert can still be created with (0, 0).
  Future<Position?> _fetchPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        appLogger.warning('Location services disabled, alert will use (0,0)');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        appLogger.warning(
          'Location permission denied ($permission), alert will use (0,0)',
        );
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e, st) {
      appLogger.warning('Failed to fetch location for alert', e, st);
      return null;
    }
  }

  /// Returns the current battery level as a percentage (0–100).
  ///
  /// Returns 0 if the level cannot be determined.
  Future<int> _fetchBatteryLevel() async {
    try {
      return await Battery().batteryLevel;
    } catch (e, st) {
      appLogger.warning('Failed to fetch battery level for alert', e, st);
      return 0;
    }
  }
}
