import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository class for managing application settings using [SharedPreferences].
class AppSettingsRepository {
  AppSettingsRepository({required SharedPreferences storage})
    : _storage = storage;

  final SharedPreferences _storage;

  @visibleForTesting
  static const languageCodeKey = 'languageCode';

  @visibleForTesting
  static const themeModeKey = 'themeMode';

  // MARK: Language

  /// Persists the given [languageCode] in preferences.
  Future<void> setLanguageCode({required String languageCode}) async {
    await _storage.setString(languageCodeKey, languageCode);
  }

  /// Returns the previously stored language code, or `null` if none is saved.
  Future<String?> getLanguageCode() async {
    return _storage.getString(languageCodeKey);
  }

  // MARK: Theme

  /// Persists the given [themeMode]. Accepted values: `'light'`, `'dark'`.
  Future<void> setThemeMode({required String themeMode}) async {
    await _storage.setString(themeModeKey, themeMode);
  }

  /// Returns the previously stored theme mode (`'light'` or `'dark'`),
  /// or `null` if the user has not set a preference yet (use system default).
  Future<String?> getThemeMode() async {
    return _storage.getString(themeModeKey);
  }
}
