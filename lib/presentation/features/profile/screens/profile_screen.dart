import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/auth/routes/auth_routes.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/logout_cubit.dart';
import 'package:safe_beacon/presentation/features/profile/routes/profile_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return BlocListener<LogoutCubit, LogoutState>(
      listener: (context, state) {
        if (state.isSuccess) {
          const AuthRoute().go(context);
        }
        if (state.errorMessage != null) {
          // TODO: Show error message
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            SectionHeader(text: l10n.tabProfile),
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
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
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
                              CustomFilledButton(
                                text: l10n.edit,
                                onPressed: () {
                                  const ProfileEditRoute().push(context);
                                },
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                                colorText: colorScheme.onSecondary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.1,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                width: 225,
                              ),

                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),

                              BlocBuilder<LogoutCubit, LogoutState>(
                                builder: (context, state) {
                                  return CustomFilledButton(
                                    text: l10n.logout,
                                    onPressed: state.isLoading
                                        ? () {}
                                        : () => context
                                              .read<LogoutCubit>()
                                              .onLogout(),
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    colorText: colorScheme.onPrimary,
                                    fontSizeText:
                                        textTheme.labelLarge!.fontSize! * 1.1,
                                    icon: state.isLoading ? null : Icons.logout,
                                    isLoading: state.isLoading,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    width: 225,
                                  );
                                },
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
