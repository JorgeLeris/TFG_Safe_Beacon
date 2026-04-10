import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';

part 'guardian_mode_state.dart';
part 'guardian_mode_cubit.freezed.dart';

class GuardianModeCubit extends Cubit<GuardianModeCubitState> {
  GuardianModeCubit({
    required String uid,
    required ContactRepository contactRepository,
  }) : _uid = uid,
       _contactRepository = contactRepository,
       super(const GuardianModeCubitState());

  final String _uid;
  final ContactRepository _contactRepository;

  // ==============================================
  // MARK: - Navigation guard
  // ==============================================

  /// Checks prerequisites (location permission + trusted contacts) before
  /// allowing navigation to the guardian mode screen.
  Future<void> requestNavigate() async {
    // TODO: manage disable case in feature configuration - add to state other disabled cases (more permission cases)
    emit(
      state.copyWith(
        isChecking: true,
        canNavigate: false,
        blockedReason: null,
        showPermissionDeniedDialog: false,
      ),
    );

    // Check location permission first.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason: GuardianModeBlockedReason.locationPermissionDenied,
        ),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason:
              GuardianModeBlockedReason.locationPermissionDeniedForever,
        ),
      );
      return;
    }

    // Check that the user has at least one trusted contact.
    final contactsResult = await _contactRepository.getTrustedContacts(_uid);
    final hasContacts = contactsResult.when(
      success: (list) => list.isNotEmpty,
      failure: (_) => true,
    );

    if (!hasContacts) {
      emit(
        state.copyWith(
          isChecking: false,
          blockedReason: GuardianModeBlockedReason.noTrustedContacts,
        ),
      );
      return;
    }

    emit(state.copyWith(isChecking: false, canNavigate: true));
  }

  /// Clears [canNavigate] after the navigation event has been consumed.
  void consumeNavigation() {
    emit(state.copyWith(canNavigate: false));
  }

  /// Clears [blockedReason] after the dialog has been consumed.
  void consumeBlockedReason() {
    emit(state.copyWith(blockedReason: null));
  }

  // ==============================================
  // MARK: - Location permission helpers
  // ==============================================

  /// Triggers the native OS location-permission dialog.
  Future<void> requestLocationPermission() async {
    emit(state.copyWith(blockedReason: null));
    final result = await Geolocator.requestPermission();
    if (result == LocationPermission.denied ||
        result == LocationPermission.deniedForever) {
      emit(state.copyWith(showPermissionDeniedDialog: true));
      return;
    }
    emit(state.copyWith(permissionJustGranted: true));
    await requestNavigate();
  }

  /// Clears [permissionJustGranted] after the event has been consumed.
  void consumePermissionGranted() {
    emit(state.copyWith(permissionJustGranted: false));
  }

  /// Opens the app settings page so the user can manually re-grant location access.
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
    emit(const GuardianModeCubitState());
  }
}
