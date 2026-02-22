import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/features/notifications/screens/notifications_screen.dart';

part 'notifications_routes.g.dart';

/// Notifications feature routes
///
/// Routes related to user notifications.
@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  const NotificationsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationsScreen();
}
