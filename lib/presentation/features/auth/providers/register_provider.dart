import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/auth_repository_imple.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/register_cubit.dart';

class RegisterProvider extends StatelessWidget {
  const RegisterProvider({
    required this.child,
    this.isGoogleRegister = false,
    super.key,
  });

  final Widget child;
  final bool isGoogleRegister;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(authApi: AuthApi()),
      child: BlocProvider(
        create: (context) => RegisterCubit(
          authRepository: context.read<AuthRepository>(),
          isGoogleRegister: isGoogleRegister,
        ),
        child: child,
      ),
    );
  }
}
