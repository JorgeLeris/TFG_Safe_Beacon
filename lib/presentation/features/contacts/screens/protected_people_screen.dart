import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/cubits/protected_people_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ProtectedPeopleScreen extends StatefulWidget {
  const ProtectedPeopleScreen({super.key});

  @override
  State<ProtectedPeopleScreen> createState() => _ProtectedPeopleScreenState();
}

class _ProtectedPeopleScreenState extends State<ProtectedPeopleScreen> {
  static const List<Map<String, String?>> _mockProtectedPeople = [];

  static const List<Map<String, String?>> _mockRequestsReceived = [
    {'username': 'Ana García', 'photo': null},
    {'username': 'Carlos López', 'photo': null},
    {'username': 'María Martínez', 'photo': null},
  ];

  Key _protectedPeopleSearchKey = UniqueKey();
  Key _requestsReceivedSearchKey = UniqueKey();

  String _protectedPeopleQuery = '';
  String _requestsReceivedQuery = '';

  // TODO: set to true when the cubit reports a load failure
  static const bool _hasError = false;

  @override
  void initState() {
    super.initState();
    context.read<ProtectedPeopleCubit>().loadUserCode();
  }

  void _onTabChanged(int index) {
    setState(() {
      if (index == 1) {
        _protectedPeopleSearchKey = UniqueKey();
        _protectedPeopleQuery = '';
      } else {
        _requestsReceivedSearchKey = UniqueKey();
        _requestsReceivedQuery = '';
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  List<Map<String, String?>> get _filteredProtectedPeople {
    if (_protectedPeopleQuery.isEmpty) return _mockProtectedPeople;
    final q = _protectedPeopleQuery.toLowerCase();
    return _mockProtectedPeople
        .where((c) => (c['username'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<Map<String, String?>> get _filteredRequestsReceived {
    if (_requestsReceivedQuery.isEmpty) return _mockRequestsReceived;
    final q = _requestsReceivedQuery.toLowerCase();
    return _mockRequestsReceived
        .where((c) => (c['username'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  Widget _buildProtectedPeopleList(AppLocalizations l10n) {
    if (_hasError) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (_mockProtectedPeople.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noProtectedPeopleTitle,
        description: l10n.noProtectedPeopleDescription,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SearchInputField(
            key: _protectedPeopleSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _protectedPeopleQuery = q),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 24),
          ),
          if (_filteredProtectedPeople.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ..._filteredProtectedPeople.map(
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

  Widget _buildRequestsReceivedList(AppLocalizations l10n) {
    if (_hasError) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (_mockRequestsReceived.isEmpty) {
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
            key: _requestsReceivedSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _requestsReceivedQuery = q),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 24),
          ),
          if (_filteredRequestsReceived.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ..._filteredRequestsReceived.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserListItem(
                  username: request['username'] as String,
                  profilePhoto: request['photo'],
                  onProfileTap: () {},
                  onDelete: () {},
                  onAccept: () {},
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
            SectionHeader(text: l10n.yourProtectedPeople),

            // Section 1: user code
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
              child: BlocBuilder<ProtectedPeopleCubit, ProtectedPeopleState>(
                builder: (context, state) {
                  final code = state.isLoading
                      ? '...'
                      : (state.username.orDash());
                  return Column(
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
                      CopyableCodeField(code: code),
                    ],
                  );
                },
              ),
            ),

            // Section 2: tabs
            Expanded(
              child: CustomTabView(
                tabs: [l10n.protectedPeople, l10n.requestsReceived],
                onTabChanged: _onTabChanged,
                children: [
                  _buildProtectedPeopleList(l10n),
                  _buildRequestsReceivedList(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
