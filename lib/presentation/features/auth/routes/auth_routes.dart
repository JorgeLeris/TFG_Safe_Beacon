import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/auth/providers/login_provider.dart';
import 'package:safe_beacon/presentation/features/auth/providers/register_provider.dart';
import 'package:safe_beacon/presentation/features/auth/screens/login_screen.dart';
import 'package:safe_beacon/presentation/features/auth/screens/register_add_data_screen.dart';
import 'package:safe_beacon/presentation/features/auth/screens/register_screen.dart';

part 'auth_routes.g.dart';

/// Auth feature routes
///
/// Routes related to user auth.
@TypedGoRoute<AuthRoute>(
  path: '/auth',
  routes: [
    TypedShellRoute<RegisterShellRoute>(
      routes: [
        TypedGoRoute<RegisterRoute>(
          path: 'register',
          routes: [TypedGoRoute<RegisterAddDataRoute>(path: 'register-data')],
        ),
      ],
    ),
    TypedGoRoute<GoogleRegisterRoute>(path: 'google-register'),
  ],
)
class AuthRoute extends GoRouteData with $AuthRoute {
  const AuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginProvider(child: LoginScreen());
}

/// Shell route for register flow, to provide the same RegisterCubit to all its routes
class RegisterShellRoute extends ShellRouteData {
  const RegisterShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      RegisterProvider(child: navigator);
}

class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RegisterScreen();
}

class RegisterAddDataRoute extends GoRouteData with $RegisterAddDataRoute {
  const RegisterAddDataRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RegisterAddDataScreen();
}

/// Independent route for Google register
class GoogleRegisterRoute extends GoRouteData with $GoogleRegisterRoute {
  const GoogleRegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RegisterProvider(
        isGoogleRegister: true,
        child: RegisterAddDataScreen(isGoogleRegister: true),
      );
}
