import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocProvider(
      create: (_) => RegisterCubit(isGoogleRegister: isGoogleRegister),
      child: child,
    );
  }
}
