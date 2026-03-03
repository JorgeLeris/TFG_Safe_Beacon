import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/auth/screens/login_screen.dart';

part 'auth_routes.g.dart';

/// Auth feature routes
///
/// Routes related to user auth.
@TypedGoRoute<AuthRoute>(path: '/login')
class AuthRoute extends GoRouteData with $AuthRoute {
  const AuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}
