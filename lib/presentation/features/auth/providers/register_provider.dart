import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/auth_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/register_cubit.dart';

class RegisterProvider extends StatelessWidget {
  const RegisterProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(authApi: AuthApi()),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
      ],
      child: BlocProvider(
        create: (context) => RegisterCubit(
          authRepository: context.read<AuthRepository>(),
          userProfileRepository: context.read<UserProfileRepository>(),
        ),
        child: child,
      ),
    );
  }
}
