import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/edit_profile_cubit.dart';

// MARK: - DUMMY DATA

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

const dummyUid = 'uid-123';

// MARK: - TEST CASES

void main() {
  late MockUserProfileRepository mockRepository;
  late EditProfileCubit cubit;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    cubit = EditProfileCubit(
      uid: dummyUid,
      userProfileRepository: mockRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(const UserProfile(uid: dummyUid, name: 'fallback'));
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // saveProfile
  // ---------------------------------------------------------------------------

  group('EditProfileCubit.saveProfile', () {
    blocTest<EditProfileCubit, EditProfileState>(
      '[HAPPY PATH] - GIVEN a successful repository update, '
      'WHEN saveProfile is called with all fields, '
      'THEN should emit [loading, saved]',
      build: () {
        when(
          () => mockRepository.updateProfile(any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: 'Doe',
        birthDate: '1990-01-15',
        gender: 'male',
        description: 'A description',
        profilePhoto: 'https://example.com/photo.jpg',
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(isSaved: true),
      ],
      verify: (_) {
        verify(() => mockRepository.updateProfile(any())).called(1);
      },
    );

    blocTest<EditProfileCubit, EditProfileState>(
      '[HAPPY PATH] - GIVEN a successful update with only the required name field, '
      'WHEN saveProfile is called with all optionals as null, '
      'THEN should emit [loading, saved]',
      build: () {
        when(
          () => mockRepository.updateProfile(any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: null,
        birthDate: null,
        gender: null,
        description: null,
        profilePhoto: null,
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(isSaved: true),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      '[ERROR PATH] - GIVEN a forbidden failure from repository, '
      'WHEN saveProfile is called, '
      'THEN should emit [loading, failure(forbidden)]',
      build: () {
        when(() => mockRepository.updateProfile(any())).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.forbidden()),
        );
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: null,
        birthDate: null,
        gender: null,
        description: null,
        profilePhoto: null,
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(failure: AppFailure.forbidden()),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      '[ERROR PATH] - GIVEN a network failure from repository, '
      'WHEN saveProfile is called, '
      'THEN should emit [loading, failure(network)]',
      build: () {
        when(() => mockRepository.updateProfile(any())).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.network()),
        );
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: null,
        birthDate: null,
        gender: null,
        description: null,
        profilePhoto: null,
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(failure: AppFailure.network()),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      '[ERROR PATH] - GIVEN a notFound failure from repository, '
      'WHEN saveProfile is called, '
      'THEN should emit [loading, failure(notFound)]',
      build: () {
        when(() => mockRepository.updateProfile(any())).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.notFound()),
        );
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: null,
        birthDate: null,
        gender: null,
        description: null,
        profilePhoto: null,
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(failure: AppFailure.notFound()),
      ],
    );

    blocTest<EditProfileCubit, EditProfileState>(
      '[ERROR PATH] - GIVEN an unknown failure from repository, '
      'WHEN saveProfile is called, '
      'THEN should emit [loading, failure(unknown)]',
      build: () {
        when(() => mockRepository.updateProfile(any())).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.unknown()),
        );
        return cubit;
      },
      act: (cubit) => cubit.saveProfile(
        name: 'John',
        surname: null,
        birthDate: null,
        gender: null,
        description: null,
        profilePhoto: null,
      ),
      expect: () => [
        const EditProfileState(isLoading: true),
        const EditProfileState(failure: AppFailure.unknown()),
      ],
    );
  });
}
