import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          SectionHeader(text: l10n.headerControl, onRefresh: () {}),

          // Section 1: contacts button
          Container(
            width: double.infinity,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.30),
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionButton(
                  icon: Icons.group_outlined,
                  text: l10n.yourProtectedPeople,
                  onPressed: () {
                    const ProtectedPeopleRoute().push(context);
                  },
                  backgroundColor: colorScheme.secondary,
                  contentColor: colorScheme.onSecondary,
                  notificationCount: 2,
                ),
              ],
            ),
          ),

          // Section 2: tabs
          Expanded(
            child: CustomTabView(
              tabs: [l10n.alerts, l10n.followUps, l10n.history],
              children: [
                const Placeholder(),
                const Placeholder(),
                const Placeholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
