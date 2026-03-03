import 'package:flutter/material.dart';
import 'package:safe_beacon/presentation/features/home/routes/home_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            const HomeRoute().go(context);
          },
          child: const Text('Ir al Dashboard'),
        ),
      ),
    );
  }
}