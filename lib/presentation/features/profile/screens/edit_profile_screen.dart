import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/edit_profile_cubit.dart';
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
  late String _name;
  late String? _surname;
  late String? _description;
  late String? _gender;
  late String? _selectedBirthDate;
  String? _selectedProfilePhoto;

  @override
  void initState() {
    super.initState();
    _name = widget.name ?? '';
    _surname = widget.surname;
    _description = widget.description;
    _gender = widget.gender;
    _selectedBirthDate = widget.birthDate;
    _selectedProfilePhoto = widget.profilePhoto;
    _birthDate = DateTimeX.tryFromStringDate(widget.birthDate);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    setState(() => _selectedProfilePhoto = base64Encode(bytes));
  }

  Widget _buildProfileAvatar(ColorScheme colorScheme, AppLocalizations l10n) {
    ImageProvider? imageProvider;

    if (_selectedProfilePhoto != null && _selectedProfilePhoto!.isNotEmpty) {
      if (_selectedProfilePhoto!.startsWith('http://') ||
          _selectedProfilePhoto!.startsWith('https://')) {
        imageProvider = NetworkImage(_selectedProfilePhoto!);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(_selectedProfilePhoto!));
        } catch (_) {
          imageProvider = null;
        }
      }
    }

    final hasPhoto = imageProvider != null;

    return Semantics(
      label: hasPhoto ? l10n.profilePhoto : l10n.profilePhotoUnavailable,
      image: true,
      child: CircleAvatar(
        radius: 56,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage:
            imageProvider ??
            const AssetImage(AppImages.placeholderProfileImage),
      ),
    );
  }

  String _mapFailure(AppFailure failure, AppLocalizations l10n) {
    return failure.when(
      network: (_, _) => l10n.networkError,
      unauthorized: () => l10n.genericError,
      forbidden: () => l10n.genericError,
      notFound: (_) => l10n.genericError,
      conflict: (_) => l10n.genericError,
      serialization: (_) => l10n.genericError,
      business: (msg) => msg ?? l10n.genericError,
      unknown: (_) => l10n.genericError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return BlocListener<EditProfileCubit, EditProfileState>(
      listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
      listener: (context, state) {
        if (state.isSaved) {
          context.pop();
        } else if (state.failure != null) {
          CustomDialog.show(
            context: context,
            title: l10n.genericError,
            content: Text(_mapFailure(state.failure!, l10n)),
            buttonText: l10n.accept,
          );
        }
      },
      child: GestureDetector(
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
                                child: _buildProfileAvatar(colorScheme, l10n),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Semantics(
                                  label: l10n.selectProfilePhotoFromGallery,
                                  button: true,
                                  child: GestureDetector(
                                    onTap: _pickImage,
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
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Profile fields
                        InputField(
                          hint: l10n.name,
                          initialValue: widget.name,
                          onChanged: (v) => _name = v,
                        ),
                        const SizedBox(height: 24),
                        InputField(
                          hint: l10n.surname,
                          initialValue: widget.surname,
                          onChanged: (v) => _surname = v,
                        ),
                        const SizedBox(height: 24),
                        DateInputField(
                          hint: l10n.birthDate,
                          initialValue: _birthDate,
                          onChanged: (date) =>
                              _selectedBirthDate = date?.toStringDate(),
                        ),
                        const SizedBox(height: 24),
                        DropdownInputField(
                          hint: l10n.gender,
                          value: widget.gender,
                          onChanged: (v) => _gender = v,
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
                          onChanged: (v) => _description = v,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 25),

                        // Save button
                        BlocBuilder<EditProfileCubit, EditProfileState>(
                          builder: (context, state) {
                            return Center(
                              child: CustomFilledButton(
                                text: l10n.save,
                                isLoading: state.isLoading,
                                onPressed: state.isLoading
                                    ? () {}
                                    : () => context
                                          .read<EditProfileCubit>()
                                          .saveProfile(
                                            name: _name,
                                            surname: _surname,
                                            birthDate: _selectedBirthDate,
                                            gender: _gender,
                                            description: _description,
                                            profilePhoto: _selectedProfilePhoto,
                                          ),
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
                            );
                          },
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
      ),
    );
  }
}
