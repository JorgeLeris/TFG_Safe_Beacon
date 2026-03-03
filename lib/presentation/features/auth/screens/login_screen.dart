import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_beacon/presentation/shared/widgets/input_field_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // TODO: adaptar a modo horizontal, si sube mucho el teclado que suban los campos de texto
    // TODO: margen de la imagen, imagen de google, container color fondo abajo, tamaño texto botones
    // TODO: que al pulsar fuera se cierre el teclado, colo modo oscuro inputfields
    // TODO: espaciado de los elementos y adaptar a la pantalla para evitar que se salga, añadir botones
    // TODO: cambiar tipografia titulo, hacer un tema para ella?
    // TODO: cambiar color de fondo del modo oscuro (además que no se use el primario)
    // TODO: traducir

    return Scaffold(
      backgroundColor: colorScheme.primary,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/login-image.svg',
              height: 160,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  Center(
                    child: Text(
                      'SafeBeacon',
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

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
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {},
                      child: const Text('Iniciar sesión'),
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

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {},
                      child: const Text('Continuar con Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
