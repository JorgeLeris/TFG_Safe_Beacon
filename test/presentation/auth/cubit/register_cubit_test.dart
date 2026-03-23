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
import 'package:safe_beacon/presentation/features/auth/cubits/register_cubit.dart';

// MARK: - DUMMY DATA

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockUser extends Mock implements User {}

const dummyEmail = 'test@example.com';
const dummyPassword = 'password123';
final dummyBirthDate = DateTime(1990, 1, 15);

RegisterState get _validStep2Seed => RegisterState(
  email: dummyEmail,
  password: dummyPassword,
  confirmPassword: dummyPassword,
  name: 'John',
  surname: 'Doe',
  birthDate: dummyBirthDate,
  gender: 'male',
  description: 'A description',
);

MockAppLocalizations _buildL10n() {
  final l10n = MockAppLocalizations();
  when(() => l10n.emailRequired).thenReturn('email_required');
  when(() => l10n.emailInvalid).thenReturn('email_invalid');
  when(() => l10n.passwordRequired).thenReturn('password_required');
  when(() => l10n.passwordInvalid).thenReturn('password_invalid');
  when(
    () => l10n.confirmPasswordRequired,
  ).thenReturn('confirm_password_required');
  when(() => l10n.passwordsDoNotMatch).thenReturn('passwords_do_not_match');
  when(() => l10n.nameRequired).thenReturn('name_required');
  when(() => l10n.surnameRequired).thenReturn('surname_required');
  when(() => l10n.birthDateRequired).thenReturn('birth_date_required');
  when(() => l10n.genderRequired).thenReturn('gender_required');
  when(() => l10n.registrationFailed).thenReturn('registration_failed');
  when(() => l10n.registerEmailAlreadyInUse).thenReturn('email_already_in_use');
  when(() => l10n.registerWeakPassword).thenReturn('weak_password');
  when(() => l10n.loginTooManyRequests).thenReturn('too_many_requests');
  return l10n;
}

MockUser _buildUser({String uid = 'uid-123'}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  return user;
}

// MARK: - TEST CASES

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserProfileRepository mockProfileRepository;
  late MockAppLocalizations l10n;
  late RegisterCubit cubit;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockProfileRepository = MockUserProfileRepository();
    l10n = _buildL10n();
    cubit = RegisterCubit(
      authRepository: mockAuthRepository,
      userProfileRepository: mockProfileRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(const UserProfile(uid: 'fallback', name: 'fallback'));
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // Field change methods
  // ---------------------------------------------------------------------------

  group('RegisterCubit - field state updates', () {
    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onEmailChanged is called, '
      'THEN should emit state with updated email',
      build: () => cubit,
      act: (cubit) => cubit.onEmailChanged(dummyEmail),
      expect: () => [const RegisterState(email: dummyEmail)],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onPasswordChanged is called, '
      'THEN should emit state with updated password',
      build: () => cubit,
      act: (cubit) => cubit.onPasswordChanged(dummyPassword),
      expect: () => [const RegisterState(password: dummyPassword)],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onConfirmPasswordChanged is called, '
      'THEN should emit state with updated confirmPassword',
      build: () => cubit,
      act: (cubit) => cubit.onConfirmPasswordChanged(dummyPassword),
      expect: () => [const RegisterState(confirmPassword: dummyPassword)],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onNameChanged is called, '
      'THEN should emit state with updated name',
      build: () => cubit,
      act: (cubit) => cubit.onNameChanged('John'),
      expect: () => [const RegisterState(name: 'John')],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onSurnameChanged is called, '
      'THEN should emit state with updated surname',
      build: () => cubit,
      act: (cubit) => cubit.onSurnameChanged('Doe'),
      expect: () => [const RegisterState(surname: 'Doe')],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onGenderChanged is called, '
      'THEN should emit state with updated gender',
      build: () => cubit,
      act: (cubit) => cubit.onGenderChanged('male'),
      expect: () => [const RegisterState(gender: 'male')],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onDescriptionChanged is called, '
      'THEN should emit state with updated description',
      build: () => cubit,
      act: (cubit) => cubit.onDescriptionChanged('A description'),
      expect: () => [const RegisterState(description: 'A description')],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[STATE UPDATE] - GIVEN initial state, '
      'WHEN onBirthDateChanged is called with a date, '
      'THEN should emit state with updated birthDate',
      build: () => cubit,
      act: (cubit) => cubit.onBirthDateChanged(dummyBirthDate),
      expect: () => [RegisterState(birthDate: dummyBirthDate)],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[EDGE CASE] - GIVEN a birthDate previously set, '
      'WHEN onBirthDateChanged is called with null, '
      'THEN should emit state with null birthDate',
      build: () => cubit,
      seed: () => RegisterState(birthDate: dummyBirthDate),
      act: (cubit) => cubit.onBirthDateChanged(null),
      expect: () => [const RegisterState()],
    );
  });

  // ---------------------------------------------------------------------------
  // onNextStep
  // ---------------------------------------------------------------------------

  group('RegisterCubit.onNextStep', () {
    blocTest<RegisterCubit, RegisterState>(
      '[HAPPY PATH] - GIVEN valid email, password, and matching confirmPassword, '
      'WHEN onNextStep is called, '
      'THEN should emit step1Completed: true',
      build: () => cubit,
      seed: () => const RegisterState(
        email: dummyEmail,
        password: dummyPassword,
        confirmPassword: dummyPassword,
      ),
      act: (cubit) => cubit.onNextStep(l10n),
      expect: () => [
        const RegisterState(
          email: dummyEmail,
          password: dummyPassword,
          confirmPassword: dummyPassword,
          step1Completed: true,
        ),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN empty email, empty password, and empty confirmPassword, '
      'WHEN onNextStep is called, '
      'THEN should emit all three field validation errors',
      build: () => cubit,
      seed: () => const RegisterState(),
      act: (cubit) => cubit.onNextStep(l10n),
      expect: () => [
        const RegisterState(
          emailError: 'email_required',
          passwordError: 'password_required',
          confirmPasswordError: 'confirm_password_required',
        ),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN a malformed email and short password, '
      'WHEN onNextStep is called, '
      'THEN should emit email and password validation errors',
      build: () => cubit,
      seed: () => const RegisterState(
        email: 'not-an-email',
        password: '123',
        confirmPassword: '123',
      ),
      act: (cubit) => cubit.onNextStep(l10n),
      expect: () => [
        const RegisterState(
          email: 'not-an-email',
          password: '123',
          confirmPassword: '123',
          emailError: 'email_invalid',
          passwordError: 'password_invalid',
        ),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN valid email and password but mismatched confirmPassword, '
      'WHEN onNextStep is called, '
      'THEN should emit confirmPassword mismatch error',
      build: () => cubit,
      seed: () => const RegisterState(
        email: dummyEmail,
        password: dummyPassword,
        confirmPassword: 'different_password',
      ),
      act: (cubit) => cubit.onNextStep(l10n),
      expect: () => [
        const RegisterState(
          email: dummyEmail,
          password: dummyPassword,
          confirmPassword: 'different_password',
          confirmPasswordError: 'passwords_do_not_match',
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // onSubmit
  // ---------------------------------------------------------------------------

  group('RegisterCubit.onSubmit', () {
    blocTest<RegisterCubit, RegisterState>(
      '[HAPPY PATH] - GIVEN all step-2 fields valid and successful auth + profile creation, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, requiresEmailVerification]',
      build: () {
        final user = _buildUser();
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenAnswer((_) async => user);
        when(
          () => mockProfileRepository.createProfile(any(), any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
        when(
          () => mockAuthRepository.sendEmailVerificationLink(),
        ).thenAnswer((_) async {});
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true, errorMessage: null),
        _validStep2Seed.copyWith(requiresEmailVerification: true),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).called(1);
        verify(
          () => mockProfileRepository.createProfile(any(), any()),
        ).called(1);
        verify(() => mockAuthRepository.sendEmailVerificationLink()).called(1);
      },
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN createUserWithCredential returns null, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(registrationFailed)]',
      build: () {
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenAnswer((_) async => null);
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true),
        _validStep2Seed.copyWith(errorMessage: 'registration_failed'),
      ],
      verify: (_) {
        verifyNever(() => mockProfileRepository.createProfile(any(), any()));
      },
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN successful user creation but profile creation fails, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(registrationFailed)]',
      build: () {
        final user = _buildUser();
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenAnswer((_) async => user);
        when(
          () => mockProfileRepository.createProfile(any(), any()),
        ).thenAnswer(
          (_) async => const Result<void>.failure(AppFailure.unknown()),
        );
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true),
        _validStep2Seed.copyWith(errorMessage: 'registration_failed'),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException with code email-already-in-use, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(emailAlreadyInUse)]',
      build: () {
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true),
        _validStep2Seed.copyWith(errorMessage: 'email_already_in_use'),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN a FirebaseAuthException with code weak-password, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(weakPassword)]',
      build: () {
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'weak-password'));
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true),
        _validStep2Seed.copyWith(errorMessage: 'weak_password'),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN a generic exception, '
      'WHEN onSubmit is called, '
      'THEN should emit [loading, errorMessage(registrationFailed)]',
      build: () {
        when(
          () => mockAuthRepository.createUserWithCredential(
            dummyEmail,
            dummyPassword,
          ),
        ).thenThrow(Exception('Unexpected'));
        return cubit;
      },
      seed: () => _validStep2Seed,
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        _validStep2Seed.copyWith(isLoading: true),
        _validStep2Seed.copyWith(errorMessage: 'registration_failed'),
      ],
    );

    blocTest<RegisterCubit, RegisterState>(
      '[ERROR PATH] - GIVEN missing name, surname, birthDate, and gender, '
      'WHEN onSubmit is called, '
      'THEN should emit all step-2 validation errors without calling any repository',
      build: () => cubit,
      seed: () =>
          const RegisterState(email: dummyEmail, password: dummyPassword),
      act: (cubit) => cubit.onSubmit(l10n),
      expect: () => [
        const RegisterState(
          email: dummyEmail,
          password: dummyPassword,
          nameError: 'name_required',
          surnameError: 'surname_required',
          birthDateError: 'birth_date_required',
          genderError: 'gender_required',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockAuthRepository.createUserWithCredential(any(), any()),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // clearErrors
  // ---------------------------------------------------------------------------

  group('RegisterCubit.clearErrors', () {
    blocTest<RegisterCubit, RegisterState>(
      '[RESET ACTION] - GIVEN a state with active field errors and step1Completed, '
      'WHEN clearErrors is called, '
      'THEN should emit a clean state with all errors and step1Completed nulled',
      build: () => cubit,
      seed: () => const RegisterState(
        email: dummyEmail,
        emailError: 'email_required',
        passwordError: 'password_required',
        nameError: 'name_required',
        errorMessage: 'registration_failed',
        step1Completed: true,
      ),
      act: (cubit) => cubit.clearErrors(),
      expect: () => [const RegisterState(email: dummyEmail)],
    );
  });

  // ---------------------------------------------------------------------------
  // clearVerificationFlag
  // ---------------------------------------------------------------------------

  group('RegisterCubit.clearVerificationFlag', () {
    blocTest<RegisterCubit, RegisterState>(
      '[RESET ACTION] - GIVEN a state with requiresEmailVerification set, '
      'WHEN clearVerificationFlag is called, '
      'THEN should emit state with requiresEmailVerification as false',
      build: () => cubit,
      seed: () => const RegisterState(requiresEmailVerification: true),
      act: (cubit) => cubit.clearVerificationFlag(),
      expect: () => [const RegisterState()],
    );
  });

  // ---------------------------------------------------------------------------
  // resendVerificationEmail
  // ---------------------------------------------------------------------------

  group('RegisterCubit.resendVerificationEmail', () {
    blocTest<RegisterCubit, RegisterState>(
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

    blocTest<RegisterCubit, RegisterState>(
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
