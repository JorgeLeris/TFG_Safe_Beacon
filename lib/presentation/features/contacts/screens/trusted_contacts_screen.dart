import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
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

  String _contactsQuery = '';
  String _pendingQuery = '';

  List<Map<String, String?>> get _filteredContacts {
    if (_contactsQuery.isEmpty) return _mockContacts;
    final q = _contactsQuery.toLowerCase();
    return _mockContacts
        .where((c) => (c['username'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<Map<String, String?>> get _filteredPending {
    if (_pendingQuery.isEmpty) return _mockPending;
    final q = _pendingQuery.toLowerCase();
    return _mockPending
        .where((c) => (c['username'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        SearchInputField(
                          hint: l10n.searchContact,
                          onChanged: (q) => setState(() => _contactsQuery = q),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Divider(height: 24),
                        ),
                        if (_filteredContacts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text(
                              l10n.noTrustedContactsYet,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._filteredContacts.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: UserListItem(
                                username: contact['username'] as String,
                                profilePhoto: contact['photo'],
                                onProfileTap: () {},
                                onDelete: () {},
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tab 2 — pending requests
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        SearchInputField(
                          hint: l10n.searchContact,
                          onChanged: (q) => setState(() => _pendingQuery = q),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Divider(height: 24),
                        ),
                        if (_filteredPending.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text(
                              l10n.noPendingRequestsYet,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._filteredPending.map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: UserListItem(
                                username: request['username'] as String,
                                profilePhoto: request['photo'],
                                onProfileTap: () {},
                                onDelete: () {},
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
