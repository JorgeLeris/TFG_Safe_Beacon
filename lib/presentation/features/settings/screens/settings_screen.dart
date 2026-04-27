import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: These values should be loaded from user preferences and updated accordingly when changed. (put default values)
  bool _darkMode = false;
  bool _locationPermission = false;
  bool _notificationsPermission = false;
  String? _selectedLanguage = 'es';

  static const double _horizontalPadding = 20;

  void _showSuggestionsDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.suggestionsDialogTitle,
      content: Text(l10n.suggestionsDialogContent),
      buttonText: l10n.send,
      dropdownHint: l10n.suggestionsDialogTypeHint,
      dropdownItems: [
        DropdownMenuItem(
          value: 'suggestion',
          child: Text(l10n.suggestionsDialogTypeSuggestion),
        ),
        DropdownMenuItem(
          value: 'incident',
          child: Text(l10n.suggestionsDialogTypeIncident),
        ),
      ],
      inputHint: l10n.suggestionsDialogDescriptionHint,
      onFormButtonPressed: (type, description) {
        Navigator.of(context, rootNavigator: true).pop();
        // TODO: Send suggestion/incident with [type] and [description]
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
                        onPressed: () {
                          // TODO: Navigate to trusted contacts screen
                        },
                      ),
                      SettingsOption(
                        icon: Icons.group_outlined,
                        title: l10n.yourProtectedPeople,
                        description: l10n.settingsProtectedPeopleDescription,
                        onPressed: () {
                          // TODO: Navigate to protected people screen
                        },
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
                        switchValue: _darkMode,
                        onSwitchChanged: (value) {
                          setState(() => _darkMode = value);
                          // TODO: Apply dark / light theme
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Permissions
                  SettingsOptionsList(
                    sectionTitle: l10n.settingsPermissionsSection,
                    horizontalPadding: _horizontalPadding,
                    options: [
                      SettingsOption(
                        icon: Icons.location_on_outlined,
                        title: l10n.settingsLocationPermission,
                        description: l10n.settingsLocationPermissionDescription,
                        switchValue: _locationPermission,
                        onSwitchChanged: (value) {
                          setState(() => _locationPermission = value);
                          // TODO: Request / revoke location permission
                        },
                      ),
                      SettingsOption(
                        icon: Icons.notifications_outlined,
                        title: l10n.settingsNotificationsPermission,
                        description:
                            l10n.settingsNotificationsPermissionDescription,
                        switchValue: _notificationsPermission,
                        onSwitchChanged: (value) {
                          setState(() => _notificationsPermission = value);
                          // TODO: Request / revoke notifications permission
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Language
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
                          value: _selectedLanguage,
                          alignedDropdown: true,
                          onChanged: (value) {
                            setState(() => _selectedLanguage = value);
                            // TODO: Change app locale
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
