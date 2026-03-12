import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/home/routes/home_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

Future<void> showEmailVerificationDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required Future<bool> Function() onCheckVerified,
  required Future<void> Function() onResend,
  VoidCallback? onNotVerified,
}) {
  return CustomDialog.show(
    context: context,
    title: l10n.verifyAccountTitle,
    dismissible: false,
    content: Text(l10n.verifyAccountMessage),
    topButtonText: l10n.resendVerificationEmail,
    onTopButtonPressed: () => onResend(),
    buttonText: l10n.continueButton,
    onButtonPressed: () =>
        _handleContinue(context, l10n, onCheckVerified, onNotVerified),
  );
}

Future<void> _handleContinue(
  BuildContext context,
  AppLocalizations l10n,
  Future<bool> Function() onCheckVerified,
  VoidCallback? onNotVerified,
) async {
  final isVerified = await onCheckVerified();
  if (!context.mounted) return;

  Navigator.of(context).pop();

  if (isVerified) {
    const HomeRoute().go(context);
    return;
  }

  onNotVerified?.call();
}
