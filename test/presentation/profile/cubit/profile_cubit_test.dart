import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/profile_cubit.dart';

// MARK: - DUMMY DATA

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

const dummyUid = 'uid-123';

const dummyProfile = UserProfile(
  uid: dummyUid,
  name: 'John',
  surname: 'Doe',
  gender: 'male',
  birthDate: '1990-01-15',
  description: 'A description',
  profilePhoto: 'https://example.com/photo.jpg',
);

// MARK: - TEST CASES

void main() {
  late MockUserProfileRepository mockRepository;
  late ProfileCubit cubit;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    cubit = ProfileCubit(uid: dummyUid, userProfileRepository: mockRepository);
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // loadProfile
  // ---------------------------------------------------------------------------

  group('ProfileCubit.loadProfile', () {
    blocTest<ProfileCubit, ProfileState>(
      '[HAPPY PATH] - GIVEN an existing profile in repository, '
      'WHEN loadProfile is called, '
      'THEN should emit [loading, profile]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async => const Result<UserProfile>.success(dummyProfile),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(userProfile: dummyProfile),
      ],
      verify: (_) {
        verify(() => mockRepository.getProfile(dummyUid)).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      '[ERROR PATH] - GIVEN a notFound failure from repository, '
      'WHEN loadProfile is called, '
      'THEN should emit [loading, failure(notFound)]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async => const Result<UserProfile>.failure(AppFailure.notFound()),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(failure: AppFailure.notFound()),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[ERROR PATH] - GIVEN a forbidden failure from repository, '
      'WHEN loadProfile is called, '
      'THEN should emit [loading, failure(forbidden)]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async =>
              const Result<UserProfile>.failure(AppFailure.forbidden()),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(failure: AppFailure.forbidden()),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[ERROR PATH] - GIVEN a network failure from repository, '
      'WHEN loadProfile is called, '
      'THEN should emit [loading, failure(network)]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async => const Result<UserProfile>.failure(AppFailure.network()),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(failure: AppFailure.network()),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[ERROR PATH] - GIVEN an unknown failure from repository, '
      'WHEN loadProfile is called, '
      'THEN should emit [loading, failure(unknown)]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async => const Result<UserProfile>.failure(AppFailure.unknown()),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(failure: AppFailure.unknown()),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[STATE UPDATE] - GIVEN a previous failure in state, '
      'WHEN loadProfile is called successfully, '
      'THEN should clear failure and emit [loading, profile]',
      build: () {
        when(() => mockRepository.getProfile(dummyUid)).thenAnswer(
          (_) async => const Result<UserProfile>.success(dummyProfile),
        );
        return cubit;
      },
      seed: () => const ProfileState(failure: AppFailure.unknown()),
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(isLoading: true),
        const ProfileState(userProfile: dummyProfile),
      ],
    );
  });
}
