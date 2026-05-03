import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MARK: - DUMMY DATA & MOCKS

class MockSharedPreferences extends Mock implements SharedPreferences {}

const dummyLanguageCode = 'es';
const dummyThemeMode = 'dark';

// MARK: - TEST CASES

void main() {
  late MockSharedPreferences mockStorage;
  late AppSettingsRepository repository;

  setUp(() {
    mockStorage = MockSharedPreferences();
    repository = AppSettingsRepository(storage: mockStorage);
  });

  // ---------------------------------------------------------------------------
  // setLanguageCode
  // ---------------------------------------------------------------------------

  group('AppSettingsRepository.setLanguageCode', () {
    test(
      '[HAPPY PATH] - GIVEN a language code, WHEN setLanguageCode is called, THEN should persist the value in storage',
      () async {
        // Arrange
        when(
          () => mockStorage.setString(
            AppSettingsRepository.languageCodeKey,
            dummyLanguageCode,
          ),
        ).thenAnswer((_) async => true);

        // Act
        await repository.setLanguageCode(languageCode: dummyLanguageCode);

        // Assert
        verify(
          () => mockStorage.setString(
            AppSettingsRepository.languageCodeKey,
            dummyLanguageCode,
          ),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getLanguageCode
  // ---------------------------------------------------------------------------

  group('AppSettingsRepository.getLanguageCode', () {
    test(
      '[HAPPY PATH] - GIVEN a stored language code, WHEN getLanguageCode is called, THEN should return the stored value',
      () async {
        // Arrange
        when(
          () => mockStorage.getString(AppSettingsRepository.languageCodeKey),
        ).thenReturn(dummyLanguageCode);

        // Act
        final result = await repository.getLanguageCode();

        // Assert
        expect(result, dummyLanguageCode);
      },
    );

    test(
      '[EDGE CASE] - GIVEN no stored language code, WHEN getLanguageCode is called, THEN should return null',
      () async {
        // Arrange
        when(
          () => mockStorage.getString(AppSettingsRepository.languageCodeKey),
        ).thenReturn(null);

        // Act
        final result = await repository.getLanguageCode();

        // Assert
        expect(result, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // setThemeMode
  // ---------------------------------------------------------------------------

  group('AppSettingsRepository.setThemeMode', () {
    test(
      '[HAPPY PATH] - GIVEN a theme mode, WHEN setThemeMode is called, THEN should persist the value in storage',
      () async {
        // Arrange
        when(
          () => mockStorage.setString(
            AppSettingsRepository.themeModeKey,
            dummyThemeMode,
          ),
        ).thenAnswer((_) async => true);

        // Act
        await repository.setThemeMode(themeMode: dummyThemeMode);

        // Assert
        verify(
          () => mockStorage.setString(
            AppSettingsRepository.themeModeKey,
            dummyThemeMode,
          ),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getThemeMode
  // ---------------------------------------------------------------------------

  group('AppSettingsRepository.getThemeMode', () {
    test(
      '[HAPPY PATH] - GIVEN a stored theme mode, WHEN getThemeMode is called, THEN should return the stored value',
      () async {
        // Arrange
        when(
          () => mockStorage.getString(AppSettingsRepository.themeModeKey),
        ).thenReturn(dummyThemeMode);

        // Act
        final result = await repository.getThemeMode();

        // Assert
        expect(result, dummyThemeMode);
      },
    );

    test(
      '[EDGE CASE] - GIVEN no stored theme mode, WHEN getThemeMode is called, THEN should return null',
      () async {
        // Arrange
        when(
          () => mockStorage.getString(AppSettingsRepository.themeModeKey),
        ).thenReturn(null);

        // Act
        final result = await repository.getThemeMode();

        // Assert
        expect(result, isNull);
      },
    );
  });
}
