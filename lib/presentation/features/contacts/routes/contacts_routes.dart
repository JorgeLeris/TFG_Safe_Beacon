import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/contacts/screens/trusted_contacts_screen.dart';

part 'contacts_routes.g.dart';

/// Contacts feature routes
///
/// Routes related to the trusted contacts screen.
@TypedGoRoute<TrustedContactsRoute>(path: '/trusted-contacts')
class TrustedContactsRoute extends GoRouteData with $TrustedContactsRoute {
  const TrustedContactsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TrustedContactsScreen();
}
