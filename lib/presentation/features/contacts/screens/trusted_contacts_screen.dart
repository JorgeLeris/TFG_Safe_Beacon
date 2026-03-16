import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  // TODO: replace with real user code from cubit/provider
  static const String _mockUserCode = 'USR-4F2A-9C1B';

  static const _mockContacts = [
    {'username': 'Ana García', 'photo': null},
    {'username': 'Carlos López', 'photo': null},
    {'username': 'María Martínez', 'photo': null},
  ];

  static const _mockPending = [
    {'username': 'Luis Sánchez', 'photo': null},
    {'username': 'Laura Fernández', 'photo': null},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          SectionHeader(text: l10n.yourTrustedContacts),

          // Section 1: user code + add contact
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
                Text(
                  l10n.yourUserCode,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const CopyableCodeField(code: _mockUserCode),
                const SizedBox(height: 16),
                SectionButton(
                  icon: Icons.person_add_outlined,
                  text: l10n.addTrustedContact,
                  showArrow: false,
                  onPressed: () {},
                  backgroundColor: colorScheme.secondary,
                  contentColor: colorScheme.onSecondary,
                ),
              ],
            ),
          ),

          // Section 2: tabs
          Expanded(
            child: CustomTabView(
              tabs: [l10n.trustedContacts, l10n.pendingRequests],
              children: [
                // Tab 1 — trusted contacts list
                _mockContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes contactos de confianza aún',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _mockContacts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final contact = _mockContacts[index];
                          return UserListItem(
                            username: contact['username'] as String,
                            profilePhoto: contact['photo'],
                            onProfileTap: () {},
                            onDelete: () {},
                          );
                        },
                      ),

                // Tab 2 — pending requests
                _mockPending.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes solicitudes pendientes',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _mockPending.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = _mockPending[index];
                          return UserListItem(
                            username: request['username'] as String,
                            profilePhoto: request['photo'],
                            onProfileTap: () {},
                            onDelete: () {},
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
