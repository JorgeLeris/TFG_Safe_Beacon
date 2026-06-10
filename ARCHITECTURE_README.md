# Arquitectura de la Aplicación

Este documento describe la arquitectura del proyecto y cómo trabajar sobre ella de forma consistente.

## Tabla de Contenidos

- [Estructura del Proyecto](#estructura-del-proyecto)
- [Arquitectura en Capas](#arquitectura-en-capas)
- [Flujo de Datos](#flujo-de-datos)
- [Documentación Específica](#documentación-específica)
- [Stack Tecnológico](#stack-tecnológico)
- [Guía de Desarrollo](#guía-de-desarrollo)

## Estructura del Proyecto

```
lib/
├── app/                          # Configuración global de la aplicación
│   ├── config/                   # Dependencias y configuración por entorno
│   │   ├── app_dependencies.dart # Contenedor de dependencias globales
│   │   ├── environment.dart      # Enum de entornos
│   │   └── DEPENDENCY_INJECTION_README.md
│   ├── monitoring/               # Observabilidad y logging
│   │   ├── app_bloc_observer.dart
│   │   └── logging.dart
│   ├── router/                   # Configuración de navegación
│   │   ├── app_router.dart       # Router principal
│   │   └── ROUTES_README.md
│   └── app.dart                  # Widget raíz de la aplicación
│
├── core/                         # Recursos compartidos
│   ├── assets/                   # Descriptores de recursos (imágenes, iconos, animaciones)
│   ├── constants/                # Constantes y endpoints
│   ├── extensions/               # Extensiones de tipos y contexto
│   ├── language/                 # Gestión de idiomas (cubit, localización)
│   └── theme/                    # Sistema de diseño (colores, tipografías, estilos)
│
├── domain/                       # Lógica de negocio pura
│   ├── common/                   # Tipos compartidos (Result, AppFailure)
│   └── {feature}/                # Entidades, repositorios (opcional) y casos de uso (opcional) por feature
│
├── data/                         # Acceso a datos
│   ├── datasources/              # [Opcional] Abstracciones de fuentes de datos
│   ├── repositories/             # Implementaciones de repositorios
│   └── sources/                  # Implementaciones concretas de fuentes de datos
│       ├── local/                # Datos locales (SharedPrefs, SQLite, Hive, etc.)
│       └── remote/               # Datos remotos (APIs REST, GraphQL, etc.)
│           ├── http/             # Configuración HTTP (Dio, interceptors, adapters)
│           └── {feature}/        # APIs y DTOs por feature
│
├── presentation/                 # Capa de UI
│   ├── features/                 # Features organizadas verticalmente
│   │   ├── {feature}/
│   │   │   ├── cubit/            # Lógica de presentación (estado)
│   │   │   ├── providers/        # DI específica de la feature
│   │   │   ├── routes/           # Rutas de la feature
│   │   │   ├── screens/          # Pantallas principales
│   │   │   └── widgets/          # Widgets reutilizables de la feature
│   │   └── dashboard/            # Shell navigation (bottom tabs)
│   └── shared/                   # Componentes compartidos entre features
│       └── screens/              # Pantallas compartidas
│       └── .../                  
│
├── main.dart                     # Entry point común (inicialización)
├── main_dev.dart                 # Entry point para desarrollo
├── main_pre.dart                 # Entry point para preproducción
└── main_prod.dart                # Entry point para producción
```

## Arquitectura en Capas

La aplicación sigue principios de **Clean Architecture** adaptados a Flutter, con separación clara de responsabilidades:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                           │
│  ┌───────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐              │
│  │  Screens  │→ │ Widgets │→ │  Cubit  │→ │ Provider │              │
│  └───────────┘  └─────────┘  └─────────┘  └──────────┘              │
└────────────────────────────┬────────────────────────────────────────┘
                             │ Result<T>
                             │ (Success<T> | Failure<AppFailure>)
┌────────────────────────────▼────────────────────────────────────────┐
│                          DOMAIN LAYER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐            │
│  │   Entities   │  │  Result<T>   │  │   AppFailure    │            │
│  └──────────────┘  └──────────────┘  └─────────────────┘            │
│  ┌───────────────────────────────────────────────────────┐          │
│  │       Repository Contracts (optional interfaces)      │          │
│  └───────────────────────────────────────────────────────┘          │
└────────────────────────────┬────────────────────────────────────────┘
                             │ implements
┌────────────────────────────▼────────────────────────────────────────┐
│                           DATA LAYER                                │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                      Repositories                            │   │
│  │  • Orchestrates multiple DataSources                         │   │
│  │  • Transforms DTO → Entity                                   │   │
│  │  • Returns Result<Entity>                                    │   │
│  └────────┬────────────────────────────────┬────────────────────┘   │
│           │                                │                        │
│    ┌──────▼──────────────┐       ┌─────────▼───────────────┐        │
│    │  Local DataSources  │       │  Remote DataSources     │        │
│    │                     │       │                         │        │
│    │ • Storage           │       │ • API Clients           │        │
│    │ • ...               │       │ • DTOs                  │        │
│    │                     │       │ • ...                   │        │
│    └─────────────────────┘       └─────────┬───────────────┘        │
│                                            │                        │
│                               ┌────────────▼─────────────┐          │
│                               │   Result Call Adapter    │          │
│                               │   (HTTP Error Handler)   │          │
│                               │  • Maps HTTP → Result<T> │          │
│                               │  • Maps Errors→Failures  │          │
│                               └────────────┬─────────────┘          │
└────────────────────────────────────────────┼────────────────────────┘
                                             │ HTTP Client
                                             │ (auth, logging, mock, ...)
                                             ▼
                                  External Systems
```

### Responsabilidades por Capa

#### **Presentation Layer**
- Renderizado de UI y gestión de eventos de usuario
- Estado local de la UI (formularios, animaciones, scroll)
- Transformación de datos de dominio a formato visual
- **No contiene lógica de negocio**

#### **Domain Layer**
- Entidades de negocio (modelos puros, sin dependencias de framework)
- Tipos de resultado (`Result<Success, Failure>`)
- Contratos de repositorios (interfaces)
- **No depende de capas externas**

#### **Data Layer**
- Implementación de repositorios
- Clientes HTTP con Retrofit/Dio o Firebase
- Transformación de DTOs a entidades de dominio
- Gestión de caché y persistencia local
- **Depende solo de Domain**

##### DataSources (Opcional)
Para features con múltiples fuentes de datos (API + cache, API + local storage) o cuando necesites cambiar implementaciones (ej: de SharedPreferences a Hive), puedes crear abstracciones de DataSources:

```
data/
├── datasources/                    # Abstracciones (interfaces)
│   ├── feature_remote_datasource.dart
│   └── feature_local_datasource.dart
└── sources/
    ├── local/
    │   └── feature_local_datasource_impl.dart
    └── remote/
        └── feature_remote_datasource_impl.dart
```

**Cuándo usar DataSources**:
- ✅ Feature necesita cache local + llamadas remotas
- ✅ Quieres poder cambiar la implementación de storage (SharedPrefs → Hive → SQLite)
- ✅ Necesitas testear Repository sin mockear Retrofit/Dio o Firebase

**Cuándo NO usarlos**:
- ❌ Feature solo hace llamadas remotas sin cache
- ❌ Implementación simple que no cambiará
- ❌ No necesitas tests aislados del cliente HTTP

Para features simples, el Repository puede usar directamente el API client sin abstracción intermedia.

## Flujo de Datos

### Flujo End-to-End de una Feature

```
1. USER ACTION
   └─> Screen captura evento (onTap, onSubmit, etc.)
   
2. CUBIT/BLOC
   └─> Valida input
   └─> Emite estado de loading
   └─> Llama al repository
   
3. REPOSITORY
   └─> Ejecuta llamada a API (Retrofit/Dio o Firebase)
   └─> Aplica interceptores (auth, language, logging, mock)
   └─> Transforma DTO → Entity
   └─> Retorna Result<Entity, AppFailure>
   
4. CUBIT/BLOC
   └─> Mapea Result a estado de presentación
   └─> Emite estado de success/error
   
5. SCREEN/WIDGET
   └─> Reacciona al cambio de estado (BlocBuilder/BlocListener)
   └─> Renderiza UI actualizada
```

### Manejo de Errores

Todos los errores se encapsulan en `Result<T, AppFailure>`:

```dart
sealed class AppFailure {
  network,           // Sin conectividad
  unauthorized,      // 401 - Token inválido
  forbidden,         // 403 - Sin permisos
  notFound,          // 404 - Recurso no existe
  conflict,          // 409 - Conflicto de datos
  serialization,     // Error parseando JSON
  server,            // 500+ Errores del servidor
  unknown            // Errores no clasificados
}
```

Los repositorios **siempre** retornan `Result`, nunca lanzan excepciones a la capa de presentación.

## Documentación Específica

### Inyección de Dependencias
📖 Ver [DEPENDENCY_INJECTION_README.md](lib/app/config/DEPENDENCY_INJECTION_README.md)

- Patrón manual con `RepositoryProvider` y `BlocProvider`
- Dependencias globales vs. dependencias por feature
- Testing y mocking de dependencias

### Navegación y Rutas
📖 Ver [ROUTES_README.md](lib/app/router/ROUTES_README.md)

- Configuración de `go_router` con type-safety
- Shell navigation (bottom tabs)
- Rutas anidadas y parámetros
- Deep links y navegación programática

### Testing
📖 Ver:
- [cubit_test_readme.md](test/presentation/cubit/cubit_test_readme.md) - Testing de Cubits/Blocs
- [repository_test_readme.md](test/data/repository/repository_test_readme.md) - Testing de Repositorios

## Stack Tecnológico

### Core Framework
- **Flutter SDK**: `>=3.8.0 <4.0.0`
- **Dart**: Null-safety habilitado

### State Management & Architecture
- **flutter_bloc** - Gestión de estado reactiva
- **bloc** - Lógica de negocio separada de UI

### Code Generation
- **freezed** - Clases inmutables y sealed unions
- **freezed_annotation** 
- **json_serializable** - Serialización JSON
- **build_runner** - Generación de código

### Networking
- **dio** - Cliente HTTP configurable

### Navigation
- **go_router** - Routing declarativo
- **go_router_builder** - Type-safe routes

### Local Storage
- **shared_preferences** - Persistencia key-value

### Internationalization
- **intl** - Formateo y localización
- **flutter_localizations** - Traducciones multi-idioma

### Development Tools
- **logger** - Logging estructurado
- **very_good_analysis** - Linting rules

### Testing
- **bloc_test** - Testing de Blocs/Cubits
- **mocktail** - Mocking moderno

## Guía de Desarrollo

### 1. Inicialización del Proyecto

```bash
# Obtener dependencias
flutter pub get

# Generar código (rutas, freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en modo desarrollo
flutter run lib/main_dev.dart

# O usar scripts helpers
./tools/run_dev.sh
./tools/run_pre.sh
./tools/run_prod.sh
```

### 2. Entornos de Ejecución

La aplicación soporta tres entornos configurables:

| Entorno | Entry Point | Uso |
|---------|-------------|-----|
| **Development** | `main_dev.dart` | Desarrollo local |
| **Pre-production** | `main_pre.dart` | Testing QA, staging APIs |
| **Production** | `main_prod.dart` | Release a usuarios finales |

Cada entorno define:
- Base URLs de APIs
- Nivel de logging
- Configuración de analytics
- Habilitación de debug tools

### 3. Crear una Nueva Feature

#### Paso 1: Estructura de carpetas

```bash
lib/presentation/features/mi_feature/
├── cubit/
│   ├── mi_feature_cubit.dart
│   └── mi_feature_state.dart
├── providers/
│   └── mi_feature_provider.dart
├── routes/
│   └── mi_feature_routes.dart
├── screens/
│   └── mi_feature_screen.dart
└── widgets/
    └── mi_feature_widget.dart
```

#### Paso 2: Definir entidades de dominio

```dart
// lib/domain/mi_feature/mi_entidad.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mi_entidad.freezed.dart';

@freezed
class MiEntidad with _$MiEntidad {
  const factory MiEntidad({
    required String id,
    required String nombre,
  }) = _MiEntidad;
}
```

#### Paso 3: Crear API client

```dart
// lib/data/sources/remote/mi_feature/mi_feature_api.dart
import 'package:dio/dio.dart';

part 'mi_feature_api.g.dart';

@RestApi()
abstract class MiFeatureApi {
  factory MiFeatureApi(Dio dio, {String baseUrl}) = _MiFeatureApi;

  @GET('/endpoint')
  Future<MiEntidadDto> obtenerDatos();
}
```

#### Paso 4: Implementar repositorio

```dart
// lib/data/repositories/mi_feature_repository_impl.dart
class MiFeatureRepositoryImpl implements MiFeatureRepository {
  final MiFeatureApi _api;

  MiFeatureRepositoryImpl(this._api);

  @override
  Future<Result<MiEntidad, AppFailure>> obtenerDatos() async {
    try {
      final dto = await _api.obtenerDatos();
      final entity = dto.toDomain();
      return Result.success(entity);
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    }
  }
}
```

#### Paso 5: Crear Cubit

```dart
// lib/presentation/features/mi_feature/cubit/mi_feature_cubit.dart
class MiFeatureCubit extends Cubit<MiFeatureState> {
  final MiFeatureRepository _repository;

  MiFeatureCubit(this._repository) : super(const MiFeatureState.initial());

  Future<void> cargarDatos() async {
    emit(const MiFeatureState.loading());
    
    final result = await _repository.obtenerDatos();
    
    result.when(
      success: (data) => emit(MiFeatureState.success(data)),
      failure: (error) => emit(MiFeatureState.error(error)),
    );
  }
}
```

#### Paso 6: Configurar Provider de la feature

```dart
// lib/presentation/features/mi_feature/providers/mi_feature_provider.dart
class MiFeatureProvider extends StatelessWidget {
  const MiFeatureProvider({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appDeps = context.read<AppDependencies>();

    final api = MiFeatureApi(
      appDeps.dio,
      baseUrl: appDeps.environment.miFeatureBaseUrl,
    );

    return RepositoryProvider<MiFeatureRepository>(
      create: (_) => MiFeatureRepositoryImpl(api),
      child: BlocProvider(
        create: (context) => MiFeatureCubit(
          context.read<MiFeatureRepository>(),
        ),
        child: child,
      ),
    );
  }
}
```

#### Paso 7: Crear Screen

```dart
// lib/presentation/features/mi_feature/screens/mi_feature_screen.dart
class MiFeatureScreen extends StatelessWidget {
  const MiFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MiFeatureProvider(
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi Feature')),
        body: BlocBuilder<MiFeatureCubit, MiFeatureState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const CircularProgressIndicator(),
              success: (data) => Text(data.nombre),
              error: (failure) => Text('Error: $failure'),
            );
          },
        ),
      ),
    );
  }
}
```

#### Paso 8: Definir rutas

```dart
// lib/presentation/features/mi_feature/routes/mi_feature_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/features/mi_feature/screens/mi_feature_screen.dart';

part 'mi_feature_routes.g.dart';

@TypedGoRoute<MiFeatureRoute>(path: '/mi-feature')
class MiFeatureRoute extends GoRouteData with $MiFeatureRoute {
  const MiFeatureRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MiFeatureScreen();
}
```

#### Paso 9: Registrar en app_router.dart

```dart
// lib/app/router/app_router.dart
import 'package:safe_beacon/presentation/features/mi_feature/routes/mi_feature_routes.dart';
```

#### Paso 10: Regenerar código

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Trabajar con Mocks

Para desarrollo y testing, la app soporta respuestas mockeadas:

```bash
# Ejecutar con mocks habilitados
flutter run --dart-define=MOCK=true lib/main_dev.dart

# Navegar a /mock-selector para seleccionar escenarios
# Disponible solo en modo MOCK
```

Los mocks se gestionan mediante:
- `MockInterceptor` - Intercepta peticiones HTTP y retorna JSONs locales
- `MockSelectorScreen` - UI para cambiar entre escenarios (ok/empty/error)
- Archivos JSON en `assets/mocks/`

### 5. Debugging y Observabilidad

#### Logging

```dart
// Uso del logger global
import 'package:safe_beacon/app/monitoring/logging.dart';

appLogger.info('Información general');
appLogger.warning('Advertencia');
appLogger.error('Error crítico', error: e, stackTrace: st);
appLogger.debug('Debug detallado');
```

#### BlocObserver

Todos los eventos de Blocs/Cubits se registran automáticamente:

```dart
// lib/app/monitoring/app_bloc_observer.dart
// Registra:
// - onCreate, onEvent, onChange, onTransition, onError, onClose
```

#### Navegación Global

Acceso al router desde cualquier parte sin context:

```dart
import 'package:safe_beacon/app/router/app_router.dart';

// Útil en interceptores, notificaciones push, deep links
final context = navigatorKey.currentContext;
if (context != null) {
  context.go('/login');
}
```

### 6. Buenas Prácticas

#### ✅ DO

- Mantener features auto-contenidas (vertical slicing)
- Usar `Result<T, AppFailure>` para todas las operaciones fallibles
- Validar inputs en el Cubit, no en el Repository
- Documentar clases y métodos públicos
- Escribir tests para lógica de negocio crítica
- Usar `freezed` para entidades de dominio y estados
- Seguir la convención de nombres: `snake_case` para archivos, `PascalCase` para clases
- Usar extensiones para lógica derivada (getters calculados)

#### ❌ DON'T

- No mezclar lógica de negocio en widgets
- No usar Singletons globales (usar DI con Providers)
- No hardcodear strings (usar `AppLocalizations`)
- No ignorar errores (siempre mapear a `AppFailure`)
- No crear dependencias circulares entre capas
- No exponer DTOs fuera de la capa Data
- No usar `BuildContext` fuera del árbol de widgets
- No compartir estado mutable entre features

### 7. Comandos Útiles

```bash
# Obtener dependencias
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Análisis estático
flutter analyze

# Formateo de código
dart format .

# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ver coverage (requiere lcov instalado)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Limpiar build
flutter clean

# Regenerar código sin confirmar (útil para resolver conflictos)
dart run build_runner build --delete-conflicting-outputs

# Build para release (Android)
flutter build apk --release --flavor prod -t lib/main_prod.dart

# Build para release (iOS)
flutter build ios --release --flavor prod -t lib/main_prod.dart
```

### 8. Solución de Problemas Comunes

#### Error: "Target of URI hasn't been generated"

**Causa**: Falta ejecutar `build_runner` después de añadir rutas.

**Solución**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### Error: "The getter 'read' isn't defined for the type 'BuildContext'"

**Causa**: Falta importar `flutter_bloc`.

**Solución**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
```

#### Error: Dependencia no disponible en el contexto

**Causa**: El widget no está dentro del árbol de providers.

**Solución**: Verifica que el `Provider` esté envolviendo el widget que intenta acceder a la dependencia.

#### Navegación no funciona

**Causa**: Ruta no registrada o typo en el path.

**Solución**: 
1. Verifica el import en `app_router.dart`
2. Confirma que la ruta está en `$appRoutes`
3. Regenera código con `build_runner`

---

**Última actualización**: 17 de noviembre de 2025
