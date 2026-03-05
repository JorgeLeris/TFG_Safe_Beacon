import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class OtherProfileScreen extends StatelessWidget {
  const OtherProfileScreen({super.key});

  // TODO: Change this to receive the user's data as parameters

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // TODO: Change this to the user's name
          const SectionHeader(text: 'Perfil de _UsuarioX'),

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
                      label: l10n.name,
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: l10n.surname,
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: l10n.birthDate,
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: l10n.gender,
                      value: 'Lorem Impsum',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),

                    _ProfileField(
                      label: l10n.descriptionObservation,
                      value:
                          'Is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: 25),

                    // Edit buttons
                    Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(),
                            const SizedBox(height: 25),

                            CustomFilledButton(
                              text: '${l10n.initChatWith} _UsuarioX',
                              onPressed: () {},
                              backgroundColor: colorScheme.tertiary,
                              foregroundColor: colorScheme.onTertiary,
                              colorText: colorScheme.onTertiary,
                              fontSizeText:
                                  textTheme.labelLarge!.fontSize! * 1.1,
                              icon: Icons.chat_outlined,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
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
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

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
