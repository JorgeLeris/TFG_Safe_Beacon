import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.name,
    this.surname,
    this.birthDate,
    this.gender,
    this.description,
    this.profilePhoto,
  });

  final String? name;
  final String? surname;
  final String? birthDate;
  final String? gender;
  final String? description;
  final String? profilePhoto;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _birthDate = DateTimeX.tryFromStringDate(widget.birthDate);
  }

  Widget _buildProfileAvatar(ColorScheme colorScheme) {
    ImageProvider? imageProvider;

    if (widget.profilePhoto != null && widget.profilePhoto!.isNotEmpty) {
      if (widget.profilePhoto!.startsWith('http://') ||
          widget.profilePhoto!.startsWith('https://')) {
        imageProvider = NetworkImage(widget.profilePhoto!);
      } else {
        try {
          final bytes = base64Decode(widget.profilePhoto!);
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            SectionHeader(text: l10n.editProfile),

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
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              child: _buildProfileAvatar(colorScheme),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: colorScheme.onTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Profile fields
                      InputField(hint: l10n.name, initialValue: widget.name),
                      const SizedBox(height: 24),
                      InputField(
                        hint: l10n.surname,
                        initialValue: widget.surname,
                      ),
                      const SizedBox(height: 24),
                      DateInputField(
                        hint: l10n.birthDate,
                        initialValue: _birthDate,
                      ),
                      const SizedBox(height: 24),
                      DropdownInputField(
                        hint: l10n.gender,
                        value: widget.gender,
                        items: [
                          DropdownMenuItem(
                            value: Constants.maleFieldKey,
                            child: Text(l10n.male),
                          ),
                          DropdownMenuItem(
                            value: Constants.femaleFieldKey,
                            child: Text(l10n.female),
                          ),
                          DropdownMenuItem(
                            value: Constants.otherFieldKey,
                            child: Text(l10n.other),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      InputField(
                        hint: l10n.descriptionObservation,
                        initialValue: widget.description,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 25),

                      // Save button
                      Center(
                        child: CustomFilledButton(
                          text: l10n.save,
                          onPressed: () => context.pop(),
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          colorText: colorScheme.onSecondary,
                          fontSizeText: textTheme.labelLarge!.fontSize! * 1.1,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: 225,
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
