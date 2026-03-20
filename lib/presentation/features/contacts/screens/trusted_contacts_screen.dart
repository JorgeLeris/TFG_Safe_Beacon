import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request_item.dart';
import 'package:safe_beacon/presentation/features/contacts/cubits/trusted_contacts_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  // TODO: replace with real contacts data from cubit
  static const List<Map<String, String?>> _mockContacts = [
    {'username': 'Ana García', 'photo': null},
    {'username': 'Carlos López', 'photo': null},
    {'username': 'María Martínez', 'photo': null},
  ];

  Key _contactsSearchKey = UniqueKey();
  Key _pendingSearchKey = UniqueKey();

  String _contactsQuery = '';
  String _pendingQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TrustedContactsCubit>().loadUserCode();
    context.read<TrustedContactsCubit>().loadSentRequests();
  }

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

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showSendRequestDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.sendRequest,
      content: Text(
        l10n.sendRequestDescription,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      inputHint: l10n.userCode,
      buttonText: l10n.send,
      onInputButtonPressed: (receiverUsername) {
        Navigator.of(context).pop();
        context.read<TrustedContactsCubit>().sendRequest(
          receiverUsername.trim(),
        );
      },
    );
  }

  void _showSendRequestErrorDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppFailure failure,
  ) {
    final message = failure.when(
      network: (_, _) => l10n.networkError,
      notFound: (_) => l10n.userCodeNotFound,
      conflict: (_) => l10n.requestAlreadyExists,
      business: (msg) =>
          msg == 'self_request' ? l10n.selfRequestError : l10n.genericError,
      forbidden: () => l10n.genericError,
      unauthorized: () => l10n.genericError,
      serialization: (_) => l10n.genericError,
      unknown: (_) => l10n.genericError,
    );

    CustomDialog.show(
      context: context,
      title: l10n.sendRequestErrorTitle,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      buttonText: l10n.accept,
    );
  }

  void _showDeleteRequestDialog(
    BuildContext context,
    AppLocalizations l10n,
    ContactRequestItem request,
  ) {
    CustomDialog.show(
      context: context,
      title: l10n.cancelRequest,
      content: Text(
        l10n.cancelRequestDescription(request.peerUsername),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      buttonText: l10n.accept,
      onButtonPressed: () {
        Navigator.of(context).pop();
        context.read<TrustedContactsCubit>().deleteSentRequest(
          request.requestId,
        );
      },
      secondButtonText: l10n.cancel,
      onSecondButtonPressed: () => Navigator.of(context).pop(),
    );
  }

  void _showDeleteRequestErrorDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppFailure failure,
  ) {
    final message = failure.when(
      network: (_, _) => l10n.networkError,
      notFound: (_) => l10n.genericError,
      forbidden: () => l10n.genericError,
      unauthorized: () => l10n.genericError,
      conflict: (_) => l10n.genericError,
      business: (_) => l10n.genericError,
      serialization: (_) => l10n.genericError,
      unknown: (_) => l10n.genericError,
    );

    CustomDialog.show(
      context: context,
      title: l10n.cancelRequestErrorTitle,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      buttonText: l10n.accept,
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Trusted contacts list
  // ---------------------------------------------------------------------------
  Widget _buildContactsList(AppLocalizations l10n, TrustedContactsState state) {
    // TODO: replace with real loading state and error handling from cubit
    if (state.failure != null) {
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

  // ---------------------------------------------------------------------------
  // Tab 2 — Sent requests
  // ---------------------------------------------------------------------------

  Widget _buildPendingList(
    BuildContext context,
    AppLocalizations l10n,
    TrustedContactsState state,
  ) {
    if (state.isLoadingSentRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sentRequestsFailure != null) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (state.sentRequests.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noPendingRequestsTitle,
        description: l10n.noPendingRequestsDescription,
      );
    }

    final filtered = _pendingQuery.isEmpty
        ? state.sentRequests
        : state.sentRequests
              .where(
                (r) => r.peerUsername.toLowerCase().contains(
                  _pendingQuery.toLowerCase(),
                ),
              )
              .toList();

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
          if (filtered.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ...filtered.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserListItem(
                  username: request.peerUsername,
                  profilePhoto: request.peerPhoto,
                  onProfileTap: () {},
                  onDelete: () =>
                      _showDeleteRequestDialog(context, l10n, request),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<TrustedContactsCubit, TrustedContactsState>(
          listenWhen: (prev, curr) => curr.sendRequestFailure != null,
          listener: (context, state) {
            context.read<TrustedContactsCubit>().clearSendRequestFailure();
            _showSendRequestErrorDialog(
              context,
              l10n,
              state.sendRequestFailure!,
            );
          },
        ),
        BlocListener<TrustedContactsCubit, TrustedContactsState>(
          listenWhen: (prev, curr) => curr.deleteRequestFailure != null,
          listener: (context, state) {
            context.read<TrustedContactsCubit>().clearDeleteRequestFailure();
            _showDeleteRequestErrorDialog(
              context,
              l10n,
              state.deleteRequestFailure!,
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: BlocBuilder<TrustedContactsCubit, TrustedContactsState>(
            builder: (context, state) {
              return Column(
                children: [
                  SectionHeader(text: l10n.yourTrustedContacts),

                  // Section 1: user code + add contact
                  Container(
                    width: double.infinity,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.30,
                          ),
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
                        CopyableCodeField(
                          code: state.isLoading
                              ? '...'
                              : (state.username.orDash()),
                        ),
                        const SizedBox(height: 16),
                        SectionButton(
                          icon: Icons.person_add_outlined,
                          text: l10n.addTrustedContact,
                          showArrow: false,
                          onPressed: () =>
                              _showSendRequestDialog(context, l10n),
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
                      children: [
                        _buildContactsList(l10n, state),
                        _buildPendingList(context, l10n, state),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
