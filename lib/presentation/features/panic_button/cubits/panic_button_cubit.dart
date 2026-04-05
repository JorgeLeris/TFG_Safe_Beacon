import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/notification_service.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

part 'panic_button_state.dart';
part 'panic_button_cubit.freezed.dart';

class PanicButtonCubit extends Cubit<PanicButtonCubitState> {
  PanicButtonCubit({
    required String uid,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
    required ContactRepository contactRepository,
  }) : _uid = uid,
       _alertRepository = alertRepository,
       _userProfileRepository = userProfileRepository,
       _contactRepository = contactRepository,
       super(const PanicButtonCubitState());

  final String _uid;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;
  final ContactRepository _contactRepository;

  /// Queries Firestore for an active alert and sets the initial button state.
  ///
  /// Also checks location permission. If permission is denied, the button will be disabled.
  Future<void> loadAlertState() async {
    emit(
      state.copyWith(
        isLoading: true,
        buttonState: PanicButtonState.loading,
        failure: null,
        permissionRequestDenied: false,
      ),
    );

    // Check location permission first.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      emit(
        state.copyWith(
          isLoading: false,
          buttonState: PanicButtonState.disabled,
          disabledReason: DisabledReason.locationPermissionDenied,
        ),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          isLoading: false,
          buttonState: PanicButtonState.disabled,
          disabledReason: DisabledReason.locationPermissionDeniedForever,
        ),
      );
      return;
    }

    final alertResult = await _alertRepository.getActiveAlert(_uid);

    if (alertResult is Failure<Alert?>) {
      emit(state.copyWith(isLoading: false, failure: alertResult.failure));
      return;
    }

    final alert = (alertResult as Success<Alert?>).value;

    if (alert != null) {
      emit(
        state.copyWith(
          isLoading: false,
          buttonState: PanicButtonState.active,
          activeAlertActivatedAt: alert.activatedAt,
          disabledReason: null,
        ),
      );
      return;
    }

    // No active alert: check whether the user has trusted contacts.
    // If not, the button must stay disabled to prevent a pointless activation.
    final contactsResult = await _contactRepository.getTrustedContacts(_uid);
    final hasContacts = contactsResult.when(
      success: (list) => list.isNotEmpty,
      failure: (_) => true,
    );

    emit(
      state.copyWith(
        isLoading: false,
        buttonState: hasContacts
            ? PanicButtonState.normal
            : PanicButtonState.disabled,
        disabledReason: hasContacts ? null : DisabledReason.noTrustedContacts,
        activeAlertActivatedAt: null,
      ),
    );
  }

  /// Creates a new panic alert for the current user.
  ///
  /// Emits [PanicButtonState.loading] while the operation is in flight.
  /// Transitions to [PanicButtonState.disabled] with [DisabledReason.noTrustedContacts]
  Future<void> activateAlert(AppLocalizations l10n) async {
    emit(
      state.copyWith(
        isActivating: true,
        activateFailure: null,
        buttonState: PanicButtonState.loading,
      ),
    );

    // Resolve owner username before creating the alert.
    final profileResult = await _userProfileRepository.getProfile(_uid);
    String? username;
    String? name;
    profileResult.when(
      success: (profile) {
        username = profile.username ?? _uid;
        name =
            '${profile.name}'
                    ' ${profile.surname ?? ''}'
                .capitalized();
      },
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

    if (result.isFailure) {
      final failure = (result as Failure<void>).failure;
      // No trusted contacts.
      if (failure is BusinessFailure &&
          failure.message == 'no_trusted_contacts') {
        emit(
          state.copyWith(
            isActivating: false,
            buttonState: PanicButtonState.disabled,
            disabledReason: DisabledReason.noTrustedContacts,
            activateFailure: null,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isActivating: false,
          buttonState: PanicButtonState.normal,
          activateFailure: failure,
        ),
      );
      return;
    }

    // Fetch the newly created alert to get the embedded trustedContactUids.
    final activeAlertResult = await _alertRepository.getActiveAlert(_uid);
    final trustedContactUids = activeAlertResult.when(
      success: (alert) => alert?.trustedContactUids ?? <String>[],
      failure: (_) => <String>[],
    );

    // Fetch FCM tokens of all trusted contacts (users without a token are excluded).
    final tokensResult = await _userProfileRepository.getFcmTokensForUsers(
      trustedContactUids,
    );
    tokensResult.when(
      success: (tokens) {
        appLogger.info('Fetched ${tokens.length} FCM token(s)');
        for (var token in tokens) {
          appLogger.info('Would send alert notification to token: $token');
          NotificationService().sendPushNotification(
            deviceToken: token,
            title: l10n.notificationAlertTitle(name!),
            body: l10n.notificationAlertBody(name!),
          );
        }
      },
      failure: (f) => appLogger.warning(
        'Failed to fetch FCM tokens for alert notification — owner: $_uid — $f',
      ),
    );

    emit(
      state.copyWith(
        isActivating: false,
        buttonState: PanicButtonState.active,
        activeAlertActivatedAt: DateTime.now(),
        disabledReason: null,
      ),
    );
  }

  /// Deactivates the current active alert with an optional [reason].
  ///
  /// Emits [PanicButtonState.loading] while the operation is in flight.
  Future<void> deactivateAlert({String? reason}) async {
    emit(
      state.copyWith(
        isDeactivating: true,
        deactivateFailure: null,
        buttonState: PanicButtonState.loading,
      ),
    );

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

  /// Triggers the native OS location permission dialog and re-runs [loadAlertState].
  /// If the user denies the request, emits [permissionRequestDenied] so the UI
  /// can show an informational dialog.
  Future<void> requestLocationPermission() async {
    final result = await Geolocator.requestPermission();
    if (result == LocationPermission.denied ||
        result == LocationPermission.deniedForever) {
      emit(state.copyWith(permissionRequestDenied: true));
    }
    await loadAlertState();
  }

  /// Opens the app settings page so the user can manually re-enable location
  /// permission. Called when the disabled reason is
  /// [DisabledReason.locationPermissionDeniedForever].
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
    // Re-check after the user returns from Settings.
    await loadAlertState();
  }

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
