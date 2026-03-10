import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/logout_cubit.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/profile_cubit.dart';
import 'package:safe_beacon/presentation/features/profile/routes/profile_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  String _mapGender(String? gender, AppLocalizations l10n) {
    switch (gender) {
      case Constants.maleFieldKey:
        return l10n.male;
      case Constants.femaleFieldKey:
        return l10n.female;
      case Constants.otherFieldKey:
        return l10n.other;
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<LogoutCubit, LogoutState>(
          listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
          listener: (context, state) {
            if (state.errorMessage != null) {
              CustomDialog.show(
                context: context,
                title: l10n.logoutErrorTitle,
                content: Text(state.errorMessage!),
                buttonText: l10n.accept,
              );
            }
          },
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
          listener: (context, state) {
            if (state.failure != null) {
              final message = state.failure!.when(
                network: (_, __) => l10n.networkError,
                unauthorized: () => l10n.genericError,
                forbidden: () => l10n.genericError,
                notFound: (_) => l10n.profileNotFound,
                conflict: (_) => l10n.genericError,
                serialization: (_) => l10n.genericError,
                business: (msg) => msg ?? l10n.genericError,
                unknown: (_) => l10n.genericError,
              );
              CustomDialog.show(
                context: context,
                title: l10n.genericError,
                content: Text(message),
                buttonText: l10n.accept,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            SectionHeader(text: l10n.tabProfile),
            Expanded(
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profile = state.userProfile;

                  return SingleChildScrollView(
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
                                border: Border.all(
                                  color: colorScheme.onSurface,
                                ),
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
                            value: profile?.name ?? '-',
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),

                          _ProfileField(
                            label: l10n.surname,
                            value: profile?.surname ?? '-',
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),

                          _ProfileField(
                            label: l10n.birthDate,
                            value: profile?.birthDate ?? '-',
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),

                          _ProfileField(
                            label: l10n.gender,
                            value: _mapGender(profile?.gender, l10n),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),

                          _ProfileField(
                            label: l10n.descriptionObservation,
                            value: profile?.description ?? '-',
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
                                    builder: (context, logoutState) {
                                      return CustomFilledButton(
                                        text: l10n.logout,
                                        onPressed: logoutState.isLoading
                                            ? () {}
                                            : () => context
                                                  .read<LogoutCubit>()
                                                  .onLogout(l10n),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        colorText: colorScheme.onPrimary,
                                        fontSizeText:
                                            textTheme.labelLarge!.fontSize! *
                                            1.1,
                                        icon: logoutState.isLoading
                                            ? null
                                            : Icons.logout,
                                        isLoading: logoutState.isLoading,
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
                  );
                },
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
