import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/cubits/guardian_mode_cubit.dart';

// MARK: - DUMMY DATA

class MockContactRepository extends Mock implements ContactRepository {}

class MockGuardianSessionRepository extends Mock
    implements GuardianSessionRepository {}

class MockAlertRepository extends Mock implements AlertRepository {}

const _geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

// Geolocator LocationPermission enum indices:
// 0 = denied, 1 = deniedForever, 2 = whileInUse (granted), 3 = always

void _setGeolocatorChannel({
  int checkPermission = 2,
  int requestPermission = 2,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_geolocatorChannel, (call) async {
        switch (call.method) {
          case 'checkPermission':
            return checkPermission;
          case 'requestPermission':
            return requestPermission;
          case 'openAppSettings':
            return true;
          default:
            return null;
        }
      });
}

const _uid = 'uid-123';
const _sessionId = 'session-abc';
const _dummyFailure = AppFailure.unknown();

final _dummySession = GuardianSession(
  id: _sessionId,
  ownerUid: _uid,
  trustedContactUids: const [],
  status: GuardianSessionStatus.active,
  secondaryStatuses: const [],
  originLocation: const GuardianCoordinate(
    latitude: 41.6488,
    longitude: -0.8891,
  ),
  currentLocation: const GuardianCoordinate(
    latitude: 41.6488,
    longitude: -0.8891,
  ),
  estimatedDuration: const Duration(minutes: 30),
  activatedAt: DateTime(2024),
);

final _dummySessionWithAlertStatuses = GuardianSession(
  id: _sessionId,
  ownerUid: _uid,
  trustedContactUids: const [],
  status: GuardianSessionStatus.active,
  secondaryStatuses: const [
    GuardianSessionSecondaryStatus.routeDeviation,
    GuardianSessionSecondaryStatus.estimatedTimeExceeded,
  ],
  originLocation: const GuardianCoordinate(
    latitude: 41.6488,
    longitude: -0.8891,
  ),
  currentLocation: const GuardianCoordinate(
    latitude: 41.6488,
    longitude: -0.8891,
  ),
  estimatedDuration: const Duration(minutes: 30),
  activatedAt: DateTime(2024),
);

final _dummyContact = Contact(
  id: 'contact-1',
  protectedPersonUid: _uid,
  trustedContactUid: 'contact-uid',
  protectedPersonUsername: 'me',
  trustedContactUsername: 'them',
  createdAt: DateTime(2024),
);

// MARK: - TEST CASES

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockContactRepository mockContactRepository;
  late MockGuardianSessionRepository mockSessionRepository;
  late MockAlertRepository mockAlertRepository;
  late GuardianModeCubit cubit;

  setUp(() {
    mockContactRepository = MockContactRepository();
    mockSessionRepository = MockGuardianSessionRepository();
    mockAlertRepository = MockAlertRepository();
    cubit = GuardianModeCubit(
      uid: _uid,
      contactRepository: mockContactRepository,
      guardianSessionRepository: mockSessionRepository,
      alertRepository: mockAlertRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 30));
    registerFallbackValue(const GuardianCoordinate(latitude: 0, longitude: 0));
    registerFallbackValue(
      GuardianSessionSecondaryStatus.completedByCancellation,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, null);
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // loadSessionState
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.loadSessionState', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN an active session exists, '
      'WHEN loadSessionState is called, '
      'THEN should emit [loading, loaded with session]',
      build: () {
        when(
          () => mockSessionRepository.getActiveSession(_uid),
        ).thenAnswer((_) async => Result.success(_dummySession));
        return cubit;
      },
      act: (c) => c.loadSessionState(),
      expect: () => [
        const GuardianModeCubitState(),
        GuardianModeCubitState(
          isLoadingSession: false,
          activeSession: _dummySession,
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN a session with alert secondary statuses exists, '
      'WHEN loadSessionState is called, '
      'THEN should restore alertTriggerStatuses from the session',
      build: () {
        when(() => mockSessionRepository.getActiveSession(_uid)).thenAnswer(
          (_) async => Result.success(_dummySessionWithAlertStatuses),
        );
        return cubit;
      },
      act: (c) => c.loadSessionState(),
      expect: () => [
        const GuardianModeCubitState(),
        GuardianModeCubitState(
          isLoadingSession: false,
          activeSession: _dummySessionWithAlertStatuses,
          alertTriggerStatuses: const [
            GuardianSessionSecondaryStatus.routeDeviation,
            GuardianSessionSecondaryStatus.estimatedTimeExceeded,
          ],
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN no active session exists, '
      'WHEN loadSessionState is called, '
      'THEN should emit [loading, loaded with null session]',
      build: () {
        when(
          () => mockSessionRepository.getActiveSession(_uid),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (c) => c.loadSessionState(),
      expect: () => [
        const GuardianModeCubitState(),
        const GuardianModeCubitState(isLoadingSession: false),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, '
      'WHEN loadSessionState is called, '
      'THEN should emit [loading, failure state]',
      build: () {
        when(
          () => mockSessionRepository.getActiveSession(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (c) => c.loadSessionState(),
      expect: () => [
        const GuardianModeCubitState(),
        const GuardianModeCubitState(
          isLoadingSession: false,
          failure: _dummyFailure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // activateSession
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.activateSession', () {
    const initialLocation = GuardianCoordinate(
      latitude: 41.6488,
      longitude: -0.8891,
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN a pending duration and valid repositories, '
      'WHEN activateSession is called, '
      'THEN should emit [activating, activated with session]',
      build: () {
        when(
          () => mockSessionRepository.createSession(
            ownerUid: any(named: 'ownerUid'),
            estimatedDuration: any(named: 'estimatedDuration'),
            initialLocation: any(named: 'initialLocation'),
            destination: any(named: 'destination'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockSessionRepository.getActiveSession(_uid),
        ).thenAnswer((_) async => Result.success(_dummySession));
        return cubit;
      },
      seed: () =>
          const GuardianModeCubitState(pendingDuration: Duration(minutes: 30)),
      act: (c) => c.activateSession(initialLocation: initialLocation),
      expect: () => [
        const GuardianModeCubitState(
          isActivating: true,
          pendingDuration: Duration(minutes: 30),
        ),
        GuardianModeCubitState(
          activeSession: _dummySession,
          pendingDuration: const Duration(minutes: 30),
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN createSession returns a failure, '
      'WHEN activateSession is called, '
      'THEN should emit [activating, activateFailure]',
      build: () {
        when(
          () => mockSessionRepository.createSession(
            ownerUid: any(named: 'ownerUid'),
            estimatedDuration: any(named: 'estimatedDuration'),
            initialLocation: any(named: 'initialLocation'),
            destination: any(named: 'destination'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      seed: () =>
          const GuardianModeCubitState(pendingDuration: Duration(minutes: 30)),
      act: (c) => c.activateSession(initialLocation: initialLocation),
      expect: () => [
        const GuardianModeCubitState(
          isActivating: true,
          pendingDuration: Duration(minutes: 30),
        ),
        const GuardianModeCubitState(
          activateFailure: _dummyFailure,
          pendingDuration: Duration(minutes: 30),
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[EDGE CASE] - GIVEN no pending duration, '
      'WHEN activateSession is called, '
      'THEN should not emit any state',
      build: () => cubit,
      act: (c) => c.activateSession(initialLocation: initialLocation),
      expect: () => [],
    );
  });

  // ---------------------------------------------------------------------------
  // completeSession
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.completeSession', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN an active session and successful repository, '
      'WHEN completeSession is called, '
      'THEN should emit [completing, cleared session state]',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockSessionRepository.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      seed: () => GuardianModeCubitState(activeSession: _dummySession),
      act: (c) => c.completeSession(
        completionStatus:
            GuardianSessionSecondaryStatus.completedByCancellation,
      ),
      expect: () => [
        GuardianModeCubitState(
          isCompleting: true,
          activeSession: _dummySession,
        ),
        const GuardianModeCubitState(),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, '
      'WHEN completeSession is called, '
      'THEN should emit [completing, completeFailure]',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockSessionRepository.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      seed: () => GuardianModeCubitState(activeSession: _dummySession),
      act: (c) => c.completeSession(
        completionStatus:
            GuardianSessionSecondaryStatus.completedByCancellation,
      ),
      expect: () => [
        GuardianModeCubitState(
          isCompleting: true,
          activeSession: _dummySession,
        ),
        GuardianModeCubitState(
          activeSession: _dummySession,
          completeFailure: _dummyFailure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // Pending form state updates
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit - pending form state', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN updatePendingDestination is called, '
      'THEN should update pendingDestination in state',
      build: () => cubit,
      act: (c) => c.updatePendingDestination(
        const GuardianCoordinate(latitude: 41.7, longitude: -0.85),
      ),
      expect: () => [
        const GuardianModeCubitState(
          pendingDestination: GuardianCoordinate(
            latitude: 41.7,
            longitude: -0.85,
          ),
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN updatePendingDuration is called, '
      'THEN should update pendingDuration in state',
      build: () => cubit,
      act: (c) => c.updatePendingDuration(const Duration(minutes: 45)),
      expect: () => [
        const GuardianModeCubitState(pendingDuration: Duration(minutes: 45)),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN updatePendingDescription is called, '
      'THEN should update pendingDescription in state',
      build: () => cubit,
      act: (c) => c.updatePendingDescription('Going to the gym'),
      expect: () => [
        const GuardianModeCubitState(pendingDescription: 'Going to the gym'),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // Consume / reset actions
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit - consume actions', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[RESET ACTION] - WHEN consumeActivateFailure is called, '
      'THEN should clear activateFailure from state',
      build: () => cubit,
      seed: () => const GuardianModeCubitState(activateFailure: _dummyFailure),
      act: (c) => c.consumeActivateFailure(),
      expect: () => [const GuardianModeCubitState()],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[RESET ACTION] - WHEN consumeCompleteFailure is called, '
      'THEN should clear completeFailure from state',
      build: () => cubit,
      seed: () => const GuardianModeCubitState(completeFailure: _dummyFailure),
      act: (c) => c.consumeCompleteFailure(),
      expect: () => [const GuardianModeCubitState()],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[RESET ACTION] - WHEN consumeNavigation is called, '
      'THEN should set canNavigate to false',
      build: () => cubit,
      seed: () => const GuardianModeCubitState(canNavigate: true),
      act: (c) => c.consumeNavigation(),
      expect: () => [const GuardianModeCubitState()],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[RESET ACTION] - WHEN consumeBlockedReason is called, '
      'THEN should clear blockedReason from state',
      build: () => cubit,
      seed: () => const GuardianModeCubitState(
        blockedReason: GuardianModeBlockedReason.noTrustedContacts,
      ),
      act: (c) => c.consumeBlockedReason(),
      expect: () => [const GuardianModeCubitState()],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[RESET ACTION] - WHEN consumePermissionGranted is called, '
      'THEN should set permissionJustGranted to false',
      build: () => cubit,
      seed: () => const GuardianModeCubitState(permissionJustGranted: true),
      act: (c) => c.consumePermissionGranted(),
      expect: () => [const GuardianModeCubitState()],
    );
  });

  // ---------------------------------------------------------------------------
  // activateSession – with description (covers description != null branch)
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.activateSession – with description', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN a pending description is set, '
      'WHEN activateSession is called, '
      'THEN should pass the description to createSession',
      build: () {
        when(
          () => mockSessionRepository.createSession(
            ownerUid: any(named: 'ownerUid'),
            estimatedDuration: any(named: 'estimatedDuration'),
            initialLocation: any(named: 'initialLocation'),
            destination: any(named: 'destination'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockSessionRepository.getActiveSession(_uid),
        ).thenAnswer((_) async => Result.success(_dummySession));
        return cubit;
      },
      seed: () => const GuardianModeCubitState(
        pendingDuration: Duration(minutes: 30),
        pendingDescription: 'Going to the gym',
      ),
      act: (c) => c.activateSession(
        initialLocation: const GuardianCoordinate(
          latitude: 41.6488,
          longitude: -0.8891,
        ),
      ),
      verify: (_) {
        verify(
          () => mockSessionRepository.createSession(
            ownerUid: _uid,
            estimatedDuration: any(named: 'estimatedDuration'),
            initialLocation: any(named: 'initialLocation'),
            destination: any(named: 'destination'),
            description: 'Going to the gym',
          ),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // completeSession – no active session (sessionId null)
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.completeSession – edge cases', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[EDGE CASE] - GIVEN no active session, '
      'WHEN completeSession is called, '
      'THEN should skip deactivateAlert and still complete',
      build: () {
        when(
          () => mockSessionRepository.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (c) => c.completeSession(
        completionStatus:
            GuardianSessionSecondaryStatus.completedByCancellation,
      ),
      expect: () => [
        const GuardianModeCubitState(isCompleting: true),
        const GuardianModeCubitState(),
      ],
      verify: (_) {
        verifyNever(
          () => mockAlertRepository.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
          ),
        );
      },
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[EDGE CASE] - GIVEN deactivateAlert returns a failure, '
      'WHEN completeSession is called, '
      'THEN failure is silently ignored and session completes normally',
      build: () {
        when(
          () => mockAlertRepository.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        when(
          () => mockSessionRepository.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      seed: () => GuardianModeCubitState(activeSession: _dummySession),
      act: (c) => c.completeSession(
        completionStatus:
            GuardianSessionSecondaryStatus.completedByCancellation,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        GuardianModeCubitState(
          isCompleting: true,
          activeSession: _dummySession,
        ),
        const GuardianModeCubitState(),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // startChecks / stopChecks / updateCheckRoutePoints
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit - check service controls', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[EDGE CASE] - GIVEN no active session, '
      'WHEN startChecks is called, '
      'THEN should not emit any state (early return)',
      build: () => cubit,
      act: (c) => c.startChecks(routePoints: const [], locale: 'es'),
      expect: () => [],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN stopChecks is called, '
      'THEN should not emit any state',
      build: () => cubit,
      act: (c) => c.stopChecks(),
      expect: () => [],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN updateCheckRoutePoints is called, '
      'THEN should not emit any state',
      build: () => cubit,
      act: (c) => c.updateCheckRoutePoints([const LatLng(41.6, -0.8)]),
      expect: () => [],
    );
  });

  // ---------------------------------------------------------------------------
  // requestNavigate
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.requestNavigate', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN permission granted and has contacts, '
      'WHEN requestNavigate is called, '
      'THEN should emit [checking, canNavigate: true]',
      build: () {
        _setGeolocatorChannel();
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (c) => c.requestNavigate(),
      expect: () => [
        const GuardianModeCubitState(isChecking: true),
        const GuardianModeCubitState(canNavigate: true),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN location permission is denied, '
      'WHEN requestNavigate is called, '
      'THEN should emit [checking, blocked with locationPermissionDenied]',
      build: () {
        _setGeolocatorChannel(checkPermission: 0);
        return cubit;
      },
      act: (c) => c.requestNavigate(),
      expect: () => [
        const GuardianModeCubitState(isChecking: true),
        const GuardianModeCubitState(
          blockedReason: GuardianModeBlockedReason.locationPermissionDenied,
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN location permission is permanently denied, '
      'WHEN requestNavigate is called, '
      'THEN should emit [checking, blocked with locationPermissionDeniedForever]',
      build: () {
        _setGeolocatorChannel(checkPermission: 1);
        return cubit;
      },
      act: (c) => c.requestNavigate(),
      expect: () => [
        const GuardianModeCubitState(isChecking: true),
        const GuardianModeCubitState(
          blockedReason:
              GuardianModeBlockedReason.locationPermissionDeniedForever,
        ),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN permission granted but no trusted contacts, '
      'WHEN requestNavigate is called, '
      'THEN should emit [checking, blocked with noTrustedContacts]',
      build: () {
        _setGeolocatorChannel();
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return cubit;
      },
      act: (c) => c.requestNavigate(),
      expect: () => [
        const GuardianModeCubitState(isChecking: true),
        const GuardianModeCubitState(
          blockedReason: GuardianModeBlockedReason.noTrustedContacts,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // requestLocationPermission
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.requestLocationPermission', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[ERROR PATH] - GIVEN the user denies the permission request, '
      'WHEN requestLocationPermission is called, '
      'THEN should emit showPermissionDeniedDialog: true',
      build: () {
        _setGeolocatorChannel(requestPermission: 0);
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        const GuardianModeCubitState(),
        const GuardianModeCubitState(showPermissionDeniedDialog: true),
      ],
    );

    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[HAPPY PATH] - GIVEN the user grants the permission, '
      'WHEN requestLocationPermission is called, '
      'THEN should emit permissionJustGranted: true then proceed to requestNavigate',
      build: () {
        _setGeolocatorChannel();
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        return cubit;
      },
      act: (c) => c.requestLocationPermission(),
      expect: () => [
        const GuardianModeCubitState(),
        const GuardianModeCubitState(permissionJustGranted: true),
        const GuardianModeCubitState(
          permissionJustGranted: true,
          isChecking: true,
        ),
        const GuardianModeCubitState(
          permissionJustGranted: true,
          canNavigate: true,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // openLocationSettings
  // ---------------------------------------------------------------------------

  group('GuardianModeCubit.openLocationSettings', () {
    blocTest<GuardianModeCubit, GuardianModeCubitState>(
      '[STATE UPDATE] - WHEN openLocationSettings is called, '
      'THEN should reset state to initial',
      build: () {
        _setGeolocatorChannel();
        return cubit;
      },
      seed: () => const GuardianModeCubitState(
        blockedReason:
            GuardianModeBlockedReason.locationPermissionDeniedForever,
      ),
      act: (c) => c.openLocationSettings(),
      expect: () => [const GuardianModeCubitState()],
    );
  });
}
