import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/home/providers/home_provider.dart';
import 'package:safe_beacon/presentation/features/home/screens/home_screen.dart';

part 'home_routes.g.dart';

/// Home feature routes
///
/// Routes related to the home screen of the application.
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HomeProvider(child: HomeScreen());
}
