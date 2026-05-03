import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';
import 'package:safe_beacon/presentation/features/fall_detection/cubits/fall_detection_cubit.dart';
import 'package:safe_beacon/presentation/features/fall_detection/services/fall_detection_background_service.dart';

// MARK: - DUMMY DATA

class MockContactRepository extends Mock implements ContactRepository {}

class MockAlertRepository extends Mock implements AlertRepository {}

// Geolocator MethodChannel used by the plugin.
const _geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

// Geolocator LocationPermission enum indices (as returned by the platform):
//   0 = denied
//   1 = deniedForever
//   2 = whileInUse  (granted)
//   3 = always      (granted)
void _setGeolocatorChannel({
  int checkPermission = 2,
  int requestPermission = 2,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_geolocatorChannel, (call) async {
    return switch (call.method) {
      'checkPermission' => checkPermission,
      'requestPermission' => requestPermission,
      'openAppSettings' => true,
      _ => null,
    };
  });
}

const _uid = 'uid-fall-test';
const _dummyFailure = AppFailure.unknown();

final _dummyContact = Contact(
  id: 'contact-1',
  protectedPersonUid: _uid,
  trustedContactUid: 'trusted-uid',
  protectedPersonUsername: 'me',
  trustedContactUsername: 'them',
  createdAt: DateTime(2024),
);


// MARK: - TEST CASES

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockContactRepository mockContactRepository;
  late MockAlertRepository mockAlertRepository;
  late FallDetectionCubit cubit;

  setUp(() {
    mockContactRepository = MockContactRepository();
    mockAlertRepository = MockAlertRepository();
    cubit = FallDetectionCubit(
      uid: _uid,
      contactRepository: mockContactRepository,
      alertRepository: mockAlertRepository,
    );
  });

  tearDown(() => cubit.close());

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, null);
  });

  // ---------------------------------------------------------------------------
  // loadState
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.loadState', () {
    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN permission granted and at least one trusted contact, '
      'WHEN loadState is called, '
      'THEN should emit [inactive]',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (c) => c.loadState(),
      // The cubit's _emitted flag is false at construction, so the first
      // emit() call always fires even if the value equals the initial state.
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN permission "always" (index 3) and trusted contacts, '
      'WHEN loadState is called, '
      'THEN should also emit [inactive] (always = granted)',
      build: () {
        _setGeolocatorChannel(checkPermission: 3);
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (c) => c.loadState(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN a previous non-loading state, '
      'WHEN loadState is called, '
      'THEN should emit [loading, inactive] (loading transition is visible)',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
        disabledReason: FallDetectionDisabledReason.noTrustedContacts,
      ),
      act: (c) => c.loadState(),
      expect: () => [
        // loading clears the previous disabledReason via copyWith
        const FallDetectionCubitState(
          disabledReason: FallDetectionDisabledReason.noTrustedContacts,
        ),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN location permission is denied, '
      'WHEN loadState is called, '
      'THEN should emit [disabled with locationPermissionDenied]',
      build: () {
        _setGeolocatorChannel(checkPermission: 0);
        return cubit;
      },
      act: (c) => c.loadState(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.locationPermissionDenied,
        ),
      ],
      verify: (_) {
        // Contact check must be skipped when permission is not granted.
        verifyNever(() => mockContactRepository.getTrustedContacts(any()));
      },
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN location permission is permanently denied, '
      'WHEN loadState is called, '
      'THEN should emit [disabled with locationPermissionDeniedForever]',
      build: () {
        _setGeolocatorChannel(checkPermission: 1);
        return cubit;
      },
      act: (c) => c.loadState(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockContactRepository.getTrustedContacts(any()));
      },
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN permission granted but no trusted contacts, '
      'WHEN loadState is called, '
      'THEN should emit [disabled with noTrustedContacts]',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => const Result.success([]));
        return cubit;
      },
      act: (c) => c.loadState(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.noTrustedContacts,
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[EDGE CASE] - GIVEN the contacts repository returns a failure, '
      'WHEN loadState is called, '
      'THEN should treat as "has contacts" and emit [inactive]',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (c) => c.loadState(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[EDGE CASE] - GIVEN a previous failure in state, '
      'WHEN loadState is called, '
      'THEN should clear the failure field in the loading emission',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      seed: () =>
          const FallDetectionCubitState(failure: AppFailure.unknown('prev')),
      act: (c) => c.loadState(),
      expect: () => [
        // loading emission clears failure
        const FallDetectionCubitState(),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // deactivate
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.deactivate', () {
    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN alert deactivation succeeds and a reason is provided, '
      'WHEN deactivate is called, '
      'THEN should emit [deactivating, inactive] and pass the reason to the repo',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (c) => c.deactivate(reason: 'Going home now'),
      expect: () => [
        const FallDetectionCubitState(isDeactivating: true),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
      verify: (_) {
        verify(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: 'Going home now',
          ),
        ).called(1);
      },
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN alert deactivation succeeds and no reason is provided, '
      'WHEN deactivate is called, '
      'THEN should emit [deactivating, inactive] with null cancellationReason',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (c) => c.deactivate(),
      expect: () => [
        const FallDetectionCubitState(isDeactivating: true),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
      verify: (_) {
        verify(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
          ),
        ).called(1);
      },
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[EDGE CASE] - GIVEN the reason is whitespace-only, '
      'WHEN deactivate is called, '
      'THEN should pass null as cancellationReason (whitespace is trimmed)',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (c) => c.deactivate(reason: '   '),
      expect: () => [
        const FallDetectionCubitState(isDeactivating: true),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
      verify: (_) {
        verify(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
          ),
        ).called(1);
      },
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[EDGE CASE] - GIVEN alert deactivation returns a failure (e.g. not found), '
      'WHEN deactivate is called, '
      'THEN failure is silently ignored and state still reaches [deactivating, inactive]',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (c) => c.deactivate(reason: 'some reason'),
      expect: () => [
        const FallDetectionCubitState(isDeactivating: true),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN the cubit is in alertActive state, '
      'WHEN deactivate is called, '
      'THEN should clear the alert and reach inactive',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      seed: () =>
          const FallDetectionCubitState(status: FallDetectionStatus.alertActive),
      act: (c) => c.deactivate(reason: 'Alert resolved'),
      expect: () => [
        const FallDetectionCubitState(
          status: FallDetectionStatus.alertActive,
          isDeactivating: true,
        ),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[EDGE CASE] - GIVEN the cubit has a disabledReason set, '
      'WHEN deactivate is called, '
      'THEN disabledReason is cleared in the final inactive state',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlert(
            ownerUid: _uid,
            alertType: AlertType.sensors,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
        disabledReason: FallDetectionDisabledReason.guardianModeRunning,
      ),
      act: (c) => c.deactivate(),
      expect: () => [
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.guardianModeRunning,
          isDeactivating: true,
        ),
        // disabledReason is cleared to null
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // requestLocationPermission
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.requestLocationPermission', () {
    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN the user denies the permission request, '
      'WHEN requestLocationPermission is called, '
      'THEN should emit permissionRequestDenied: true then disabled state',
      build: () {
        _setGeolocatorChannel(requestPermission: 0, checkPermission: 0);
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        // permissionRequestDenied is set before loadState is called
        const FallDetectionCubitState(
          permissionRequestDenied: true,
        ),
        // loadState resolves to disabled (checkPermission still 0)
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.locationPermissionDenied,
          permissionRequestDenied: true,
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN the user permanently denies the permission request, '
      'WHEN requestLocationPermission is called, '
      'THEN should emit permissionRequestDenied: true then deniedForever disabled state',
      build: () {
        _setGeolocatorChannel(requestPermission: 1, checkPermission: 1);
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        const FallDetectionCubitState(
          permissionRequestDenied: true,
        ),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
          permissionRequestDenied: true,
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN the user grants the permission, '
      'WHEN requestLocationPermission is called, '
      'THEN should NOT set permissionRequestDenied and should emit [inactive]',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        // loadState() is the first emit() call; _emitted=false so it always fires.
        const FallDetectionCubitState(),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[HAPPY PATH] - GIVEN the user grants permission but has no contacts, '
      'WHEN requestLocationPermission is called, '
      'THEN should NOT set permissionRequestDenied and reach disabled/noTrustedContacts',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => const Result.success([]));
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        const FallDetectionCubitState(),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.noTrustedContacts,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // openLocationSettings
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.openLocationSettings', () {
    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[STATE UPDATE] - GIVEN settings are opened and permission is now granted, '
      'WHEN openLocationSettings is called, '
      'THEN should call loadState and transition to inactive',
      build: () {
        _setGeolocatorChannel();
        when(() => mockContactRepository.getTrustedContacts(_uid))
            .thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
        disabledReason:
            FallDetectionDisabledReason.locationPermissionDeniedForever,
      ),
      act: (c) => c.openLocationSettings(),
      expect: () => [
        // loading — visible because seed was disabled (different from loading)
        const FallDetectionCubitState(
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
        ),
        const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[STATE UPDATE] - GIVEN settings are opened but permission is still denied, '
      'WHEN openLocationSettings is called, '
      'THEN should remain in disabled state after loadState',
      build: () {
        _setGeolocatorChannel(checkPermission: 1);
        return cubit;
      },
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
        disabledReason:
            FallDetectionDisabledReason.locationPermissionDeniedForever,
      ),
      act: (c) => c.openLocationSettings(),
      expect: () => [
        const FallDetectionCubitState(
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
        ),
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason:
              FallDetectionDisabledReason.locationPermissionDeniedForever,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // consumePermissionRequestDenied
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.consumePermissionRequestDenied', () {
    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[RESET ACTION] - GIVEN permissionRequestDenied is true, '
      'WHEN consumePermissionRequestDenied is called, '
      'THEN should clear the flag without touching other state fields',
      build: () => cubit,
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
        disabledReason: FallDetectionDisabledReason.locationPermissionDenied,
        permissionRequestDenied: true,
      ),
      act: (c) => c.consumePermissionRequestDenied(),
      expect: () => [
        const FallDetectionCubitState(
          status: FallDetectionStatus.disabled,
          disabledReason: FallDetectionDisabledReason.locationPermissionDenied,
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[RESET ACTION] - GIVEN permissionRequestDenied is already false, '
      'WHEN consumePermissionRequestDenied is called, '
      'THEN should not emit any state (no change)',
      build: () => cubit,
      seed: () => const FallDetectionCubitState(
        status: FallDetectionStatus.disabled,
      ),
      act: (c) => c.consumePermissionRequestDenied(),
      expect: () => [],
    );
  });

  // ---------------------------------------------------------------------------
  // activate
  // ---------------------------------------------------------------------------
  //
  // On macOS (test host) the iOS code path is used for the background service.
  // FallDetectionBackgroundServiceManager.startChecks() starts an in-process
  // FallDetectionCheckService and returns true (the accelerometer EventChannel
  // error is delivered asynchronously and does not prevent the service from
  // being marked as running). The static _iosCheckService is reset by the
  // group tearDown after each test to prevent state leaking.
  // ---------------------------------------------------------------------------

  group('FallDetectionCubit.activate', () {
    tearDown(() async {
      await FallDetectionBackgroundServiceManager.stopChecks();
    });

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN the background service cannot start (test environment), '
      'WHEN activate is called, '
      'THEN should emit [activating, failure with UnknownFailure]',
      build: () => cubit,
      act: (c) => c.activate('es'),
      expect: () => [
        const FallDetectionCubitState(isActivating: true),
        const FallDetectionCubitState(
          failure: AppFailure.unknown('Could not start fall detection'),
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN the cubit is in inactive state, '
      'WHEN activate is called, '
      'THEN isActivating is emitted relative to the seed state before failing',
      build: () => cubit,
      seed: () =>
          const FallDetectionCubitState(status: FallDetectionStatus.inactive),
      act: (c) => c.activate('es'),
      expect: () => [
        const FallDetectionCubitState(
          status: FallDetectionStatus.inactive,
          isActivating: true,
        ),
        const FallDetectionCubitState(
          status: FallDetectionStatus.inactive,
          failure: AppFailure.unknown('Could not start fall detection'),
        ),
      ],
    );

    blocTest<FallDetectionCubit, FallDetectionCubitState>(
      '[ERROR PATH] - GIVEN a different locale, '
      'WHEN activate is called, '
      'THEN should also emit [activating, failure] (locale does not affect the failure path)',
      build: () => cubit,
      act: (c) => c.activate('en'),
      expect: () => [
        const FallDetectionCubitState(isActivating: true),
        const FallDetectionCubitState(
          failure: AppFailure.unknown('Could not start fall detection'),
        ),
      ],
    );
  });
}
