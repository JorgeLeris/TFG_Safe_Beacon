import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/panic_button/screens/panic_button_screen.dart';

part 'panic_button_routes.g.dart';

/// Panic feature routes
///
/// Routes related to the panic button screen of the application.
@TypedGoRoute<PanicButtonRoute>(path: '/panic-button')
class PanicButtonRoute extends GoRouteData with $PanicButtonRoute {
  const PanicButtonRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PanicButtonScreen();
}
