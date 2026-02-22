import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safe_beacon/app/config/environment.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/language_interceptor.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/mock_interceptor.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';
import 'package:safe_beacon/data/sources/remote/http/dio_client.dart';

/// This class should only include truly global dependencies such as:
/// - Logger
/// - HTTP Client (Dio)
/// - SharedPreferences
/// - AppSettingsRepository
/// - LanguageInterceptor
/// - Analytics
/// - Auth/Session
/// - Environment Config
/// APIs or feature-specific repositories should NOT be here.
class AppDependencies {
  AppDependencies._({
    required this.environment,
    required this.logger,
    required this.dio,
    required this.sharedPreferences,
    required this.appSettingsRepository,
    required this.languageInterceptor,
  });

  final Environment environment;
  final Logger logger;
  final Dio dio;
  final SharedPreferences sharedPreferences;
  final AppSettingsRepository appSettingsRepository;
  final LanguageInterceptor languageInterceptor;

  /// Initialize all global dependencies of the application
  static Future<AppDependencies> initialize(Environment environment) async {
    // Logger
    final logger = Logger('app');

    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();

    // AppSettingsRepository
    final appSettingsRepository = AppSettingsRepository(
      storage: sharedPreferences,
    );

    // Get saved language or use default
    final savedLanguage = await appSettingsRepository.getLanguageCode();
    final languageCode = savedLanguage ?? defaultAppLanguage;

    // LanguageInterceptor
    final languageInterceptor = LanguageInterceptor(
      languageCode: languageCode,
      validateLanguageCode: (languageCode) {
        if (languageCode == localeValencianApi) {
          return true;
        }
        return AppLocalizations.supportedLocales.any(
          (element) => element.languageCode == languageCode,
        );
      },
    );

    // Dio HTTP client (with interceptors)
    final dio = buildDio(environment);
    dio.interceptors.addAll([
      languageInterceptor,
      if (const bool.fromEnvironment('MOCK')) const MockInterceptor(),
    ]);

    return AppDependencies._(
      environment: environment,
      logger: logger,
      dio: dio,
      sharedPreferences: sharedPreferences,
      appSettingsRepository: appSettingsRepository,
      languageInterceptor: languageInterceptor,
    );
  }
}
