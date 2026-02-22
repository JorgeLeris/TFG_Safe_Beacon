# Router Structure

## Organización de Rutas

Este proyecto organiza las rutas usando `go_router_builder` con una estructura dividida por features.

### Ventajas de esta Estructura

1. **Cohesión por Feature**: Cada feature contiene todo su código relacionado
   - Screens
   - Providers
   - Cubits/Blocs
   - Routes ← nuevo

2. **Fácil de Encontrar**: Sabes exactamente dónde buscar las rutas de cada feature

3. **Escalable**: Añadir una nueva feature es simple y no afecta otras

4. **Independencia**: Puedes mover/eliminar una feature completa fácilmente

### Jerarquía de Navegación

```
DashboardShell (Bottom Navigation)
├── Home Branch (/home)
│   └── HomeRoute
├── Search Branch (/search)
│   └── SearchRoute
├── Notifications Branch (/notifications)
│   └── NotificationsRoute
└── Profile Branch (/profile)
    └── ProfileRoute
```

### Ejemplo: Estructura Completa de una Feature

```
lib/presentation/features/home/
├── routes/
│   ├── home_routes.dart      ← Definición de rutas
│   └── home_routes.g.dart    ← Generado por build_runner
├── providers/
│   └── home_provider.dart    ← DI específica
├── cubit/
│   ├── home_cubit.dart       ← Lógica de negocio
│   └── home_state.dart
├── screens/
│   └── home_screen.dart      ← UI principal
└── widgets/
    └── weather_section.dart  ← Widgets reutilizables
```

### Cómo Añadir una Nueva Ruta

#### 1. Crear el archivo de rutas dentro de la feature

```dart
// lib/presentation/features/settings/routes/settings_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dena/presentation/features/settings/screens/settings_screen.dart';

part 'settings_routes.g.dart';

/// Settings feature routes
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
```

#### 2. Importar en app_router.dart

```dart
import 'package:dena/presentation/features/settings/routes/settings_routes.dart';
```

#### 3. Si es una ruta de nivel raíz (fuera del shell), añadirla al router

Si tu ruta está **fuera del shell** (no es parte del bottom navigation), agrégala manualmente:

```dart
GoRouter buildAppRouter() => GoRouter(
  routes: [
    ...$appRoutes, // Incluye automáticamente el shell y sus branches
    // Añadir rutas adicionales fuera del shell aquí
  ],
  initialLocation: HomeBranch.$initialLocation,
);
```

**Nota**: Las rutas que defines dentro de los `branches` del `@TypedStatefulShellRoute` se incluyen automáticamente en `$appRoutes`. Solo necesitas agregar manualmente rutas que estén completamente fuera del shell.

#### 4. Regenerar el código

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Navegación Programática

Con `go_router_builder` siempre usa navegación tipo seguro:

```dart
// Navegar reemplazando toda la pila (go)
HomeRoute().go(context);
SearchRoute().go(context);

// Navegar añadiendo a la pila (push)
ProfileRoute().push(context);
```

### Rutas Anidadas

#### Rutas anidadas dentro de un branch del Shell

Si quieres agregar sub-rutas dentro de una sección del shell (ej: detalles dentro de Home):

**Define las sub-rutas en `home_routes.dart`** (recomendado):

```dart
// home_routes.dart
@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [  // <-- Define sub-rutas aquí
    TypedGoRoute<HomeDetailRoute>(path: 'detail/:id'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

// Sub-ruta en el mismo archivo
class HomeDetailRoute extends GoRouteData with $HomeDetailRoute {
  const HomeDetailRoute({required this.id});
  
  final String id;
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      HomeDetailScreen(id: id);
  // Ruta resultante: /home/detail/:id
}
```

**En `app_router.dart` NO necesitas cambiar nada:**
```dart
TypedStatefulShellBranch<HomeBranch>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),  // Ya incluye las sub-rutas
  ],
),
```

**Nota importante**: El `@TypedGoRoute` en `home_routes.dart` define la ruta completa con sus sub-rutas. El `TypedGoRoute` en `app_router.dart` solo **referencia** esa ruta para incluirla en el branch.

#### Rutas anidadas fuera del Shell

Ejemplo con sub-rutas en una feature independiente:

```dart
// lib/presentation/features/settings/routes/settings_routes.dart
@TypedGoRoute<SettingsRoute>(
  path: '/settings',
  routes: [
    TypedGoRoute<AccountSettingsRoute>(path: 'account'),
    TypedGoRoute<PrivacySettingsRoute>(path: 'privacy'),
  ],
)
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

class AccountSettingsRoute extends GoRouteData with $AccountSettingsRoute {
  const AccountSettingsRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AccountSettingsScreen();
  // Ruta: /settings/account
}
```

**Navegación:**

```dart
ListTile(
  title: const Text('Account Settings'),
  onTap: () => const AccountSettingsRoute().push(context),
),
```

### Rutas con Parámetros

```dart
@TypedGoRoute<UserDetailRoute>(path: '/user/:id')
class UserDetailRoute extends GoRouteData with $UserDetailRoute {
  const UserDetailRoute({required this.id});
  
  final String id;
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UserDetailScreen(userId: id);
}

// Uso:
UserDetailRoute(id: '123').go(context);
```

### Query Parameters (Parámetros Opcionales)

```dart
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute({this.query, this.category});
  
  final String? query;
  final String? category;
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SearchScreen(query: query, category: category);
}

// Uso:
SearchRoute(query: 'flutter', category: 'mobile').go(context);
// Ruta: /search?query=flutter&category=mobile
```

### Return Values

Puedes obtener valores de retorno al hacer pop de una ruta:

```dart
// Push y esperar un valor de retorno
final bool? result = await ProfileRoute().push<bool>(context);

if (result != null) {
  // Procesar el resultado
}
```

### Custom Transitions

Para transiciones personalizadas, sobrescribe `buildPage`:

```dart
class FancyRoute extends GoRouteData with $FancyRoute {
  const FancyRoute();
  
  @override
  CustomTransitionPage<void> buildPage(
    BuildContext context,
    GoRouterState state,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const MyPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
```

### Mejores Prácticas

✅ **DO:**
- Mantén las rutas dentro de cada feature
- Usa nombres descriptivos para las clases de rutas
- Documenta el propósito de cada ruta
- Usa navegación tipo seguro
- Agrupa rutas relacionadas en el mismo archivo
- Siempre usa el mixin generado `with $RouteName` en cada ruta

❌ **DON'T:**
- No mezcles rutas de diferentes features en un archivo
- No uses strings mágicos para navegación
- No dupliques paths de rutas
- No olvides regenerar después de cambios

### Shell Routes vs Rutas Regulares

**Shell Routes** (con bottom navigation):
```dart
@TypedStatefulShellRoute<DashboardShellRoute>(
  branches: [
    TypedStatefulShellBranch<HomeBranch>(
      routes: [TypedGoRoute<HomeRoute>(path: '/home')],
    ),
  ],
)
class DashboardShellRoute extends StatefulShellRouteData {
  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return DashboardShell(navigationShell: navigationShell);
  }
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
  static const String $initialLocation = '/home';
}
```
- Se definen en `app_router.dart`
- Mantienen el estado entre navegaciones
- Ideal para tabs principales con bottom navigation

**Regular Routes** (pantalla completa):
- Se definen en archivos de feature (`feature/routes/feature_routes.dart`)
- Reemplazan toda la pantalla
- Ideal para detalles, formularios, modals
- Ejemplo: todas las rutas en `home_routes.dart`, `profile_routes.dart`, etc.

### Debugging

Si encuentras errores:

1. **"Target of URI hasn't been generated"**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **"Undefined class"**
   - Verifica los imports en `app_router.dart`
   - Asegúrate de que el archivo `.g.dart` existe

3. **Navegación no funciona**
   - Verifica que el path no tenga typos
   - Revisa que la ruta esté incluida en `$appRoutes`
