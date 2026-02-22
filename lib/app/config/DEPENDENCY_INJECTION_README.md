# Dependency Injection Pattern

Este proyecto utiliza un patrón de inyección de dependencias manual basado en `RepositoryProvider` y `BlocProvider` de Flutter Bloc, evitando service locators globales para mantener la arquitectura más comprensible y explícita.

## Estructura

### 1. Dependencias Globales (`AppDependencies`)

Las dependencias globales (logger, http client, shared preferences, language, analytics, auth/session, config) se inicializan en `main.dart` y se proporcionan a través de `MultiRepositoryProvider` y `BlocProvider` en la raíz de la aplicación.

```dart
// lib/app/config/app_dependencies.dart
class AppDependencies {
  final Environment environment;
  final Logger logger;
  final Dio dio;
  final SharedPreferences sharedPreferences;
  final AppSettingsRepository appSettingsRepository;
  final LanguageInterceptor languageInterceptor;
  
  static Future<AppDependencies> initialize(Environment environment) async {
    // Inicialización de servicios globales
  }
}
```

**Servicios Globales:**
- `Environment`: Configuración del entorno (dev/pre/prod)
- `Logger`: Sistema de logging de la aplicación
- `Dio`: Cliente HTTP configurado
- `SharedPreferences`: Almacenamiento local
- `AppSettingsRepository`: Gestión de configuración de la app
- `LanguageInterceptor`: Interceptor para añadir idioma a las peticiones

**Blocs/Cubits Globales:**
- `LanguageCubit`: Gestión del idioma de la aplicación (disponible en toda la app)

### 2. Providers por Feature

Cada feature tiene su propia carpeta `providers/` que contiene la lógica de inyección de dependencias específica de esa feature.

```
lib/presentation/features/
  home/
    cubit/
      home_cubit.dart
    providers/
      home_provider.dart  ← Provider específico de la feature
    screens/
      home_screen.dart
    widgets/
```

**Ejemplo: HomeProvider**
```dart
class HomeProvider extends StatelessWidget {
  const HomeProvider({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 1. Obtener dependencias globales
    final appDeps = context.read<AppDependencies>();

    // 2. Crear API específico de la feature
    final weatherApi = WeatherApi(
      appDeps.dio,
      baseUrl: appDeps.environment.weatherBaseUrl,
    );

    // 3. Crear repositorios de la feature
    return RepositoryProvider<WeatherRepository>(
      create: (_) => WeatherRepositoryImpl(weatherApi),
      
      // 4. Crear cubits/blocs de la feature
      child: BlocProvider(
        create: (context) => HomeCubit(context.read<WeatherRepository>()),
        child: child,
      ),
    );
  }
}
```

### 3. Uso en Screens

Las screens simplemente envuelven su contenido con el provider de la feature:

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeProvider(
      child: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const WeatherSection(),
      ),
    );
  }
}
```

## Ventajas de este patrón

1. **Claridad**: Es evidente qué dependencias usa cada feature
2. **Scope explícito**: Las dependencias viven solo mientras la feature está activa
3. **Testing simplificado**: Fácil mockear dependencias por feature
4. **Sin service locator global**: No hay "magia" ni dependencias ocultas
5. **Consistencia**: Patrón uniforme en todo el proyecto

## Acceso a dependencias globales

En cualquier widget que esté dentro del árbol de la app:

```dart
// Acceder al environment
final env = context.read<Environment>();

// Acceder al logger
final logger = context.read<Logger>();

// Acceder al Dio client (si necesitas hacer llamadas HTTP directas)
final dio = context.read<Dio>();

// Acceder a todas las dependencias
final appDeps = context.read<AppDependencies>();
```
