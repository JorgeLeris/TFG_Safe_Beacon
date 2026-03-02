import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/app/monitoring/app_bloc_observer.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/app/router/app_router.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/core/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter();

    setupLogging();
    Bloc.observer = const AppBlocObserver();

    return MaterialApp.router(
      title: 'safe_beacon',
      theme: buildTheme(),
      darkTheme: buildTheme(brightness: Brightness.dark),
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
