import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/language.dart';
import 'package:safe_beacon/core/theme/theme.dart';
import 'package:safe_beacon/data/sources/remote/emailjs/emailjs_service.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const double _horizontalPadding = 20;

  void _showSuggestionsDialog(BuildContext context, AppLocalizations l10n) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    CustomDialog.show(
      context: context,
      title: l10n.suggestionsDialogTitle,
      content: Text(l10n.suggestionsDialogContent),
      buttonText: l10n.send,
      dropdownHint: l10n.suggestionsDialogTypeHint,
      dropdownItems: [
        DropdownMenuItem(
          value: Constants.suggestionTypeKey,
          child: Text(l10n.suggestionsDialogTypeSuggestion),
        ),
        DropdownMenuItem(
          value: Constants.incidentTypeKey,
          child: Text(l10n.suggestionsDialogTypeIncident),
        ),
      ],
      dropdownInitialValue: Constants.suggestionTypeKey,
      inputHint: l10n.suggestionsDialogDescriptionHint,
      onFormButtonPressed: (type, description) {
        Navigator.of(context, rootNavigator: true).pop();
        final email =
            FirebaseAuth.instance.currentUser?.email ?? '';
        EmailJsService()
            .sendFeedback(
              type: FeedbackType.fromDropdownValue(type),
              fromEmail: email,
              message: description,
            )
            .then(
              (_) => scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(l10n.suggestionsSentSuccess)),
              ),
            )
            .catchError(
              (_) => scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(l10n.suggestionsSentError)),
              ),
            );
      },
      secondButtonText: l10n.cancel,
      onSecondButtonPressed: () =>
          Navigator.of(context, rootNavigator: true).pop(),
    );
  }

  void _showFutureDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.notAvailableYet,
      content: Text(l10n.futureUpdateContent),
      buttonText: l10n.accept,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = context.watch<ThemeCubit>().state.themeMode;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final selectedLanguage = context
        .watch<LanguageCubit>()
        .state
        .locale
        .languageCode;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          SectionHeader(text: l10n.tabSettings),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Section 1: Contact lists
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsContactListsSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.group_outlined,
                        title: l10n.yourTrustedContacts,
                        description: l10n.settingsTrustedContactsDescription,
                        onPressed: () =>
                            const TrustedContactsRoute().push(context),
                      ),
                      SettingsOption(
                        icon: Icons.group_outlined,
                        title: l10n.yourProtectedPeople,
                        description: l10n.settingsProtectedPeopleDescription,
                        onPressed: () =>
                            const ProtectedPeopleRoute().push(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Dark mode
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsDarkModeSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.settingsEnableDarkMode,
                        description: l10n.settingsEnableDarkModeDescription,
                        switchValue: isDark,
                        onSwitchChanged: (value) {
                          context.read<ThemeCubit>().setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Language
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsLanguageSection,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownInputField<String>(
                          hint: l10n.settingsLanguageHint,
                          value: selectedLanguage,
                          alignedDropdown: true,
                          onChanged: (value) {
                            if (value == null) return;
                            context.read<LanguageCubit>().changeLocale(
                              Locale(value),
                            );
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'es',
                              child: Text(l10n.settingsLanguageSpanish),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.settingsLanguageEnglish),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text(l10n.settingsLanguageFrench),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Permissions
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsPermissionsSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.location_on_outlined,
                        title: l10n.settingsLocationPermission,
                        description: l10n.settingsLocationPermissionDescription,
                        onPressed: () => Geolocator.openAppSettings(),
                      ),
                      SettingsOption(
                        icon: Icons.notifications_outlined,
                        title: l10n.settingsNotificationsPermission,
                        description:
                            l10n.settingsNotificationsPermissionDescription,
                        onPressed: () => Geolocator.openAppSettings(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 5: Privacy policies
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsPrivacyPoliciesSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.visibility_outlined,
                        title: l10n.settingsViewPrivacyPolicies,
                        description:
                            l10n.settingsViewPrivacyPoliciesDescription,
                        onPressed: () {
                          // TODO: Navigate to privacy policies screen
                          _showFutureDialog(context, l10n);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 6: Suggestions and incidents
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsSuggestionsSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.check_circle_outline,
                        title: l10n.settingsSendSuggestions,
                        description: l10n.settingsSendSuggestionsDescription,
                        onPressed: () {
                          _showSuggestionsDialog(context, l10n);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 7: Customization
                  SettingsOptionsList(
                    sectionTitle: l10n.customization,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.settings_outlined,
                        title: l10n.featuresSettings,
                        description: l10n.settingsFeaturesConfigDescription,
                        onPressed: () {
                          _showFutureDialog(context, l10n);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
