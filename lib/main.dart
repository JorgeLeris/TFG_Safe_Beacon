import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:safe_beacon/app/app.dart';
import 'package:safe_beacon/app/config/app_dependencies.dart';
import 'package:safe_beacon/app/config/environment.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/app/router/app_router.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/firebase_options.dart';
import 'package:safe_beacon/notification_service.dart';

Future<void> mainCommon(Environment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load environment variables
  await dotenv.load();

  // Check if the app was launched by tapping a notification (terminated state).
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  final initialAlertId = initialMessage?.data['alertId'] as String?;
  if (initialAlertId != null && initialAlertId.isNotEmpty) {
    NotificationService.setPendingInitialAlertId(initialAlertId);
  }

  // Build the app router with dependencies
  final router = buildAppRouter();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init(
    onNotificationTap: (alertId) => router.push('/alert-detail/$alertId'),
  );
  notificationService.listenToTokenRefresh((uid, token) async {
    await UserProfileRepositoryImpl(
      api: UserProfileApi(),
    ).saveFcmToken(uid, token);
  });
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

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
        child: SafeArea(
          left: false,
          right: false,
          top: false,
          child: App(router: router),
        ),
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

// Necessary for background message handling, must be a top-level function — runs in a separate isolate
// Terminated/Background: app is closed or in background
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  appLogger.info(
    'Background/terminated message received — running in separate isolate: ${message.messageId}',
  );
}
