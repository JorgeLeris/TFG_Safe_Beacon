import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/panic_button/cubits/panic_button_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/buttons/panic_button.dart';

// MARK: - MOCKS

class MockAlertRepository extends Mock implements AlertRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockContactRepository extends Mock implements ContactRepository {}

// MARK: - DUMMY DATA

const _uid = 'uid-123';
const _dummyFailure = AppFailure.unknown();

final _dummyAlert = Alert(
  id: 'alert-1',
  ownerUid: _uid,
  ownerUsername: 'john',
  alertType: AlertType.panic,
  latitude: 0,
  longitude: 0,
  batteryLevel: 50,
  status: AlertStatus.active,
  trustedContactUids: const ['c1'],
  activatedAt: DateTime(2024),
);

const _dummyProfile = UserProfile(
  uid: _uid,
  name: 'John',
  surname: 'Doe',
  username: 'john',
);

final _dummyContact = Contact(
  id: 'contact-1',
  protectedPersonUid: _uid,
  trustedContactUid: 'c1',
  protectedPersonUsername: 'john',
  trustedContactUsername: 'friend',
  createdAt: DateTime(2024),
);

// MARK: - TESTS

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel geolocatorChannel = MethodChannel(
    'flutter.baseflow.com/geolocator',
  );

  late MockAlertRepository alertRepository;
  late MockUserProfileRepository userProfileRepository;
  late MockContactRepository contactRepository;
  late PanicButtonCubit cubit;

  setUpAll(() {
    registerFallbackValue(AlertType.panic);
    registerFallbackValue(AlertStatus.active);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'checkPermission':
              return 2;
            case 'isLocationServiceEnabled':
              return true;
            case 'getCurrentPosition':
              return {
                'latitude': 0.0,
                'longitude': 0.0,
                'timestamp': DateTime.now().toIso8601String(),
                'accuracy': 1.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'speed_accuracy': 0.0,
              };
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null);
  });

  setUp(() {
    alertRepository = MockAlertRepository();
    userProfileRepository = MockUserProfileRepository();
    contactRepository = MockContactRepository();

    cubit = PanicButtonCubit(
      uid: _uid,
      alertRepository: alertRepository,
      userProfileRepository: userProfileRepository,
      contactRepository: contactRepository,
    );
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // loadAlertState
  // ---------------------------------------------------------------------------

  group('loadAlertState', () {
    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[HAPPY PATH] - active alert',
      build: () {
        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => Result<Alert?>.success(_dummyAlert));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertState(),
      expect: () => [
        isA<PanicButtonCubitState>().having(
          (s) => s.isLoading,
          'loading',
          true,
        ),
        isA<PanicButtonCubitState>()
            .having((s) => s.buttonState, 'state', PanicButtonState.active)
            .having(
              (s) => s.activeAlertActivatedAt,
              'date',
              _dummyAlert.activatedAt,
            ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[HAPPY PATH] - no alert + has contacts',
      build: () {
        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => const Result<Alert?>.success(null));
        when(
          () => contactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertState(),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.buttonState,
          'state',
          PanicButtonState.normal,
        ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[EDGE] - no alert + no contacts',
      build: () {
        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => const Result<Alert?>.success(null));
        when(
          () => contactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertState(),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>()
            .having((s) => s.buttonState, 'state', PanicButtonState.disabled)
            .having(
              (s) => s.disabledReason,
              'reason',
              DisabledReason.noTrustedContacts,
            ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[ERROR PATH] - alert failure',
      build: () {
        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertState(),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.failure,
          'failure',
          _dummyFailure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // activateAlert
  // ---------------------------------------------------------------------------

  group('activateAlert', () {
    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[HAPPY PATH] - success',
      build: () {
        when(
          () => userProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));

        when(
          () => alertRepository.createAlert(
            ownerUid: any(named: 'ownerUid'),
            ownerUsername: any(named: 'ownerUsername'),
            alertType: any(named: 'alertType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            batteryLevel: any(named: 'batteryLevel'),
          ),
        ).thenAnswer((_) async => const Result.success(null));

        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => Result<Alert?>.success(_dummyAlert));

        when(
          () => userProfileRepository.getFcmTokensForUsers(any()),
        ).thenAnswer((_) async => const Result.success([]));

        return cubit;
      },
      act: (cubit) => cubit.activateAlert(FakeL10n()),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.buttonState,
          'state',
          PanicButtonState.active,
        ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[ERROR PATH] - profile fetch failure',
      build: () {
        when(
          () => userProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (cubit) => cubit.activateAlert(FakeL10n()),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.activateFailure,
          'failure',
          _dummyFailure,
        ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[ERROR PATH] - generic failure',
      build: () {
        when(
          () => userProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));

        when(
          () => alertRepository.createAlert(
            ownerUid: any(named: 'ownerUid'),
            ownerUsername: any(named: 'ownerUsername'),
            alertType: any(named: 'alertType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            batteryLevel: any(named: 'batteryLevel'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));

        return cubit;
      },
      act: (cubit) => cubit.activateAlert(FakeL10n()),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.activateFailure,
          'failure',
          _dummyFailure,
        ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[EDGE] - no trusted contacts',
      build: () {
        when(
          () => userProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));

        when(
          () => alertRepository.createAlert(
            ownerUid: any(named: 'ownerUid'),
            ownerUsername: any(named: 'ownerUsername'),
            alertType: any(named: 'alertType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            batteryLevel: any(named: 'batteryLevel'),
          ),
        ).thenAnswer(
          (_) async =>
              const Result.failure(AppFailure.business('no_trusted_contacts')),
        );

        return cubit;
      },
      act: (cubit) => cubit.activateAlert(FakeL10n()),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>()
            .having((s) => s.buttonState, 'state', PanicButtonState.disabled)
            .having(
              (s) => s.disabledReason,
              'reason',
              DisabledReason.noTrustedContacts,
            ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // deactivateAlert
  // ---------------------------------------------------------------------------

  group('deactivateAlert', () {
    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[HAPPY PATH] - success',
      build: () {
        when(
          () => alertRepository.deactivateAlert(
            ownerUid: any(named: 'ownerUid'),
            alertType: any(named: 'alertType'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));

        return cubit;
      },
      act: (cubit) => cubit.deactivateAlert(),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.buttonState,
          'state',
          PanicButtonState.normal,
        ),
      ],
    );

    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[ERROR PATH] - failure',
      build: () {
        when(
          () => alertRepository.deactivateAlert(
            ownerUid: any(named: 'ownerUid'),
            alertType: any(named: 'alertType'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));

        return cubit;
      },
      act: (cubit) => cubit.deactivateAlert(),
      expect: () => [
        isA<PanicButtonCubitState>(),
        isA<PanicButtonCubitState>().having(
          (s) => s.deactivateFailure,
          'failure',
          _dummyFailure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // requestLocationPermission
  // ---------------------------------------------------------------------------

  group('requestLocationPermission', () {
    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[ERROR PATH] - permission denied',
      setUp: () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(geolocatorChannel, (
              MethodCall call,
            ) async {
              switch (call.method) {
                case 'requestPermission':
                  return 0;
                case 'checkPermission':
                  return 0;
                default:
                  return null;
              }
            });
      },
      tearDown: () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(geolocatorChannel, (
              MethodCall call,
            ) async {
              switch (call.method) {
                case 'checkPermission':
                  return 2;
                case 'requestPermission':
                  return 3;
                case 'isLocationServiceEnabled':
                  return true;
                case 'openAppSettings':
                  return true;
                case 'getCurrentPosition':
                  return {
                    'latitude': 0.0,
                    'longitude': 0.0,
                    'timestamp': DateTime.now().toIso8601String(),
                    'accuracy': 1.0,
                    'altitude': 0.0,
                    'heading': 0.0,
                    'speed': 0.0,
                    'speed_accuracy': 0.0,
                  };
                default:
                  return null;
              }
            });
      },
      build: () => cubit,
      act: (cubit) => cubit.requestLocationPermission(),
      expect: () => [
        isA<PanicButtonCubitState>().having(
          (s) => s.permissionRequestDenied,
          'permissionRequestDenied',
          true,
        ),
        isA<PanicButtonCubitState>().having(
          (s) => s.isLoading,
          'loading',
          true,
        ),
        isA<PanicButtonCubitState>()
            .having((s) => s.buttonState, 'state', PanicButtonState.disabled)
            .having(
              (s) => s.disabledReason,
              'reason',
              DisabledReason.locationPermissionDenied,
            ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // openLocationSettings
  // ---------------------------------------------------------------------------

  group('openLocationSettings', () {
    blocTest<PanicButtonCubit, PanicButtonCubitState>(
      '[HAPPY PATH] - calls loadAlertState after settings',
      build: () {
        when(
          () => alertRepository.getActiveAlert(
            _uid,
            alertType: any(named: 'alertType'),
          ),
        ).thenAnswer((_) async => Result<Alert?>.success(_dummyAlert));
        return cubit;
      },
      act: (cubit) => cubit.openLocationSettings(),
      expect: () => [
        isA<PanicButtonCubitState>().having(
          (s) => s.isLoading,
          'loading',
          true,
        ),
        isA<PanicButtonCubitState>().having(
          (s) => s.buttonState,
          'state',
          PanicButtonState.active,
        ),
      ],
    );
  });
}

// MARK: - Fake L10n

class FakeL10n extends Fake implements AppLocalizations {
  @override
  String notificationAlertTitle(String name) => 'title';

  @override
  String notificationAlertBody(String name) => 'body';
}
