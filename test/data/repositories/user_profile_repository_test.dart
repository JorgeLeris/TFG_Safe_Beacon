import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/profile/dto/user_profile_dto.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';

// MARK: - DUMMY DATA & MOCKS

class MockUserProfileApi extends Mock implements UserProfileApi {}

class FakeUserProfileDto extends Fake implements UserProfileDto {}

const dummyEmail = 'john.doe@example.com';

// Dummy domain entity.
const dummyProfile = UserProfile(
  uid: 'uid-123',
  name: 'John',
  surname: 'Doe',
  gender: 'male',
  birthDate: '1990-01-15',
  description: 'A test user',
  profilePhoto: 'https://example.com/photo.jpg',
  username: 'john_doe',
);

// Dummy DTO returned by the API.
final dummyProfileDto = UserProfileDto(
  name: dummyProfile.name,
  surname: dummyProfile.surname,
  gender: dummyProfile.gender,
  birthDate: dummyProfile.birthDate,
  description: dummyProfile.description,
  profilePhoto: dummyProfile.profilePhoto,
  username: dummyProfile.username ?? '',
  createdAt: DateTime(2024),
);

/// Creates a [FirebaseException] with the given [code].
FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockUserProfileApi mockApi;
  late UserProfileRepositoryImpl repository;

  setUp(() {
    mockApi = MockUserProfileApi();
    repository = UserProfileRepositoryImpl(api: mockApi);
    registerFallbackValue(FakeUserProfileDto());
  });

  // ---------------------------------------------------------------------------
  // createProfile
  // ---------------------------------------------------------------------------

  group('UserProfileRepositoryImpl.createProfile', () {
    test(
      '[HAPPY PATH] - GIVEN a valid UserProfile and email with no username collision, '
      'WHEN createProfile is called, '
      'THEN should call usernameExists once, createProfileWithUsername once, '
      'and return Result.success with null',
      () async {
        // Arrange.
        when(
          () => mockApi.usernameExists(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockApi.createProfileWithUsername(
            dummyProfile.uid,
            any<UserProfileDto>(),
            any(),
          ),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.createProfile(dummyProfile, dummyEmail);

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(() => mockApi.usernameExists(any())).called(1);
        verify(
          () => mockApi.createProfileWithUsername(
            dummyProfile.uid,
            any<UserProfileDto>(),
            any(),
          ),
        ).called(1);
      },
    );

    test(
      '[HAPPY PATH] - GIVEN a base username already taken but suffix is free, '
      'WHEN createProfile is called, '
      'THEN should call usernameExists twice and return Result.success',
      () async {
        // Arrange.
        var callCount = 0;
        when(() => mockApi.usernameExists(any())).thenAnswer((_) async {
          callCount++;
          return callCount == 1;
        });
        when(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.createProfile(dummyProfile, dummyEmail);

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(() => mockApi.usernameExists(any())).called(2);
        verify(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).called(1);
      },
    );

    test(
      '[HAPPY PATH] - GIVEN an email with special characters and accents, '
      'WHEN createProfile is called, '
      'THEN should sanitize the username and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.usernameExists(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.createProfile(
          dummyProfile,
          'Juan.García+tag@gmail.com',
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        final captured = verify(
          () => mockApi.createProfileWithUsername(any(), any(), captureAny()),
        ).captured;
        final username = captured.first as String;
        expect(username, matches(RegExp(r'^[a-z0-9_]+$')));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a username_taken race condition on the transaction, '
      'WHEN createProfile is called, '
      'THEN should return Result.failure with AppFailure.unknown() '
      'because there is no retry loop',
      () async {
        // Arrange.
        when(
          () => mockApi.usernameExists(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).thenThrow(Exception('username_taken'));

        // Act.
        final result = await repository.createProfile(dummyProfile, dummyEmail);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
        // Verify it only attempted once (no retry).
        verify(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN createProfile is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.usernameExists(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.createProfile(dummyProfile, dummyEmail);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN createProfile is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.usernameExists(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockApi.createProfileWithUsername(any(), any(), any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.createProfile(dummyProfile, dummyEmail);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getProfile
  // ---------------------------------------------------------------------------

  group('UserProfileRepositoryImpl.getProfile', () {
    test('[HAPPY PATH] - GIVEN an existing user UID, '
        'WHEN getProfile is called, '
        'THEN should return Result.success with the mapped UserProfile '
        'including username', () async {
      // Arrange.
      when(
        () => mockApi.getProfile(dummyProfile.uid),
      ).thenAnswer((_) async => dummyProfileDto);

      // Act.
      final result = await repository.getProfile(dummyProfile.uid);

      // Assert.
      expect(result.isSuccess, isTrue);
      final profile = result.valueOrNull!;
      expect(profile.uid, equals(dummyProfile.uid));
      expect(profile.name, equals(dummyProfile.name));
      expect(profile.surname, equals(dummyProfile.surname));
      expect(profile.gender, equals(dummyProfile.gender));
      expect(profile.birthDate, equals(dummyProfile.birthDate));
      expect(profile.description, equals(dummyProfile.description));
      expect(profile.profilePhoto, equals(dummyProfile.profilePhoto));
      expect(profile.username, equals(dummyProfile.username));
      verify(() => mockApi.getProfile(dummyProfile.uid)).called(1);
    });

    test(
      '[ERROR PATH] - GIVEN the profile does not exist (StateError), '
      'WHEN getProfile is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.getProfile(dummyProfile.uid),
        ).thenThrow(StateError('No element'));

        // Act.
        final result = await repository.getProfile(dummyProfile.uid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.notFound())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN getProfile is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.getProfile(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.getProfile(dummyProfile.uid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN getProfile is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.getProfile(any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.getProfile(dummyProfile.uid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.network())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unrecognised FirebaseException code, '
      'WHEN getProfile is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.getProfile(any()),
        ).thenThrow(_firebaseException('internal'));

        // Act.
        final result = await repository.getProfile(dummyProfile.uid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.unknown())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a non-Firebase exception, '
      'WHEN getProfile is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.getProfile(any()),
        ).thenThrow(Exception('Unexpected error'));

        // Act.
        final result = await repository.getProfile(dummyProfile.uid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.unknown())),
        );
      },
    );

    test(
      '[EDGE CASE] - GIVEN an empty UID string, '
      'WHEN getProfile is called and the API throws a StateError, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(() => mockApi.getProfile('')).thenThrow(StateError('No element'));

        // Act.
        final result = await repository.getProfile('');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<UserProfile>.failure(AppFailure.notFound())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  group('UserProfileRepositoryImpl.updateProfile', () {
    test('[HAPPY PATH] - GIVEN a valid UserProfile, '
        'WHEN updateProfile is called, '
        'THEN should return Result.success with null', () async {
      // Arrange.
      when(
        () => mockApi.updateProfile(dummyProfile.uid, any()),
      ).thenAnswer((_) async {});

      // Act.
      final result = await repository.updateProfile(dummyProfile);

      // Assert.
      expect(result.isSuccess, isTrue);
      verify(() => mockApi.updateProfile(dummyProfile.uid, any())).called(1);
    });

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN updateProfile is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateProfile(any(), any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.updateProfile(dummyProfile);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN updateProfile is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateProfile(any(), any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.updateProfile(dummyProfile);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a not-found FirebaseException, '
      'WHEN updateProfile is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateProfile(any(), any()),
        ).thenThrow(_firebaseException('not-found'));

        // Act.
        final result = await repository.updateProfile(dummyProfile);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.notFound())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unrecognised FirebaseException code, '
      'WHEN updateProfile is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateProfile(any(), any()),
        ).thenThrow(_firebaseException('internal'));

        // Act.
        final result = await repository.updateProfile(dummyProfile);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a non-Firebase exception, '
      'WHEN updateProfile is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateProfile(any(), any()),
        ).thenThrow(Exception('Unexpected error'));

        // Act.
        final result = await repository.updateProfile(dummyProfile);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // saveFcmToken
  // ---------------------------------------------------------------------------

  group('UserProfileRepositoryImpl.saveFcmToken', () {
    test(
      '[HAPPY PATH] - GIVEN a valid uid and token, '
      'WHEN saveFcmToken is called, '
      'THEN should call api.saveFcmToken and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.saveFcmToken(dummyProfile.uid, 'fcm-token-abc'),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.saveFcmToken(
          dummyProfile.uid,
          'fcm-token-abc',
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(
          () => mockApi.saveFcmToken(dummyProfile.uid, 'fcm-token-abc'),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN saveFcmToken is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.saveFcmToken(any(), any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.saveFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN saveFcmToken is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.saveFcmToken(any(), any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.saveFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a non-Firebase exception, '
      'WHEN saveFcmToken is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.saveFcmToken(any(), any()),
        ).thenThrow(Exception('Unexpected'));

        // Act.
        final result = await repository.saveFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // clearFcmToken
  // ---------------------------------------------------------------------------

  group('UserProfileRepositoryImpl.clearFcmToken', () {
    test(
      '[HAPPY PATH] - GIVEN a valid uid and token, '
      'WHEN clearFcmToken is called, '
      'THEN should call api.clearFcmToken and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.clearFcmToken(dummyProfile.uid, 'fcm-token-abc'),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.clearFcmToken(
          dummyProfile.uid,
          'fcm-token-abc',
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(
          () => mockApi.clearFcmToken(dummyProfile.uid, 'fcm-token-abc'),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN clearFcmToken is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.clearFcmToken(any(), any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.clearFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN clearFcmToken is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.clearFcmToken(any(), any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.clearFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a non-Firebase exception, '
      'WHEN clearFcmToken is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.clearFcmToken(any(), any()),
        ).thenThrow(Exception('Unexpected'));

        // Act.
        final result = await repository.clearFcmToken(dummyProfile.uid, 'tok');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
      },
    );
  });
}
