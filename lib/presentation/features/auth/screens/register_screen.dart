import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/auth/routes/auth_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/custom_filled_button.dart';
import 'package:safe_beacon/presentation/shared/widgets/input_field_widget.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.surfaceContainerHigh,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(color: colorScheme.surfaceContainerHigh),
                ),
                Expanded(child: Container(color: colorScheme.surfaceContainer)),
              ],
            ),

            Positioned(
              bottom: 15,
              right: 15,
              child: SvgPicture.asset(AppImages.loginImage, height: 185),
            ),

            Padding(
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

                  const SizedBox(height: 40),

                  InputField(hint: l10n.email),
                  const SizedBox(height: 24),
                  InputField(hint: l10n.password, isPassword: true),
                  const SizedBox(height: 24),
                  InputField(hint: l10n.confirmPassword, isPassword: true),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: CustomFilledButton(
                      text: l10n.next,
                      onPressed: () {
                        const RegisterAddDataRoute().push(context);
                      },
                      backgroundColor: colorScheme.inversePrimary,
                      foregroundColor: colorScheme.onPrimary,
                      colorText: colorScheme.onPrimary,
                      fontSizeText: textTheme.labelLarge!.fontSize! * 1.2,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text.rich(
                      TextSpan(
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        text: l10n.haveAccount,
                        children: [
                          TextSpan(
                            text: l10n.loginHere,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                const AuthRoute().go(context);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
