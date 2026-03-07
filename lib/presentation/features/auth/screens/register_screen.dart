import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/register_cubit.dart';
import 'package:safe_beacon/presentation/features/auth/routes/auth_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final cubit = context.read<RegisterCubit>();

    return BlocListener<RegisterCubit, RegisterState>(
      listenWhen: (prev, curr) => !prev.step1Completed && curr.step1Completed,
      listener: (context, state) => const RegisterAddDataRoute().push(context),
      child: GestureDetector(
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
                  Expanded(
                    child: Container(color: colorScheme.surfaceContainer),
                  ),
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

                    BlocBuilder<RegisterCubit, RegisterState>(
                      buildWhen: (prev, curr) =>
                          prev.emailError != curr.emailError,
                      builder: (context, state) => InputField(
                        hint: l10n.email,
                        onChanged: cubit.onEmailChanged,
                        errorText: state.emailError,
                      ),
                    ),

                    const SizedBox(height: 24),

                    BlocBuilder<RegisterCubit, RegisterState>(
                      buildWhen: (prev, curr) =>
                          prev.passwordError != curr.passwordError,
                      builder: (context, state) => InputField(
                        hint: l10n.password,
                        isPassword: true,
                        onChanged: cubit.onPasswordChanged,
                        errorText: state.passwordError,
                      ),
                    ),

                    const SizedBox(height: 24),

                    BlocBuilder<RegisterCubit, RegisterState>(
                      buildWhen: (prev, curr) =>
                          prev.confirmPasswordError !=
                          curr.confirmPasswordError,
                      builder: (context, state) => InputField(
                        hint: l10n.confirmPassword,
                        isPassword: true,
                        onChanged: cubit.onConfirmPasswordChanged,
                        errorText: state.confirmPasswordError,
                      ),
                    ),

                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      child: CustomFilledButton(
                        text: l10n.next,
                        onPressed: () => cubit.onNextStep(l10n),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }
}
