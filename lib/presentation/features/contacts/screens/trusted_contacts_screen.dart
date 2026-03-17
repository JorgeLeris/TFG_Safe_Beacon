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

  static const List<Map<String, String?>> _mockContacts = [
    {'username': 'Ana García', 'photo': null},
    {'username': 'Carlos López', 'photo': null},
    {'username': 'María Martínez', 'photo': null},
  ];

  static const List<Map<String, String?>> _mockPending = [];

  Key _contactsSearchKey = UniqueKey();
  Key _pendingSearchKey = UniqueKey();

  String _contactsQuery = '';
  String _pendingQuery = '';

  // TODO: set to true when the cubit reports a load failure
  static const bool _hasError = false;

  void _onTabChanged(int index) {
    setState(() {
      if (index == 1) {
        _contactsSearchKey = UniqueKey();
        _contactsQuery = '';
      } else {
        _pendingSearchKey = UniqueKey();
        _pendingQuery = '';
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

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

  Widget _buildContactsList(AppLocalizations l10n) {
    if (_hasError) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (_mockContacts.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noTrustedContactsTitle,
        description: l10n.noTrustedContactsDescription,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SearchInputField(
            key: _contactsSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _contactsQuery = q),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 24),
          ),
          if (_filteredContacts.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
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
    );
  }

  Widget _buildPendingList(AppLocalizations l10n) {
    if (_hasError) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (_mockPending.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noPendingRequestsTitle,
        description: l10n.noPendingRequestsDescription,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SearchInputField(
            key: _pendingSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _pendingQuery = q),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 24),
          ),
          if (_filteredPending.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
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
    );
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
                onTabChanged: _onTabChanged,
                children: [_buildContactsList(l10n), _buildPendingList(l10n)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
