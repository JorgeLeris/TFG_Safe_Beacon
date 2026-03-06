import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/login_cubit.dart';

class LoginProvider extends StatelessWidget {
  const LoginProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LoginCubit(), child: child);
  }
}
