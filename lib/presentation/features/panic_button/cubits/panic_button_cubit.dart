import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

    // TODO: Get real GPS coordinates via geolocator package.
    // TODO: Get real battery level via battery_plus package.
    final result = await _alertRepository.createAlert(
      ownerUid: _uid,
      ownerUsername: username!,
      alertType: AlertType.panic,
      latitude: 0.0,
      longitude: 0.0,
      batteryLevel: 0,
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
}
