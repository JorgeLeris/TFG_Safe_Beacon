import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/shared/screens/mock_selector_screen.dart';

part 'mock_routes.g.dart';

/// Mock selector routes
///
/// Routes for development, maintenance and demo purposes.
/// Only available when MOCK environment variable is set.
/// Access with: flutter run --dart-define=MOCK=true
@TypedGoRoute<MockSelectorRoute>(path: '/mock-selector')
class MockSelectorRoute extends GoRouteData with $MockSelectorRoute {
  const MockSelectorRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MockSelectorScreen();
  }
}
