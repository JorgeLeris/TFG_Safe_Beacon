import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';

// MARK: - DUMMY DATA

class MockContactRequestRepository extends Mock
    implements ContactRequestRepository {}

class MockAlertRepository extends Mock implements AlertRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockGuardianSessionRepository extends Mock
    implements GuardianSessionRepository {}

const _uid = 'uid_test';
const _alertId = 'alert-abc';
const _ownerUid = 'uid-123';
const _ownerUsername = 'john_doe';
const _dummyFailure = AppFailure.unknown();

final _dummySession = GuardianSession(
  id: 'session-1',
  ownerUid: _ownerUid,
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

final _dummyAlert = Alert(
  id: _alertId,
  ownerUid: _ownerUid,
  ownerUsername: _ownerUsername,
  alertType: AlertType.panic,
  latitude: 41.6488,
  longitude: -0.8891,
  batteryLevel: 75,
  status: AlertStatus.active,
  trustedContactUids: const [],
  activatedAt: DateTime(2024),
);

const _dummyProfile = UserProfile(uid: _ownerUid, name: 'John', surname: 'Doe');

// MARK: - TEST CASES

void main() {
  late MockContactRequestRepository mockContactRequestRepository;
  late MockAlertRepository mockAlertRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late MockGuardianSessionRepository mockGuardianSessionRepository;
  late ControlCubit controlCubit;

  setUp(() {
    mockContactRequestRepository = MockContactRequestRepository();
    mockAlertRepository = MockAlertRepository();
    mockUserProfileRepository = MockUserProfileRepository();
    mockGuardianSessionRepository = MockGuardianSessionRepository();
    controlCubit = ControlCubit(
      uid: _uid,
      contactRequestRepository: mockContactRequestRepository,
      alertRepository: mockAlertRepository,
      userProfileRepository: mockUserProfileRepository,
      guardianSessionRepository: mockGuardianSessionRepository,
    );
  });

  tearDown(() {
    controlCubit.close();
  });

  group('ControlCubit.loadReceivedRequestsCount', () {
    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN the repository returns a count, WHEN loadReceivedRequestsCount is called, THEN should emit [isLoadingCount: true, isLoadingCount: false with count]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).thenAnswer((_) async => const Result.success(3));
        return controlCubit;
      },
      act: (cubit) => cubit.loadReceivedRequestsCount(),
      expect: () => [
        const ControlState(isLoadingCount: true),
        const ControlState(receivedRequestsCount: 3),
      ],
      verify: (_) {
        verify(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).called(1);
      },
    );

    blocTest<ControlCubit, ControlState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, WHEN loadReceivedRequestsCount is called, THEN should emit [isLoadingCount: true, isLoadingCount: false with countFailure]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return controlCubit;
      },
      act: (cubit) => cubit.loadReceivedRequestsCount(),
      expect: () => [
        const ControlState(isLoadingCount: true),
        const ControlState(countFailure: _dummyFailure),
      ],
      verify: (_) {
        verify(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // applyFiltersWithLoading
  // ---------------------------------------------------------------------------

  group('ControlCubit.applyFiltersWithLoading', () {
    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN initial state, '
      'WHEN applyFiltersWithLoading is called, '
      'THEN should emit [isApplyingFilters: true, isApplyingFilters: false]',
      build: () => controlCubit,
      act: (cubit) => cubit.applyFiltersWithLoading(),
      expect: () => [
        const ControlState(isApplyingFilters: true),
        const ControlState(),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadAlerts
  // ---------------------------------------------------------------------------

  group('ControlCubit.loadAlerts', () {
    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN the repository returns a non-empty list of alerts '
      'and profiles resolve correctly, '
      'WHEN loadAlerts is called, '
      'THEN should emit [loading, loaded with alerts and display names]',
      build: () {
        final alert = _dummyAlert;
        when(
          () => mockAlertRepository.getContactsAlerts(_uid),
        ).thenAnswer((_) async => Result.success([alert]));
        when(
          () => mockUserProfileRepository.getProfile(alert.ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return controlCubit;
      },
      act: (cubit) => cubit.loadAlerts(),
      expect: () => [
        const ControlState(isLoadingAlerts: true),
        isA<ControlState>()
            .having((s) => s.isLoadingAlerts, 'isLoadingAlerts', false)
            .having((s) => s.alerts, 'alerts', [_dummyAlert])
            .having(
              (s) => s.alertDisplayNames[_dummyAlert.ownerUid],
              'displayName resolved from profile',
              'John Doe',
            ),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN the repository returns an empty list, '
      'WHEN loadAlerts is called, '
      'THEN should emit [loading, loaded with empty alerts]',
      build: () {
        when(
          () => mockAlertRepository.getContactsAlerts(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return controlCubit;
      },
      act: (cubit) => cubit.loadAlerts(),
      expect: () => [
        const ControlState(isLoadingAlerts: true),
        const ControlState(),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN alert list loads but profile fetch fails, '
      'WHEN loadAlerts is called, '
      'THEN should emit loaded state using ownerUsername as fallback display name',
      build: () {
        final alert = _dummyAlert;
        when(
          () => mockAlertRepository.getContactsAlerts(_uid),
        ).thenAnswer((_) async => Result.success([alert]));
        when(
          () => mockUserProfileRepository.getProfile(alert.ownerUid),
        ).thenAnswer((_) async => const Result.failure(AppFailure.unknown()));
        return controlCubit;
      },
      act: (cubit) => cubit.loadAlerts(),
      expect: () => [
        const ControlState(isLoadingAlerts: true),
        isA<ControlState>().having(
          (s) => s.alertDisplayNames[_dummyAlert.ownerUid],
          'displayName falls back to ownerUsername',
          _dummyAlert.ownerUsername,
        ),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, '
      'WHEN loadAlerts is called, '
      'THEN should emit [loading, alertsFailure]',
      build: () {
        when(
          () => mockAlertRepository.getContactsAlerts(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return controlCubit;
      },
      act: (cubit) => cubit.loadAlerts(),
      expect: () => [
        const ControlState(isLoadingAlerts: true),
        const ControlState(alertsFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadFollowUps
  // ---------------------------------------------------------------------------

  group('ControlCubit.loadFollowUps', () {
    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN sessions exist and profiles resolve, '
      'WHEN loadFollowUps is called, '
      'THEN should emit [loading, loaded with sessions and display names]',
      build: () {
        when(
          () => mockGuardianSessionRepository.getContactsSessions(_uid),
        ).thenAnswer((_) async => Result.success([_dummySession]));
        when(
          () => mockUserProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return controlCubit;
      },
      act: (cubit) => cubit.loadFollowUps(),
      expect: () => [
        const ControlState(isLoadingFollowUps: true),
        isA<ControlState>()
            .having((s) => s.isLoadingFollowUps, 'isLoadingFollowUps', false)
            .having((s) => s.followUps, 'followUps', [_dummySession])
            .having(
              (s) => s.followUpDisplayNames[_ownerUid],
              'displayName resolved from profile',
              'John Doe',
            ),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN no sessions exist, '
      'WHEN loadFollowUps is called, '
      'THEN should emit [loading, empty loaded state]',
      build: () {
        when(
          () => mockGuardianSessionRepository.getContactsSessions(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return controlCubit;
      },
      act: (cubit) => cubit.loadFollowUps(),
      expect: () => [
        const ControlState(isLoadingFollowUps: true),
        const ControlState(),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN sessions exist but profile fetch fails, '
      'WHEN loadFollowUps is called, '
      'THEN should emit loaded state with empty display name for that uid',
      build: () {
        when(
          () => mockGuardianSessionRepository.getContactsSessions(_uid),
        ).thenAnswer((_) async => Result.success([_dummySession]));
        when(
          () => mockUserProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.failure(AppFailure.unknown()));
        return controlCubit;
      },
      act: (cubit) => cubit.loadFollowUps(),
      expect: () => [
        const ControlState(isLoadingFollowUps: true),
        isA<ControlState>()
            .having((s) => s.isLoadingFollowUps, 'isLoadingFollowUps', false)
            .having((s) => s.followUps, 'followUps', [_dummySession])
            .having(
              (s) => s.followUpDisplayNames.containsKey(_ownerUid),
              'no display name entry for failed profile',
              false,
            ),
      ],
    );

    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN two sessions with the same owner, '
      'WHEN loadFollowUps is called, '
      'THEN profile should only be fetched once',
      build: () {
        final session2 = GuardianSession(
          id: 'session-2',
          ownerUid: _ownerUid,
          trustedContactUids: const [],
          status: GuardianSessionStatus.active,
          secondaryStatuses: const [],
          originLocation: const GuardianCoordinate(
            latitude: 41.0,
            longitude: -1.0,
          ),
          currentLocation: const GuardianCoordinate(
            latitude: 41.0,
            longitude: -1.0,
          ),
          estimatedDuration: const Duration(minutes: 20),
          activatedAt: DateTime(2024),
        );
        when(
          () => mockGuardianSessionRepository.getContactsSessions(_uid),
        ).thenAnswer((_) async => Result.success([_dummySession, session2]));
        when(
          () => mockUserProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return controlCubit;
      },
      act: (cubit) => cubit.loadFollowUps(),
      verify: (_) {
        verify(() => mockUserProfileRepository.getProfile(_ownerUid)).called(1);
      },
    );

    blocTest<ControlCubit, ControlState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, '
      'WHEN loadFollowUps is called, '
      'THEN should emit [loading, followUpsFailure]',
      build: () {
        when(
          () => mockGuardianSessionRepository.getContactsSessions(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return controlCubit;
      },
      act: (cubit) => cubit.loadFollowUps(),
      expect: () => [
        const ControlState(isLoadingFollowUps: true),
        const ControlState(followUpsFailure: _dummyFailure),
      ],
    );
  });
}
