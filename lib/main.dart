import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/app/app.dart';
import 'package:safe_beacon/app/config/app_dependencies.dart';
import 'package:safe_beacon/app/config/environment.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';
import 'package:safe_beacon/firebase_options.dart';

Future<void> mainCommon(Environment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize global dependencies
  final appDeps = await AppDependencies.initialize(environment);

  // Get initial locale (saved, device, or default)
  final locale = await _getInitialAppLocale(appDeps.appSettingsRepository);

  // Set up logging
  setupLogging();

  // Run the app with global dependencies
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: appDeps),
        RepositoryProvider.value(value: appDeps.environment),
        RepositoryProvider.value(value: appDeps.logger),
        RepositoryProvider.value(value: appDeps.dio),
        RepositoryProvider.value(value: appDeps.sharedPreferences),
        RepositoryProvider.value(value: appDeps.appSettingsRepository),
      ],
      child: BlocProvider(
        create: (_) => LanguageCubit(
          locale: locale,
          appSettingsRepository: appDeps.appSettingsRepository,
          interceptor: appDeps.languageInterceptor,
        ),
        child: const App(),
      ),
    ),
  );
}

Future<Locale> _getInitialAppLocale(
  AppSettingsRepository settingsRepository,
) async {
  String appLanguage;
  // Get the previously saved locale or use the device locale
  appLanguage =
      (await settingsRepository.getLanguageCode()) ??
      Platform.localeName.substring(0, 2);

  // if there is not a previously saved local and [Platform.localeName] is not
  // a valid locale, use [es] as default
  if (!AppLocalizations.supportedLocales.any(
    (element) => element.languageCode == appLanguage,
  )) {
    appLanguage = defaultAppLanguage;
  }

  return Locale.fromSubtags(languageCode: appLanguage);
}
