import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/auth/cubits/login_cubit.dart';
import 'package:safe_beacon/presentation/features/auth/routes/auth_routes.dart';
import 'package:safe_beacon/presentation/features/auth/widgets/email_verification_widget.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LoginView();
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final cubit = context.read<LoginCubit>();

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) =>
          prev.isLoading && !curr.isLoading ||
          !prev.isPasswordResetDialogReady && curr.isPasswordResetDialogReady,
      listener: (context, state) {
        if (state.isPasswordResetDialogReady) {
          cubit.clearPasswordResetFlag();
          CustomDialog.show(
            context: context,
            title: l10n.passwordResetTitle,
            content: Text(l10n.passwordResetMessage),
            buttonText: l10n.accept,
            onButtonPressed: () {
              Navigator.of(context).pop();
              cubit.sendPasswordResetLink(l10n);
            },
          );
          return;
        }
        if (state.requiresEmailVerification) {
          cubit.clearVerificationFlag();
          showEmailVerificationDialog(
            context: context,
            l10n: l10n,
            onCheckVerified: cubit.checkEmailVerified,
            onResend: cubit.resendVerificationEmail,
            onNotVerified: () => CustomDialog.show(
              context: context,
              title: l10n.authFailedTitle,
              content: Text(l10n.emailNotVerifiedError),
              buttonText: l10n.accept,
            ),
          );
          return;
        }
        if (state.errorMessage != null) {
          CustomDialog.show(
            context: context,
            title: l10n.loginErrorTitle,
            content: Text(state.errorMessage!),
            buttonText: l10n.accept,
          );
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
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

                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (prev, curr) =>
                          prev.emailError != curr.emailError,
                      builder: (context, state) => InputField(
                        hint: l10n.email,
                        onChanged: cubit.onEmailChanged,
                        errorText: state.emailError,
                      ),
                    ),

                    const SizedBox(height: 24),

                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (prev, curr) =>
                          prev.passwordError != curr.passwordError,
                      builder: (context, state) => InputField(
                        hint: l10n.password,
                        isPassword: true,
                        onChanged: cubit.onPasswordChanged,
                        errorText: state.passwordError,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        cubit.onForgotPassword(l10n);
                      },
                      child: Text(
                        l10n.forgotPassword,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (prev, curr) =>
                          prev.isLoading != curr.isLoading,
                      builder: (context, state) => SizedBox(
                        width: double.infinity,
                        child: CustomFilledButton(
                          text: l10n.login,
                          isLoading: state.isLoading,
                          onPressed: state.isLoading
                              ? () {}
                              : () {
                                  FocusScope.of(context).unfocus();
                                  cubit.onSubmit(context.l10n);
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
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          text: l10n.dontHaveAccount,
                          children: [
                            TextSpan(
                              text: l10n.register,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  const RegisterRoute().go(context);
                                  FocusScope.of(context).unfocus();
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.continueWith,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (prev, curr) =>
                          prev.isLoading != curr.isLoading,
                      builder: (context, state) => SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.inversePrimary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () => cubit.onGoogleLogin(l10n),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(AppIcons.googleIcon, height: 24),
                              const SizedBox(width: 8),
                              Text(l10n.loginGoogle),
                            ],
                          ),
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
