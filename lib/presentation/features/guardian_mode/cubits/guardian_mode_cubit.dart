import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';

part 'guardian_mode_state.dart';
part 'guardian_mode_cubit.freezed.dart';

class GuardianModeCubit extends Cubit<GuardianModeCubitState> {
  GuardianModeCubit({
    required String uid,
    required ContactRepository contactRepository,
    required GuardianSessionRepository guardianSessionRepository,
  }) : _uid = uid,
       _contactRepository = contactRepository,
       _guardianSessionRepository = guardianSessionRepository,
       super(const GuardianModeCubitState());

  final String _uid;
  final ContactRepository _contactRepository;
  final GuardianSessionRepository _guardianSessionRepository;

  // ==============================================
  // MARK: - Session loading
  // ==============================================

  /// Queries Firestore for an active guardian session and updates state.
  Future<void> loadSessionState() async {
    appLogger.fine('Loading guardian session state for uid: $_uid');
    emit(state.copyWith(isLoadingSession: true, failure: null));

    final result = await _guardianSessionRepository.getActiveSession(_uid);

    result.when(
      success: (session) {
        appLogger.info(
          session != null
              ? 'Active guardian session found for uid: $_uid'
              : 'No active guardian session for uid: $_uid',
        );
        emit(state.copyWith(isLoadingSession: false, activeSession: session));
      },
      failure: (failure) {
        appLogger.severe('Failed to load guardian session state', failure);
        emit(state.copyWith(isLoadingSession: false, failure: failure));
      },
    );
  }

  // ==============================================
  // MARK: - Session activation
  // ==============================================

  /// Creates a new guardian mode session using the current pending form data.
  ///
  /// On success, reloads the active session to populate [activeSession] with the server-assigned ID.
  Future<void> activateSession({
    required GuardianCoordinate initialLocation,
  }) async {
    final destination = state.pendingDestination;
    final duration = state.pendingDuration;
    if (duration == null) return;

    appLogger.fine('Activating guardian session for uid: $_uid');
    emit(state.copyWith(isActivating: true, activateFailure: null));

    final description = (state.pendingDescription?.trim().isNotEmpty ?? false)
        ? state.pendingDescription
        : null;

    final createResult = await _guardianSessionRepository.createSession(
      ownerUid: _uid,
      destination: destination,
      estimatedDuration: duration,
      initialLocation: initialLocation,
      description: description,
    );

    if (createResult is Failure) {
      appLogger.warning('Guardian session activation failed');
      emit(
        state.copyWith(
          isActivating: false,
          activateFailure: (createResult as Failure<void>).failure,
        ),
      );
      return;
    }

    // Fetch the newly created session.
    final sessionResult = await _guardianSessionRepository.getActiveSession(
      _uid,
    );
    final session = sessionResult.valueOrNull;
    appLogger.info('Guardian session activated for uid: $_uid');
    emit(state.copyWith(isActivating: false, activeSession: session));
  }

  /// Clears the active session state.
  // TODO: implement session cancellation with service (two posible cancelations)
  void clearActiveSession() {
    emit(
      state.copyWith(
        activeSession: null,
        pendingDestination: null,
        pendingDuration: null,
        pendingDescription: null,
      ),
    );
  }

  // ==============================================
  // MARK: - Pending form state
  // ==============================================

  void updatePendingDestination(GuardianCoordinate? destination) {
    emit(state.copyWith(pendingDestination: destination));
  }

  void updatePendingDuration(Duration? duration) {
    emit(state.copyWith(pendingDuration: duration));
  }

  void updatePendingDescription(String? description) {
    emit(state.copyWith(pendingDescription: description));
  }

  void consumeActivateFailure() {
    emit(state.copyWith(activateFailure: null));
  }

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
