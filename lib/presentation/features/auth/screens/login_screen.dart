import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_beacon/presentation/features/home/routes/home_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/input_field_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // TODO: traducir

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.primary,
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(color: colorScheme.primary),
                  ),
                  Expanded(child: Container(color: colorScheme.tertiary)),
                ],
              ),

              Positioned(
                bottom: 15,
                right: 15,
                child: SvgPicture.asset(
                  'assets/images/login-image.svg',
                  height: 185,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 32, left: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 75),

                    Center(
                      child: Text(
                        'SafeBeacon',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondary,
                          fontSize: textTheme.headlineLarge!.fontSize! * 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const InputField(hint: 'Correo electrónico'),
                    const SizedBox(height: 24),
                    const InputField(hint: 'Contraseña', isPassword: true),

                    const SizedBox(height: 12),

                    Text(
                      '¿Has olvidado tu contraseña?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          const HomeRoute().go(context);
                        },
                        child: Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: textTheme.labelLarge!.fontSize! * 1.2,
                            color: colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                          text: '¿No tienes cuenta? ',
                          children: const [
                            TextSpan(
                              text: 'Regístrate aquí',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.onPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O continuar con',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.onPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/google-icon.svg',
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text('Continuar con Google'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
