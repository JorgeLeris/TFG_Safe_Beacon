import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/app/monitoring/app_bloc_observer.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/core/theme/theme.dart';

class App extends StatelessWidget {
  final GoRouter router;

  const App({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    setupLogging();
    Bloc.observer = const AppBlocObserver();

    return MaterialApp.router(
      title: 'safe_beacon',
      theme: buildTheme(),
      darkTheme: buildTheme(brightness: Brightness.dark),
      themeMode: context.select((ThemeCubit cubit) => cubit.state.themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: context.select((LanguageCubit cubit) => cubit.state.locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: const bool.fromEnvironment('MOCK')
          ? (context, child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () => router.push('/mock-selector'),
                child: child,
              );
            }
          : null,
    );
  }
}
