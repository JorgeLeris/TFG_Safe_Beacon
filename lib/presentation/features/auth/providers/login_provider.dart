import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/auth_repository_imple.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/login_cubit.dart';

class LoginProvider extends StatelessWidget {
  const LoginProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(authApi: AuthApi()),
      child: BlocProvider(
        create: (context) =>
            LoginCubit(authRepository: context.read<AuthRepository>()),
        child: child,
      ),
    );
  }
}
