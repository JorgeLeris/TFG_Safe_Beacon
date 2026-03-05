import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class RegisterAddDataScreen extends StatelessWidget {
  const RegisterAddDataScreen({super.key});

  // TODO: safe data with cubit for the case if goes back

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHigh,
        body: Padding(
          padding: const EdgeInsets.only(right: 32, left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 75),

              Center(
                child: Text(
                  l10n.appName,
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    fontSize: textTheme.headlineLarge!.fontSize! * 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Divider(color: colorScheme.onPrimary, thickness: 1.25, height: 0),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      InputField(hint: l10n.name),
                      const SizedBox(height: 24),
                      InputField(hint: l10n.surname),
                      const SizedBox(height: 24),
                      DateInputField(hint: l10n.birthDate),
                      const SizedBox(height: 24),
                      DropdownInputField(
                        hint: l10n.gender,
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
                        maxLines: 5,
                      ),

                      const SizedBox(height: 36),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: CustomFilledButton(
                                text: l10n.back,
                                onPressed: () {
                                  context.pop();
                                },
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                colorText: colorScheme.onPrimary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.2,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 35),

                          Expanded(
                            child: SizedBox(
                              child: CustomFilledButton(
                                text: l10n.createAccount,
                                onPressed: () {},
                                backgroundColor: colorScheme.inversePrimary,
                                foregroundColor: colorScheme.onPrimary,
                                colorText: colorScheme.onPrimary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.2,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                    ],
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
