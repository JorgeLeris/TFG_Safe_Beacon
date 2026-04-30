import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/core/theme/cubit/theme_cubit.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';

// MARK: - DUMMY DATA

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

// MARK: - TEST CASES

void main() {
  late MockAppSettingsRepository mockRepository;
  late ThemeCubit cubit;

  setUp(() {
    mockRepository = MockAppSettingsRepository();
    cubit = ThemeCubit(
      themeMode: ThemeMode.system,
      appSettingsRepository: mockRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  // ---------------------------------------------------------------------------
  // initial state
  // ---------------------------------------------------------------------------

  group('ThemeCubit - initial state', () {
    test(
      '[STATE UPDATE] - GIVEN a ThemeMode, WHEN the cubit is created, THEN the initial state should reflect that ThemeMode',
      () {
        expect(cubit.state, const ThemeState.initial(themeMode: ThemeMode.system));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // setThemeMode
  // ---------------------------------------------------------------------------

  group('ThemeCubit.setThemeMode', () {
    blocTest<ThemeCubit, ThemeState>(
      '[HAPPY PATH] - GIVEN ThemeMode.dark, WHEN setThemeMode is called, THEN should persist "dark" and emit the dark state',
      build: () {
        when(
          () => mockRepository.setThemeMode(themeMode: 'dark'),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.setThemeMode(ThemeMode.dark),
      expect: () => [const ThemeState.initial(themeMode: ThemeMode.dark)],
      verify: (_) {
        verify(
          () => mockRepository.setThemeMode(themeMode: 'dark'),
        ).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      '[HAPPY PATH] - GIVEN ThemeMode.light, WHEN setThemeMode is called, THEN should persist "light" and emit the light state',
      build: () {
        when(
          () => mockRepository.setThemeMode(themeMode: 'light'),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.setThemeMode(ThemeMode.light),
      expect: () => [const ThemeState.initial(themeMode: ThemeMode.light)],
      verify: (_) {
        verify(
          () => mockRepository.setThemeMode(themeMode: 'light'),
        ).called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      '[EDGE CASE] - GIVEN ThemeMode.system, WHEN setThemeMode is called, THEN should persist "light" (non-dark fallback) and emit the system state',
      build: () {
        when(
          () => mockRepository.setThemeMode(themeMode: 'light'),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.setThemeMode(ThemeMode.system),
      expect: () => [const ThemeState.initial(themeMode: ThemeMode.system)],
      verify: (_) {
        verify(
          () => mockRepository.setThemeMode(themeMode: 'light'),
        ).called(1);
      },
    );
  });
}
