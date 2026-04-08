import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/alert_detail_cubit.dart';

// MARK: - DUMMY DATA & MOCKS

class MockAlertRepository extends Mock implements AlertRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

const _alertId = 'alert-abc';
const _ownerUid = 'uid-123';
const _ownerUsername = 'john_doe';
const _dummyFailure = AppFailure.unknown();

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
  late MockAlertRepository mockAlertRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late AlertDetailCubit cubit;

  setUp(() {
    mockAlertRepository = MockAlertRepository();
    mockUserProfileRepository = MockUserProfileRepository();
    cubit = AlertDetailCubit(
      alertId: _alertId,
      alertRepository: mockAlertRepository,
      userProfileRepository: mockUserProfileRepository,
    );
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // loadAlertDetail
  // ---------------------------------------------------------------------------

  group('AlertDetailCubit.loadAlertDetail', () {
    blocTest<AlertDetailCubit, AlertDetailState>(
      '[HAPPY PATH] - GIVEN the alert exists and the owner profile resolves, '
      'WHEN loadAlertDetail is called, '
      'THEN should emit [loading, loaded with alert and resolved display name]',
      build: () {
        when(
          () => mockAlertRepository.getAlertDetails(_alertId),
        ).thenAnswer((_) async => Result.success(_dummyAlert));
        when(
          () => mockUserProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertDetail(),
      expect: () => [
        const AlertDetailState(),
        isA<AlertDetailState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.alert, 'alert', _dummyAlert)
            .having((s) => s.displayName, 'displayName', 'John Doe'),
      ],
      verify: (_) {
        verify(() => mockAlertRepository.getAlertDetails(_alertId)).called(1);
        verify(() => mockUserProfileRepository.getProfile(_ownerUid)).called(1);
      },
    );

    blocTest<AlertDetailCubit, AlertDetailState>(
      '[HAPPY PATH] - GIVEN the alert exists but the owner profile fetch fails, '
      'WHEN loadAlertDetail is called, '
      'THEN should emit loaded state with ownerUsername as fallback display name',
      build: () {
        when(
          () => mockAlertRepository.getAlertDetails(_alertId),
        ).thenAnswer((_) async => Result.success(_dummyAlert));
        when(
          () => mockUserProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertDetail(),
      expect: () => [
        const AlertDetailState(),
        isA<AlertDetailState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.alert, 'alert', _dummyAlert)
            .having(
              (s) => s.displayName,
              'displayName falls back to ownerUsername',
              _ownerUsername,
            ),
      ],
    );

    blocTest<AlertDetailCubit, AlertDetailState>(
      '[ERROR PATH] - GIVEN the alert repository returns a failure, '
      'WHEN loadAlertDetail is called, '
      'THEN should emit [loading, failure] without calling the profile repository',
      build: () {
        when(
          () => mockAlertRepository.getAlertDetails(_alertId),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (cubit) => cubit.loadAlertDetail(),
      expect: () => [
        const AlertDetailState(),
        const AlertDetailState(isLoading: false, failure: _dummyFailure),
      ],
      verify: (_) {
        verifyNever(() => mockUserProfileRepository.getProfile(any()));
      },
    );
  });
}
