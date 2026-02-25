import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/features/control/screens/control_screen.dart';

part 'control_routes.g.dart';

/// Control feature routes
///
/// Routes related to user control panel.
@TypedGoRoute<ControlRoute>(path: '/control')
class ControlRoute extends GoRouteData with $ControlRoute {
  const ControlRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ControlScreen();
}
