import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/auth_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/logout_cubit.dart';

class ProfileProvider extends StatelessWidget {
  const ProfileProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(authApi: AuthApi()),
      child: BlocProvider(
        create: (context) =>
            LogoutCubit(authRepository: context.read<AuthRepository>()),
        child: child,
      ),
    );
  }
}
