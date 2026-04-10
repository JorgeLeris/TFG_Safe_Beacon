import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/screens/guardian_mode_screen.dart';

part 'guardian_mode_routes.g.dart';

/// Guardian mode feature routes
///
/// Routes related to the guardian mode screen of the application.
@TypedGoRoute<GuardianModeRoute>(path: '/guardian-mode')
class GuardianModeRoute extends GoRouteData with $GuardianModeRoute {
  const GuardianModeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const GuardianModeScreen();
}
