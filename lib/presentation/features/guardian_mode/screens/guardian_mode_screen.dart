import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class GuardianModeScreen extends StatelessWidget {
  const GuardianModeScreen({super.key});

  void _showInfoDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.guardianMode,
      content: Text(l10n.guardianModeInfoContent),
      buttonText: l10n.accept,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Header with info
          SectionHeader(
            text: l10n.guardianMode,
            trailingIcon: Icons.info_outline_rounded,
            onTrailingIconPressed: () => _showInfoDialog(context, l10n),
          ),
        ],
      ),
    );
  }
}
