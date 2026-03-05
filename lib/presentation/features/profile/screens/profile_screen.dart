import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/custom_filled_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        title: Text(
          'SafeBeacon',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Perfil',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Profile picture
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.onSurface),
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: const AssetImage(
                            AppImages.placeholderProfileImage,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Profile fields
                    _ProfileField(
                      label: 'Nombre',
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: 'Apellidos',
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: 'Fecha de nacimiento',
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: 'Género',
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: 'Descripción / observaciones',
                      value:
                          'Is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                      isMultiLine: true,
                    ),

                    const SizedBox(height: 25),

                    // Edit buttons
                    Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomFilledButton(
                              text: 'Editar',
                              onPressed: () {},
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                              colorText: colorScheme.onSecondary,
                              fontSizeText:
                                  textTheme.labelLarge!.fontSize! * 1.1,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 10,
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            CustomFilledButton(
                              text: 'Cerrar sesión',
                              onPressed: () {},
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              colorText: colorScheme.onPrimary,
                              fontSizeText:
                                  textTheme.labelLarge!.fontSize! * 1.1,
                              icon: Icons.logout,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
    this.isMultiLine = false,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final bool isMultiLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
