import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/app/config/app_dependencies.dart';

/// EJEMPLO: Provider complejo con múltiples repositorios y blocs
///
/// Este es un ejemplo de cómo estructurar un provider para una feature compleja
/// que requiere múltiples repositorios, servicios y blocs.
class ExampleComplexProvider extends StatelessWidget {
  const ExampleComplexProvider({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 1. Obtener dependencias globales
    // ignore: unused_local_variable
    final appDeps = context.read<AppDependencies>();

    // 2. Crear múltiples repositorios si es necesario
    return MultiRepositoryProvider(
      providers: [
        // Repositorio 1
        // RepositoryProvider<UserRepository>(
        //   create: (_) => UserRepositoryImpl(appDeps.dio),
        // ),

        // Repositorio 2
        // RepositoryProvider<ProductRepository>(
        //   create: (_) => ProductRepositoryImpl(appDeps.dio),
        // ),

        // Servicio específico de la feature (no es un repositorio)
        // RepositoryProvider<CartService>(
        //   create: (_) => CartService(),
        // ),
      ],

      // 3. Crear múltiples blocs/cubits si es necesario
      child: MultiBlocProvider(
        providers: [
          // Bloc 1 - depende de un repositorio
          // BlocProvider(
          //   create: (context) => UserCubit(
          //     context.read<UserRepository>(),
          //   ),
          // ),

          // Bloc 2 - depende de múltiples repositorios
          // BlocProvider(
          //   create: (context) => CartCubit(
          //     context.read<ProductRepository>(),
          //     context.read<CartService>(),
          //     appDeps.logger,
          //   ),
          // ),

          // Bloc 3 - depende de otros blocs (menos común, úsalo con cuidado)
          // BlocProvider(
          //   create: (context) => CheckoutCubit(
          //     context.read<CartCubit>(),
          //     context.read<UserCubit>(),
          //   ),
          // ),
        ],
        child: child,
      ),
    );
  }
}

/// EJEMPLO: Provider con inicialización asíncrona
///
/// Si necesitas inicializar algo de forma asíncrona antes de mostrar la UI,
/// puedes usar un FutureBuilder o StreamBuilder dentro del provider.
class ExampleAsyncProvider extends StatelessWidget {
  const ExampleAsyncProvider({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // future: _loadUserToken(), // Por ejemplo, cargar token del storage
      future: Future.value('mock-token'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final token = snapshot.data;

        return RepositoryProvider<String>.value(
          value: token!,
          // child: RepositoryProvider<AuthenticatedUserRepository>(
          //   create: (_) => AuthenticatedUserRepositoryImpl(
          //     appDeps.dio,
          //     token: token,
          //   ),
          //   child: BlocProvider(
          //     create: (context) => ProfileCubit(
          //       context.read<AuthenticatedUserRepository>(),
          //     ),
          //     child: child,
          //   ),
          // ),
          child: child,
        );
      },
    );
  }
}
