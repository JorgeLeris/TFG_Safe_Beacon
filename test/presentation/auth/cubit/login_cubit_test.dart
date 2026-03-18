import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/login_cubit.dart';

// MARK: - DUMMY DATA

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockUser extends Mock implements User {}

const dummyEmail = 'test@example.com';
const dummyPassword = 'password123';

MockAppLocalizations _buildL10n() {
  final l10n = MockAppLocalizations();
  when(() => l10n.emailRequired).thenReturn('email_required');
  when(() => l10n.emailInvalid).thenReturn('email_invalid');
  when(() => l10n.passwordRequired).thenReturn('password_required');
  when(() => l10n.passwordInvalid).thenReturn('password_invalid');
  when(() => l10n.loginFailed).thenReturn('login_failed');
  when(() => l10n.loginUserNotFound).thenReturn('user_not_found');
  when(() => l10n.loginInvalidPassword).thenReturn('invalid_password');
  when(() => l10n.loginInvalidCredentials).thenReturn('invalid_credentials');
  when(() => l10n.loginUserDisabled).thenReturn('user_disabled');
  when(() => l10n.loginTooManyRequests).thenReturn('too_many_requests');
  return l10n;
}

MockUser _buildUser({
  bool emailVerified = true,
  String uid = 'uid-123',
  String? displayName,
  String? photoURL,
  String? email,
}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.emailVerified).thenReturn(emailVerified);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.photoURL).thenReturn(photoURL);
  when(() => user.email).thenReturn(email);
  return user;
}

// MARK: - TEST CASES

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserProfileRepository mockProfileRepository;
  late MockAppLocalizations l10n;
  late LoginCubit cubit;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockProfileRepository = MockUserProfileRepository();
    l10n = _buildL10n();
    cubit = LoginCubit(
      authRepository: mockAuthRepository,
      userProfileRepository: mockProfileRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(const UserProfile(uid: 'fallback', name: 'fallback'));
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // onEmailChanged
  // ---------------------------------------------------------------------------

  group('LoginCubit.onEmailChanged', () {
    blocTest<LoginCubit, LoginState>(
      '[STATE UPDATE] - GIVEN an initial state, '
      'WHEN onEmailChanged is called, '
      'THEN should emit state with updated email',
      build: () => cubit,
      act: (cubit) => cubit.onEmailChanged(dummyEmail),
      expect: () => [const LoginState(email: dummyEmail)],
    );
  });

  // ---------------------------------------------------------------------------
  // onPasswordChanged
  // ---------------------------------------------------------------------------

  group('LoginCubit.onPasswordChanged', () {
    blocTest<LoginCubit, LoginState>(
      '[STATE UPDATE] - GIVEN an initial state, '
      'WHEN onPasswordChanged is called, '
      'THEN should emit state with updated password',
      build: () => cubit,
      act: (cubit) => cubit.onPasswordChanged(dummyPassword),
      expect: () => [const LoginState(password: dummyPassword)],
    );
  });

  // ---------------------------------------------------------------------------
  // onSubmit
  // ---------------------------------------------------------------------------

  group('LoginCubit.onSubmit', () {
    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN valid credentials and a verified user returned, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, success(isLoading: false)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenAnswer((_) async => _buildUser());
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(email: dummyEmail, password: dummyPassword),
      ],
      verify: (_) {
        verify(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN valid credentials but repository returns null user, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenAnswer((_) async => null);
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          errorMessage: 'login_failed',
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN valid credentials but returned user has unverified email, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, requiresEmailVerification]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenAnswer((_) async => _buildUser(emailVerified: false));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          requiresEmailVerification: true,
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException with code user-not-found, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(userNotFound)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          errorMessage: 'user_not_found',
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException with code invalid-credential, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(invalidCredentials)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          errorMessage: 'invalid_credentials',
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException with code too-many-requests, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(tooManyRequests)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenThrow(FirebaseAuthException(code: 'too-many-requests'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          errorMessage: 'too_many_requests',
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a generic unexpected exception, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        when(
          () =>
              mockAuthRepository.loginWithCredential(dummyEmail, dummyPassword),
        ).thenThrow(Exception('Unexpected'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          isLoading: true,
        ),
        const LoginState(
          email: dummyEmail,
          password: dummyPassword,
          errorMessage: 'login_failed',
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[EDGE CASE] - GIVEN an empty email, '
      'WHEN onSubmit is called, '
      'THEN should emit validation errors without calling the repository',
      build: () => cubit,
      seed: () => const LoginState(),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          emailError: 'email_required',
          passwordError: 'password_required',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockAuthRepository.loginWithCredential(any(), any()));
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[EDGE CASE] - GIVEN a malformed email and short password, '
      'WHEN onSubmit is called, '
      'THEN should emit field-specific validation errors',
      build: () => cubit,
      seed: () => const LoginState(email: 'not-an-email', password: '123'),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const LoginState(
          email: 'not-an-email',
          password: '123',
          emailError: 'email_invalid',
          passwordError: 'password_invalid',
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // onGoogleLogin
  // ---------------------------------------------------------------------------

  group('LoginCubit.onGoogleLogin', () {
    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a successful Google login for an existing user, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, success] without creating a profile',
      build: () {
        final user = _buildUser(email: dummyEmail);
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => (user: user as User?, isNewUser: false));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [const LoginState(isLoading: true), const LoginState()],
      verify: (_) {
        verifyNever(() => mockProfileRepository.createProfile(any(), any()));
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a successful Google login for a new user with display name, '
      'WHEN onGoogleLogin is called, '
      'THEN should create a profile and emit [loading, success]',
      build: () {
        final user = _buildUser(
          displayName: 'John Doe',
          photoURL: 'https://photo.url',
          email: 'john.doe@gmail.com',
        );
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => (user: user as User?, isNewUser: true));
        when(
          () => mockProfileRepository.createProfile(any(), any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [const LoginState(isLoading: true), const LoginState()],
      verify: (_) {
        verify(
          () => mockProfileRepository.createProfile(any(), any()),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a new user with no display name, '
      'WHEN onGoogleLogin is called, '
      'THEN should create a profile with empty name and emit [loading, success]',
      build: () {
        final user = _buildUser(email: dummyEmail);
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => (user: user as User?, isNewUser: true));
        when(
          () => mockProfileRepository.createProfile(any(), any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [const LoginState(isLoading: true), const LoginState()],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN loginWithGoogle returns null result, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => null);
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [
        const LoginState(isLoading: true),
        const LoginState(errorMessage: 'login_failed'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN loginWithGoogle returns a result with null user, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => (user: null as User?, isNewUser: false));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [
        const LoginState(isLoading: true),
        const LoginState(errorMessage: 'login_failed'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a new user whose profile creation fails, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        final user = _buildUser(displayName: 'John', email: 'john@gmail.com');
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenAnswer((_) async => (user: user as User?, isNewUser: true));
        when(
          () => mockProfileRepository.createProfile(any(), any()),
        ).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.unknown()),
        );
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [
        const LoginState(isLoading: true),
        const LoginState(errorMessage: 'login_failed'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException during Google login, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, errorMessage(mapped)]',
      build: () {
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenThrow(FirebaseAuthException(code: 'user-disabled'));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [
        const LoginState(isLoading: true),
        const LoginState(errorMessage: 'user_disabled'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a generic exception during Google login, '
      'WHEN onGoogleLogin is called, '
      'THEN should emit [loading, errorMessage(loginFailed)]',
      build: () {
        when(
          () => mockAuthRepository.loginWithGoogle(),
        ).thenThrow(Exception('Google error'));
        return cubit;
      },
      act: (cubit) => cubit.onGoogleLogin(l10n),
      expect: () => [
        const LoginState(isLoading: true),
        const LoginState(errorMessage: 'login_failed'),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // onForgotPassword
  // ---------------------------------------------------------------------------

  group('LoginCubit.onForgotPassword', () {
    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a valid email in state, '
      'WHEN onForgotPassword is called, '
      'THEN should emit isPasswordResetDialogReady',
      build: () => cubit,
      seed: () => const LoginState(email: dummyEmail),
      act: (cubit) => cubit.onForgotPassword(l10n),
      expect: () => [
        const LoginState(email: dummyEmail, isPasswordResetDialogReady: true),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN an empty email in state, '
      'WHEN onForgotPassword is called, '
      'THEN should emit emailError without opening the dialog',
      build: () => cubit,
      seed: () => const LoginState(),
      act: (cubit) => cubit.onForgotPassword(l10n),
      expect: () => [const LoginState(emailError: 'email_required')],
    );

    blocTest<LoginCubit, LoginState>(
      '[EDGE CASE] - GIVEN a malformed email in state, '
      'WHEN onForgotPassword is called, '
      'THEN should emit emailError(invalid)',
      build: () => cubit,
      seed: () => const LoginState(email: 'not-an-email'),
      act: (cubit) => cubit.onForgotPassword(l10n),
      expect: () => [
        const LoginState(email: 'not-an-email', emailError: 'email_invalid'),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // sendPasswordResetLink
  // ---------------------------------------------------------------------------

  group('LoginCubit.sendPasswordResetLink', () {
    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a successful password reset request, '
      'WHEN sendPasswordResetLink is called, '
      'THEN should emit nothing (no state change on success)',
      build: () {
        when(
          () => mockAuthRepository.sendPasswordResetLink(dummyEmail),
        ).thenAnswer((_) async {});
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail),
      act: (cubit) => cubit.sendPasswordResetLink(l10n),
      expect: () => [],
      verify: (_) {
        verify(
          () => mockAuthRepository.sendPasswordResetLink(dummyEmail),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException during password reset, '
      'WHEN sendPasswordResetLink is called, '
      'THEN should emit errorMessage(mapped)',
      build: () {
        when(
          () => mockAuthRepository.sendPasswordResetLink(dummyEmail),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail),
      act: (cubit) => cubit.sendPasswordResetLink(l10n),
      expect: () => [
        const LoginState(email: dummyEmail, errorMessage: 'user_not_found'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN a generic exception during password reset, '
      'WHEN sendPasswordResetLink is called, '
      'THEN should emit errorMessage(loginFailed)',
      build: () {
        when(
          () => mockAuthRepository.sendPasswordResetLink(dummyEmail),
        ).thenThrow(Exception('Reset error'));
        return cubit;
      },
      seed: () => const LoginState(email: dummyEmail),
      act: (cubit) => cubit.sendPasswordResetLink(l10n),
      expect: () => [
        const LoginState(email: dummyEmail, errorMessage: 'login_failed'),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // clearErrors
  // ---------------------------------------------------------------------------

  group('LoginCubit.clearErrors', () {
    blocTest<LoginCubit, LoginState>(
      '[RESET ACTION] - GIVEN a state with active errors, '
      'WHEN clearErrors is called, '
      'THEN should emit a clean state with all errors nulled',
      build: () => cubit,
      seed: () => const LoginState(
        email: dummyEmail,
        password: dummyPassword,
        emailError: 'email_required',
        passwordError: 'password_required',
        errorMessage: 'login_failed',
      ),
      act: (cubit) => cubit.clearErrors(),
      expect: () => [
        const LoginState(email: dummyEmail, password: dummyPassword),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // clearVerificationFlag
  // ---------------------------------------------------------------------------

  group('LoginCubit.clearVerificationFlag', () {
    blocTest<LoginCubit, LoginState>(
      '[RESET ACTION] - GIVEN a state with requiresEmailVerification set, '
      'WHEN clearVerificationFlag is called, '
      'THEN should emit state with requiresEmailVerification as false',
      build: () => cubit,
      seed: () => const LoginState(requiresEmailVerification: true),
      act: (cubit) => cubit.clearVerificationFlag(),
      expect: () => [const LoginState()],
    );
  });

  // ---------------------------------------------------------------------------
  // clearPasswordResetFlag
  // ---------------------------------------------------------------------------

  group('LoginCubit.clearPasswordResetFlag', () {
    blocTest<LoginCubit, LoginState>(
      '[RESET ACTION] - GIVEN a state with isPasswordResetDialogReady set, '
      'WHEN clearPasswordResetFlag is called, '
      'THEN should emit state with isPasswordResetDialogReady as false',
      build: () => cubit,
      seed: () => const LoginState(isPasswordResetDialogReady: true),
      act: (cubit) => cubit.clearPasswordResetFlag(),
      expect: () => [const LoginState()],
    );
  });

  // ---------------------------------------------------------------------------
  // resendVerificationEmail
  // ---------------------------------------------------------------------------

  group('LoginCubit.resendVerificationEmail', () {
    blocTest<LoginCubit, LoginState>(
      '[HAPPY PATH] - GIVEN a successful resend request, '
      'WHEN resendVerificationEmail is called, '
      'THEN should emit nothing (fire and forget)',
      build: () {
        when(
          () => mockAuthRepository.sendEmailVerificationLink(),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.resendVerificationEmail(),
      expect: () => [],
      verify: (_) {
        verify(() => mockAuthRepository.sendEmailVerificationLink()).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      '[ERROR PATH] - GIVEN an exception during resend, '
      'WHEN resendVerificationEmail is called, '
      'THEN should emit nothing (exception is swallowed)',
      build: () {
        when(
          () => mockAuthRepository.sendEmailVerificationLink(),
        ).thenThrow(Exception('Resend error'));
        return cubit;
      },
      act: (cubit) => cubit.resendVerificationEmail(),
      expect: () => [],
    );
  });
}
