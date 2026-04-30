import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/core/language/cubit/language_cubit.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/language_interceptor.dart';

// MARK: - DUMMY DATA

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockLanguageInterceptor extends Mock implements LanguageInterceptor {}

const dummyLocaleEs = Locale('es');
const dummyLocaleEn = Locale('en');

// MARK: - TEST CASES

void main() {
  late MockAppSettingsRepository mockRepository;
  late MockLanguageInterceptor mockInterceptor;
  late LanguageCubit cubit;

  setUp(() {
    mockRepository = MockAppSettingsRepository();
    mockInterceptor = MockLanguageInterceptor();
    cubit = LanguageCubit(
      locale: dummyLocaleEs,
      appSettingsRepository: mockRepository,
      interceptor: mockInterceptor,
    );
  });

  tearDown(() {
    cubit.close();
  });

  // ---------------------------------------------------------------------------
  // initial state
  // ---------------------------------------------------------------------------

  group('LanguageCubit - initial state', () {
    test(
      '[STATE UPDATE] - GIVEN a locale, WHEN the cubit is created, THEN the initial state should reflect that locale',
      () {
        expect(cubit.state, const LanguageState.initial(locale: dummyLocaleEs));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // changeLocale
  // ---------------------------------------------------------------------------

  group('LanguageCubit.changeLocale', () {
    blocTest<LanguageCubit, LanguageState>(
      '[HAPPY PATH] - GIVEN a new locale, WHEN changeLocale is called, THEN should persist the language code, update the interceptor, and emit the new state',
      build: () {
        when(
          () => mockRepository.setLanguageCode(
            languageCode: dummyLocaleEn.languageCode,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockInterceptor.updateLanguageCode(
            dummyLocaleEn.languageCode,
          ),
        ).thenReturn(null);
        return cubit;
      },
      act: (c) => c.changeLocale(dummyLocaleEn),
      expect: () => [const LanguageState.initial(locale: dummyLocaleEn)],
      verify: (_) {
        verify(
          () => mockRepository.setLanguageCode(
            languageCode: dummyLocaleEn.languageCode,
          ),
        ).called(1);
        verify(
          () => mockInterceptor.updateLanguageCode(
            dummyLocaleEn.languageCode,
          ),
        ).called(1);
      },
    );

    blocTest<LanguageCubit, LanguageState>(
      '[HAPPY PATH] - GIVEN the same locale already set, WHEN changeLocale is called, THEN should still persist and emit the state',
      build: () {
        when(
          () => mockRepository.setLanguageCode(
            languageCode: dummyLocaleEs.languageCode,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockInterceptor.updateLanguageCode(
            dummyLocaleEs.languageCode,
          ),
        ).thenReturn(null);
        return cubit;
      },
      act: (c) => c.changeLocale(dummyLocaleEs),
      expect: () => [const LanguageState.initial(locale: dummyLocaleEs)],
    );
  });
}
