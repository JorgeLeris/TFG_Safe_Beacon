import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/custom_filled_button.dart';
import 'package:safe_beacon/presentation/shared/widgets/date_input_field_widget.dart';
import 'package:safe_beacon/presentation/shared/widgets/input_field_widget.dart';

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

                      InputField(hint: 'Nombre'),
                      const SizedBox(height: 24),
                      InputField(hint: 'Apellidos'),
                      const SizedBox(height: 24),
                      DateInputField(hint: 'Fecha de nacimiento'),
                      const SizedBox(height: 24),
                      InputField(hint: 'Género'),
                      const SizedBox(height: 24),
                      InputField(
                        hint: 'Descripción / observaciones',
                        maxLines: 5,
                      ),

                      const SizedBox(height: 36),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: CustomFilledButton(
                                text: 'Atrás',
                                onPressed: () {
                                  context.pop();
                                },
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                colorText: colorScheme.onPrimary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(width: 35),

                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: CustomFilledButton(
                                text: 'Crear cuenta',
                                onPressed: () {},
                                backgroundColor: colorScheme.inversePrimary,
                                foregroundColor: colorScheme.onPrimary,
                                colorText: colorScheme.onPrimary,
                                fontSizeText:
                                    textTheme.labelLarge!.fontSize! * 1.2,
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
