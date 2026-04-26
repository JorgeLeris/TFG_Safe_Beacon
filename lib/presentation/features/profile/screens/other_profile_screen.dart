import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/chat/helpers/navigate_to_chat.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/profile_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class OtherProfileScreen extends StatefulWidget {
  const OtherProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
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

  Widget _buildProfileAvatar(String? profilePhoto, ColorScheme colorScheme) {
    ImageProvider? imageProvider;

    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      if (profilePhoto.startsWith('http://') ||
          profilePhoto.startsWith('https://')) {
        imageProvider = NetworkImage(profilePhoto);
      } else {
        try {
          final bytes = base64Decode(profilePhoto);
          imageProvider = MemoryImage(bytes);
        } catch (_) {
          imageProvider = null;
        }
      }
    }

    return CircleAvatar(
      radius: 56,
      backgroundColor: colorScheme.surfaceContainerHighest,
      backgroundImage:
          imageProvider ?? const AssetImage(AppImages.placeholderProfileImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.failure != null) {
            return Center(
              child: Text(
                l10n.genericError,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }

          final profile = state.userProfile;
          final displayName =
              '${(profile?.name ?? '').trim()} ${(profile?.surname ?? '').trim()}'
                  .trim()
                  .capitalized();

          return Column(
            children: [
              SectionHeader(text: displayName.isNotEmpty ? displayName : '-'),
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
                            child: _buildProfileAvatar(
                              profile?.profilePhoto,
                              colorScheme,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Profile fields
                        _ProfileField(
                          label: l10n.name,
                          value: (profile?.name).orDash(),
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: l10n.surname,
                          value: (profile?.surname).orDash(),
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),

                        _ProfileField(
                          label: l10n.birthDate,
                          value: (profile?.birthDate).orDash(),
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
                          value: (profile?.description).orDash(),
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),

                        const SizedBox(height: 25),

                        // Chat button
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(),
                              const SizedBox(height: 25),
                              CustomFilledButton(
                                text:
                                    '${l10n.initChatWith} ${(profile?.name).orDash()}',
                                onPressed: () {
                                  navigateToChat(
                                    context,
                                    otherUid: widget.uid,
                                    otherDisplayName: displayName,
                                    otherProfilePhoto: profile?.profilePhoto,
                                  );
                                },
                                backgroundColor: colorScheme.tertiary,
                                foregroundColor: colorScheme.onTertiary,
                                colorText: colorScheme.onTertiary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.1,
                                icon: Icons.chat_outlined,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                width: 225,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
