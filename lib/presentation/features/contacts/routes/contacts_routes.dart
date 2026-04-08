import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/presentation/features/contacts/providers/protected_people_provider.dart';
import 'package:safe_beacon/presentation/features/contacts/providers/trusted_contacts_provider.dart';
import 'package:safe_beacon/presentation/features/contacts/screens/protected_people_screen.dart';
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
      const TrustedContactsProvider(child: TrustedContactsScreen());
}

/// Contacts feature routes
///
/// Routes related to the protected people screens.
@TypedGoRoute<ProtectedPeopleRoute>(path: '/protected-people')
class ProtectedPeopleRoute extends GoRouteData with $ProtectedPeopleRoute {
  const ProtectedPeopleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProtectedPeopleProvider(child: ProtectedPeopleScreen());
}
