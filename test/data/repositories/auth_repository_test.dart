import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/data/repositories/auth_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';

// MARK: - DUMMY DATA & MOCKS

class MockAuthApi extends Mock implements AuthApi {}

class MockUser extends Mock implements User {}

class FakeException extends Fake implements Exception {}

extension MockUserX on MockUser {
  void stubUid(String uid) => when(() => this.uid).thenReturn(uid);
}

// Dummy data.
const dummyEmail = 'test@example.com';
const dummyPassword = 'password123';

final dummyUser = MockUser()..stubUid('mock-uid-123');

// MARK: - TEST CASES

void main() {
  late MockAuthApi mockAuthApi;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockAuthApi = MockAuthApi();
    repository = AuthRepositoryImpl(authApi: mockAuthApi);
    registerFallbackValue(FakeException());
  });

  // ---------------------------------------------------------------------------
  // sendEmailVerificationLink
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.sendEmailVerificationLink', () {
    test('[HAPPY PATH] - GIVEN a valid authenticated user, '
        'WHEN sendEmailVerificationLink is called, '
        'THEN should complete without throwing', () async {
      // Arrange.
      when(
        () => mockAuthApi.sendEmailVerificationLink(),
      ).thenAnswer((_) async {});

      // Act.
      final call = repository.sendEmailVerificationLink();

      // Assert.
      await expectLater(call, completes);
      verify(() => mockAuthApi.sendEmailVerificationLink()).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN sendEmailVerificationLink is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(
        () => mockAuthApi.sendEmailVerificationLink(),
      ).thenThrow(Exception('Verification link error'));

      // Act & Assert.
      await expectLater(
        repository.sendEmailVerificationLink(),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // reloadUser
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.reloadUser', () {
    test('[HAPPY PATH] - GIVEN a valid authenticated user, '
        'WHEN reloadUser is called, '
        'THEN should complete without throwing', () async {
      // Arrange.
      when(() => mockAuthApi.reloadUser()).thenAnswer((_) async {});

      // Act.
      final call = repository.reloadUser();

      // Assert.
      await expectLater(call, completes);
      verify(() => mockAuthApi.reloadUser()).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN reloadUser is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(() => mockAuthApi.reloadUser()).thenThrow(Exception('Reload error'));

      // Act & Assert.
      await expectLater(repository.reloadUser(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // createUserWithCredential
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.createUserWithCredential', () {
    test('[HAPPY PATH] - GIVEN valid email and password, '
        'WHEN createUserWithCredential is called, '
        'THEN should return the created User', () async {
      // Arrange.
      when(
        () => mockAuthApi.createUserWithCredential(dummyEmail, dummyPassword),
      ).thenAnswer((_) async => dummyUser);

      // Act.
      final result = await repository.createUserWithCredential(
        dummyEmail,
        dummyPassword,
      );

      // Assert.
      expect(result, isA<User>());
      expect(result, equals(dummyUser));
      verify(
        () => mockAuthApi.createUserWithCredential(dummyEmail, dummyPassword),
      ).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN createUserWithCredential is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(
        () => mockAuthApi.createUserWithCredential(dummyEmail, dummyPassword),
      ).thenThrow(Exception('Create user error'));

      // Act & Assert.
      await expectLater(
        repository.createUserWithCredential(dummyEmail, dummyPassword),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loginWithCredential
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.loginWithCredential', () {
    test('[HAPPY PATH] - GIVEN valid email and password, '
        'WHEN loginWithCredential is called, '
        'THEN should return the logged-in User', () async {
      // Arrange.
      when(
        () => mockAuthApi.loginWithCredential(dummyEmail, dummyPassword),
      ).thenAnswer((_) async => dummyUser);

      // Act.
      final result = await repository.loginWithCredential(
        dummyEmail,
        dummyPassword,
      );

      // Assert.
      expect(result, isA<User>());
      expect(result, equals(dummyUser));
      verify(
        () => mockAuthApi.loginWithCredential(dummyEmail, dummyPassword),
      ).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN loginWithCredential is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(
        () => mockAuthApi.loginWithCredential(dummyEmail, dummyPassword),
      ).thenThrow(Exception('Login error'));

      // Act & Assert.
      await expectLater(
        repository.loginWithCredential(dummyEmail, dummyPassword),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loginWithGoogle
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.loginWithGoogle', () {
    test(
      '[HAPPY PATH] - GIVEN a successful Google Sign-In for an existing user, '
      'WHEN loginWithGoogle is called, '
      'THEN should return a record with the User and isNewUser as false',
      () async {
        // Arrange.
        final expectedResult = (user: dummyUser as User?, isNewUser: false);
        when(
          () => mockAuthApi.loginWithGoogle(),
        ).thenAnswer((_) async => expectedResult);

        // Act.
        final result = await repository.loginWithGoogle();

        // Assert.
        expect(result, isNotNull);
        expect(result!.user, equals(dummyUser));
        expect(result.isNewUser, isFalse);
        verify(() => mockAuthApi.loginWithGoogle()).called(1);
      },
    );

    test(
      '[HAPPY PATH] - GIVEN a successful Google Sign-In for a new user, '
      'WHEN loginWithGoogle is called, '
      'THEN should return a record with the User and isNewUser as true',
      () async {
        // Arrange.
        final expectedResult = (user: dummyUser as User?, isNewUser: true);
        when(
          () => mockAuthApi.loginWithGoogle(),
        ).thenAnswer((_) async => expectedResult);

        // Act.
        final result = await repository.loginWithGoogle();

        // Assert.
        expect(result, isNotNull);
        expect(result!.isNewUser, isTrue);
      },
    );

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN loginWithGoogle is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(
        () => mockAuthApi.loginWithGoogle(),
      ).thenThrow(Exception('Google login error'));

      // Act & Assert.
      await expectLater(repository.loginWithGoogle(), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.logout', () {
    test('[HAPPY PATH] - GIVEN an authenticated user, '
        'WHEN logout is called, '
        'THEN should complete without throwing', () async {
      // Arrange.
      when(() => mockAuthApi.logout()).thenAnswer((_) async {});

      // Act.
      final call = repository.logout();

      // Assert.
      await expectLater(call, completes);
      verify(() => mockAuthApi.logout()).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN logout is called, '
        'THEN should swallow the exception and complete normally', () async {
      // Arrange.
      // Note: logout catches internally and does NOT rethrow.
      when(() => mockAuthApi.logout()).thenThrow(Exception('Logout error'));

      // Act.
      final call = repository.logout();

      // Assert: the exception is swallowed, so the future should complete.
      await expectLater(call, completes);
    });
  });

  // ---------------------------------------------------------------------------
  // sendPasswordResetLink
  // ---------------------------------------------------------------------------

  group('AuthRepositoryImpl.sendPasswordResetLink', () {
    test('[HAPPY PATH] - GIVEN a valid email address, '
        'WHEN sendPasswordResetLink is called, '
        'THEN should complete without throwing', () async {
      // Arrange.
      when(
        () => mockAuthApi.sendPasswordResetLink(dummyEmail),
      ).thenAnswer((_) async {});

      // Act.
      final call = repository.sendPasswordResetLink(dummyEmail);

      // Assert.
      await expectLater(call, completes);
      verify(() => mockAuthApi.sendPasswordResetLink(dummyEmail)).called(1);
    });

    test('[ERROR PATH] - GIVEN the API throws an exception, '
        'WHEN sendPasswordResetLink is called, '
        'THEN should rethrow the exception', () async {
      // Arrange.
      when(
        () => mockAuthApi.sendPasswordResetLink(dummyEmail),
      ).thenThrow(Exception('Reset link error'));

      // Act & Assert.
      await expectLater(
        repository.sendPasswordResetLink(dummyEmail),
        throwsException,
      );
    });
  });
}
