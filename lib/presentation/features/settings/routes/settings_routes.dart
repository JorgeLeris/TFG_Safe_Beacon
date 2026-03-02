import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/features/settings/screens/settings_screen.dart';

part 'settings_routes.g.dart';

/// Settings feature routes
///
/// Routes related to the settings screen of the application.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
