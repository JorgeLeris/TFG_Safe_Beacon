import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/logout_cubit.dart';

// MARK: - DUMMY DATA

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

MockAppLocalizations _buildL10n() {
  final l10n = MockAppLocalizations();
  when(() => l10n.logoutFailed).thenReturn('logout_failed');
  return l10n;
}

// MARK: - TEST CASES

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAppLocalizations l10n;
  late LogoutCubit cubit;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    l10n = _buildL10n();
    cubit = LogoutCubit(authRepository: mockAuthRepository);
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // onLogout
  // ---------------------------------------------------------------------------

  group('LogoutCubit.onLogout', () {
    blocTest<LogoutCubit, LogoutState>(
      '[HAPPY PATH] - GIVEN a successful logout from repository, '
      'WHEN onLogout is called, '
      'THEN should emit [loading, success]',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.onLogout(l10n),
      expect: () => [
        const LogoutState(isLoading: true),
        const LogoutState(isSuccess: true),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.logout()).called(1);
      },
    );

    blocTest<LogoutCubit, LogoutState>(
      '[ERROR PATH] - GIVEN an exception thrown by repository, '
      'WHEN onLogout is called, '
      'THEN should emit [loading, errorMessage]',
      build: () {
        when(
          () => mockAuthRepository.logout(),
        ).thenThrow(Exception('Logout error'));
        return cubit;
      },
      act: (cubit) => cubit.onLogout(l10n),
      expect: () => [
        const LogoutState(isLoading: true),
        const LogoutState(errorMessage: 'logout_failed'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.logout()).called(1);
      },
    );
  });
}
