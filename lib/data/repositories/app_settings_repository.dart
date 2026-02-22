import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository class for managing application settings using
/// [SharedPreferences] and [FlutterSecureStorage].
class AppSettingsRepository {
  /// Creates an instance of [AppSettingsRepository] with the given
  /// [SharedPreferences] and [FlutterSecureStorage] storage.
  ///
  /// The [storage] and [secureStorage] parameters are required and are used
  /// to persist the settings.
  AppSettingsRepository({required SharedPreferences storage})
    : _storage = storage;

  /// The [SharedPreferences] instance used for storing the settings.
  final SharedPreferences _storage;

  /// The key used for storing the onboarding completion status.
  @visibleForTesting
  static const onboardingCompletedKey = 'onboardingCompleted';

  /// The key used for storing the terms acceptance status.
  @visibleForTesting
  static const termsAcceptedKey = 'termsAccepted';

  /// The key used for storing the language code.
  @visibleForTesting
  static const languageCodeKey = 'languageCode';

  /// Sets the onboarding completion status.
  ///
  /// The [isComplete] parameter indicates whether the onboarding is completed.
  Future<void> setOnboardingCompleted({required bool isComplete}) async {
    await _storage.setBool(onboardingCompletedKey, isComplete);
  }

  /// Gets the onboarding completion status.
  ///
  /// Returns a [Future] that completes with `true` if the onboarding is
  /// completed, otherwise `false`.
  Future<bool> getOnboardingCompleted() {
    return Future.value(_storage.getBool(onboardingCompletedKey) ?? false);
  }

  /// Sets the language code.
  ///
  /// The [languageCode] parameter indicates the language code to be set.
  Future<void> setLanguageCode({required String languageCode}) async {
    await _storage.setString(languageCodeKey, languageCode);
  }

  /// Gets the stored language code.
  ///
  /// Returns a [Future] that completes with the stored language code as a
  /// [String], or `null` if no language code is stored.
  Future<String?> getLanguageCode() async {
    return _storage.getString(languageCodeKey);
  }
}
