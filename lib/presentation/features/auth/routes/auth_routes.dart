import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/auth/screens/login_screen.dart';
import 'package:safe_beacon/presentation/features/auth/screens/register_screen.dart';

part 'auth_routes.g.dart';

/// Auth feature routes
///
/// Routes related to user auth.
@TypedGoRoute<AuthRoute>(
  path: '/auth',
  routes: [
    // /auth/register
    TypedGoRoute<RegisterRoute>(path: 'register'),
  ],
)
class AuthRoute extends GoRouteData with $AuthRoute {
  const AuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}

class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RegisterScreen();
}
