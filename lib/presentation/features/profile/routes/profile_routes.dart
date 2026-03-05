import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/profile/screens/edit_profile_screen.dart';
import 'package:safe_beacon/presentation/features/profile/screens/profile_screen.dart';

part 'profile_routes.g.dart';

/// Profile feature routes
///
/// Routes related to user profile and settings.
@TypedGoRoute<ProfileRoute>(
  path: '/profile',
  routes: [
    // /profile/edit
    TypedGoRoute<ProfileEditRoute>(path: 'edit'),
  ],
)
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}

class ProfileEditRoute extends GoRouteData with $ProfileEditRoute {
  const ProfileEditRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EditProfileScreen();
}
