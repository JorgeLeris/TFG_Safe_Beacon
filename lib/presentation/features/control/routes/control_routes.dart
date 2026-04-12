import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/control/providers/alert_detail_provider.dart';
import 'package:safe_beacon/presentation/features/control/providers/control_provider.dart';
import 'package:safe_beacon/presentation/features/control/screens/alert_detail_screen.dart';
import 'package:safe_beacon/presentation/features/control/screens/control_screen.dart';
import 'package:safe_beacon/presentation/features/control/screens/follow_up_detail_screen.dart';

part 'control_routes.g.dart';

/// Control feature routes
///
/// Routes related to user control panel.
@TypedGoRoute<ControlRoute>(path: '/control')
class ControlRoute extends GoRouteData with $ControlRoute {
  const ControlRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ControlProvider(child: ControlScreen());
}

@TypedGoRoute<AlertDetailRoute>(path: '/alert-detail/:alertId')
class AlertDetailRoute extends GoRouteData with $AlertDetailRoute {
  const AlertDetailRoute({required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AlertDetailProvider(alertId: alertId, child: const AlertDetailScreen());
}

/// TODO: Change the route to include follow-up id when service is ready.
@TypedGoRoute<FollowUpDetailRoute>(path: '/follow-up-detail')
class FollowUpDetailRoute extends GoRouteData with $FollowUpDetailRoute {
  const FollowUpDetailRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FollowUpDetailScreen();
}
