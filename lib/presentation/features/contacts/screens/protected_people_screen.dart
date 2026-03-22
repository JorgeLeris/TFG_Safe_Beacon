import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request_item.dart';
import 'package:safe_beacon/presentation/features/contacts/cubits/protected_people_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ProtectedPeopleScreen extends StatefulWidget {
  const ProtectedPeopleScreen({super.key});

  @override
  State<ProtectedPeopleScreen> createState() => _ProtectedPeopleScreenState();
}

class _ProtectedPeopleScreenState extends State<ProtectedPeopleScreen> {
  Key _protectedPeopleSearchKey = UniqueKey();
  Key _requestsReceivedSearchKey = UniqueKey();

  String _protectedPeopleQuery = '';
  String _requestsReceivedQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ProtectedPeopleCubit>().loadUserCode();
    context.read<ProtectedPeopleCubit>().loadProtectedPeople();
    context.read<ProtectedPeopleCubit>().loadReceivedRequests();
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

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showDeleteContactDialog(
    BuildContext context,
    AppLocalizations l10n,
    ContactRequestItem contact,
  ) {
    CustomDialog.show(
      context: context,
      title: l10n.deleteContact,
      content: Text(
        l10n.deleteContactDescription(contact.peerUsername),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      buttonText: l10n.accept,
      onButtonPressed: () {
        Navigator.of(context).pop();
        context.read<ProtectedPeopleCubit>().deleteContact(contact.requestId);
      },
      secondButtonText: l10n.cancel,
      onSecondButtonPressed: () => Navigator.of(context).pop(),
    );
  }

  void _showDeleteContactErrorDialog(
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
      title: l10n.deleteContactErrorTitle,
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
      title: l10n.declineRequest,
      content: Text(
        l10n.declineRequestDescription(request.peerUsername),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      buttonText: l10n.accept,
      onButtonPressed: () {
        Navigator.of(context).pop();
        context.read<ProtectedPeopleCubit>().deleteReceivedRequest(
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
      title: l10n.declineRequestErrorTitle,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      buttonText: l10n.accept,
    );
  }

  void _showAcceptRequestDialog(
    BuildContext context,
    AppLocalizations l10n,
    ContactRequestItem request,
  ) {
    CustomDialog.show(
      context: context,
      title: l10n.acceptRequest,
      content: Text(
        l10n.acceptRequestDescription(request.peerUsername),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      buttonText: l10n.accept,
      onButtonPressed: () {
        Navigator.of(context).pop();
        context.read<ProtectedPeopleCubit>().acceptRequest(request);
      },
      secondButtonText: l10n.cancel,
      onSecondButtonPressed: () => Navigator.of(context).pop(),
    );
  }

  void _showAcceptRequestErrorDialog(
    BuildContext context,
    AppLocalizations l10n,
    AppFailure failure,
  ) {
    final message = failure.when(
      network: (_, _) => l10n.networkError,
      conflict: (_) => l10n.contactAlreadyExists,
      notFound: (_) => l10n.genericError,
      forbidden: () => l10n.genericError,
      unauthorized: () => l10n.genericError,
      business: (_) => l10n.genericError,
      serialization: (_) => l10n.genericError,
      unknown: (_) => l10n.genericError,
    );

    CustomDialog.show(
      context: context,
      title: l10n.acceptRequestErrorTitle,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      buttonText: l10n.accept,
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1 — Protected people list
  // ---------------------------------------------------------------------------

  Widget _buildProtectedPeopleList(
    BuildContext context,
    AppLocalizations l10n,
    ProtectedPeopleState state,
  ) {
    if (state.isLoadingProtectedPeople) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.protectedPeopleFailure != null) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (state.protectedPeople.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noProtectedPeopleTitle,
        description: l10n.noProtectedPeopleDescription,
      );
    }

    final filtered = _protectedPeopleQuery.isEmpty
        ? state.protectedPeople
        : state.protectedPeople
              .where(
                (p) => p.peerUsername.toLowerCase().contains(
                  _protectedPeopleQuery.toLowerCase(),
                ),
              )
              .toList();

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
          if (filtered.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ...filtered.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserListItem(
                  username: contact.peerUsername,
                  profilePhoto: contact.peerPhoto,
                  onProfileTap: () {},
                  onDelete: () =>
                      _showDeleteContactDialog(context, l10n, contact),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2 — Received requests
  // ---------------------------------------------------------------------------

  Widget _buildRequestsReceivedList(
    BuildContext context,
    AppLocalizations l10n,
    ProtectedPeopleState state,
  ) {
    if (state.isLoadingReceivedRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.receivedRequestsFailure != null) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (state.receivedRequests.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noReceivedRequestsTitle,
        description: l10n.noReceivedRequestsDescription,
      );
    }

    final filtered = _requestsReceivedQuery.isEmpty
        ? state.receivedRequests
        : state.receivedRequests
              .where(
                (r) => r.peerUsername.toLowerCase().contains(
                  _requestsReceivedQuery.toLowerCase(),
                ),
              )
              .toList();

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
                  onAccept: () =>
                      _showAcceptRequestDialog(context, l10n, request),
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
        BlocListener<ProtectedPeopleCubit, ProtectedPeopleState>(
          listenWhen: (prev, curr) => curr.deleteContactFailure != null,
          listener: (context, state) {
            context.read<ProtectedPeopleCubit>().clearDeleteContactFailure();
            _showDeleteContactErrorDialog(
              context,
              l10n,
              state.deleteContactFailure!,
            );
          },
        ),
        BlocListener<ProtectedPeopleCubit, ProtectedPeopleState>(
          listenWhen: (prev, curr) => curr.deleteRequestFailure != null,
          listener: (context, state) {
            context.read<ProtectedPeopleCubit>().clearDeleteRequestFailure();
            _showDeleteRequestErrorDialog(
              context,
              l10n,
              state.deleteRequestFailure!,
            );
          },
        ),
        BlocListener<ProtectedPeopleCubit, ProtectedPeopleState>(
          listenWhen: (prev, curr) => curr.acceptRequestFailure != null,
          listener: (context, state) {
            context.read<ProtectedPeopleCubit>().clearAcceptRequestFailure();
            _showAcceptRequestErrorDialog(
              context,
              l10n,
              state.acceptRequestFailure!,
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
          child: BlocBuilder<ProtectedPeopleCubit, ProtectedPeopleState>(
            builder: (context, state) {
              return Column(
                children: [
                  SectionHeader(text: l10n.yourProtectedPeople),

                  // Section 1: user code
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
                      ],
                    ),
                  ),

                  // Section 2: tabs
                  Expanded(
                    child: CustomTabView(
                      tabs: [l10n.protectedPeople, l10n.requestsReceived],
                      onTabChanged: _onTabChanged,
                      children: [
                        _buildProtectedPeopleList(context, l10n, state),
                        _buildRequestsReceivedList(context, l10n, state),
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
