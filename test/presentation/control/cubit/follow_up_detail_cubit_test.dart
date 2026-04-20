import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/follow_up_detail_cubit.dart';

// MARK: - DUMMY DATA

class MockGuardianSessionRepository extends Mock
    implements GuardianSessionRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

const _sessionId = 'session-abc';
const _ownerUid = 'uid-123';
const _dummyFailure = AppFailure.unknown();

final _dummySession = GuardianSession(
  id: _sessionId,
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

const _dummyProfileFull = UserProfile(
  uid: _ownerUid,
  name: 'John',
  surname: 'Doe',
  profilePhoto: 'https://example.com/photo.jpg',
);

const _dummyProfileNoSurname = UserProfile(uid: _ownerUid, name: 'John');

// MARK: - TEST CASES

void main() {
  late MockGuardianSessionRepository mockSessionRepository;
  late MockUserProfileRepository mockProfileRepository;
  late FollowUpDetailCubit cubit;

  setUp(() {
    mockSessionRepository = MockGuardianSessionRepository();
    mockProfileRepository = MockUserProfileRepository();
    cubit = FollowUpDetailCubit(
      sessionId: _sessionId,
      guardianSessionRepository: mockSessionRepository,
      userProfileRepository: mockProfileRepository,
    );
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // loadFollowUpDetail
  // ---------------------------------------------------------------------------

  group('FollowUpDetailCubit.loadFollowUpDetail', () {
    blocTest<FollowUpDetailCubit, FollowUpDetailState>(
      '[HAPPY PATH] - GIVEN the session exists and profile resolves, '
      'WHEN loadFollowUpDetail is called, '
      'THEN should emit [loading, loaded with session and display name]',
      build: () {
        when(
          () => mockSessionRepository.getSessionDetails(_sessionId),
        ).thenAnswer((_) async => Result.success(_dummySession));
        when(
          () => mockProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfileFull));
        return cubit;
      },
      act: (c) => c.loadFollowUpDetail(),
      expect: () => [
        const FollowUpDetailState(),
        FollowUpDetailState(
          isLoading: false,
          session: _dummySession,
          displayName: 'John Doe',
          profilePhoto: 'https://example.com/photo.jpg',
        ),
      ],
    );

    blocTest<FollowUpDetailCubit, FollowUpDetailState>(
      '[HAPPY PATH] - GIVEN the profile has no surname, '
      'WHEN loadFollowUpDetail is called, '
      'THEN display name should contain only the first name',
      build: () {
        when(
          () => mockSessionRepository.getSessionDetails(_sessionId),
        ).thenAnswer((_) async => Result.success(_dummySession));
        when(
          () => mockProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfileNoSurname));
        return cubit;
      },
      act: (c) => c.loadFollowUpDetail(),
      expect: () => [
        const FollowUpDetailState(),
        FollowUpDetailState(
          isLoading: false,
          session: _dummySession,
          displayName: 'John',
        ),
      ],
    );

    blocTest<FollowUpDetailCubit, FollowUpDetailState>(
      '[HAPPY PATH] - GIVEN the profile fetch fails, '
      'WHEN loadFollowUpDetail is called, '
      'THEN should fall back to ownerUid as display name',
      build: () {
        when(
          () => mockSessionRepository.getSessionDetails(_sessionId),
        ).thenAnswer((_) async => Result.success(_dummySession));
        when(
          () => mockProfileRepository.getProfile(_ownerUid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (c) => c.loadFollowUpDetail(),
      expect: () => [
        const FollowUpDetailState(),
        FollowUpDetailState(
          isLoading: false,
          session: _dummySession,
          displayName: _ownerUid,
        ),
      ],
    );

    blocTest<FollowUpDetailCubit, FollowUpDetailState>(
      '[ERROR PATH] - GIVEN the session fetch fails, '
      'WHEN loadFollowUpDetail is called, '
      'THEN should emit [loading, failure state]',
      build: () {
        when(
          () => mockSessionRepository.getSessionDetails(_sessionId),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return cubit;
      },
      act: (c) => c.loadFollowUpDetail(),
      expect: () => [
        const FollowUpDetailState(),
        const FollowUpDetailState(isLoading: false, failure: _dummyFailure),
      ],
      verify: (_) {
        verifyNever(() => mockProfileRepository.getProfile(any()));
      },
    );
  });
}
