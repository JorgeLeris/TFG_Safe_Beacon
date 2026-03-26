import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final Key _alertsSearchKey = UniqueKey();
  String _alertsQuery = '';

  // ---------------------------------------------------------------------------
  // TODO: replace _mockedAlerts with real data from cubit/bloc
  // Mocked alerts data
  // ---------------------------------------------------------------------------

  final List<AlertItem> _mockedAlerts = [
    AlertItem(
      alertType: 'Alerta botón del pánico',
      username: 'maria_garcia',
      isActive: true,
      dateTime: DateTime(2025, 6, 12, 14, 32),
    ),
    AlertItem(
      alertType: 'Alerta botón del pánico',
      username: 'carlos_lopez',
      isActive: false,
      dateTime: DateTime(2025, 6, 10, 9, 15),
    ),
    AlertItem(
      alertType: 'Alerta botón del pánico',
      username: 'ana_martinez',
      isActive: true,
      dateTime: DateTime(2025, 6, 11, 22, 48),
    ),
  ];

  final bool mockedHasError = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    context.read<ControlCubit>().loadReceivedRequestsCount();
  }

  // ---------------------------------------------------------------------------
  // Tab — Alerts
  // ---------------------------------------------------------------------------

  Widget _buildAlertsList(BuildContext context, AppLocalizations l10n) {
    final bool isEmpty = _mockedAlerts.isEmpty;

    if (mockedHasError) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noAlertsTitle,
        description: l10n.noAlertsDescription,
      );
    }

    final filtered = _alertsQuery.isEmpty
        ? _mockedAlerts
        : _mockedAlerts
              .where(
                (a) => a.username.toLowerCase().contains(
                  _alertsQuery.toLowerCase(),
                ),
              )
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SearchInputField(
            key: _alertsSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _alertsQuery = q),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 30),
          ),
          if (filtered.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ...filtered.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlertListItem(
                  alert: alert,
                  onTap: () {
                    // TODO: navigate to alert detail
                  },
                  onProfileTap: () {
                    // TODO: navigate to user profile
                  },
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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: BlocBuilder<ControlCubit, ControlState>(
          builder: (context, state) {
            return Column(
              children: [
                SectionHeader(
                  text: l10n.headerControl,
                  onRefresh: () =>
                      context.read<ControlCubit>().loadReceivedRequestsCount(),
                ),

                // Section 1: contacts button
                Container(
                  width: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.30,
                        ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionButton(
                        icon: Icons.group_outlined,
                        text: l10n.yourProtectedPeople,
                        onPressed: () {
                          const ProtectedPeopleRoute().push(context).then((_) {
                            if (context.mounted) {
                              context
                                  .read<ControlCubit>()
                                  .loadReceivedRequestsCount();
                            }
                          });
                        },
                        backgroundColor: colorScheme.secondary,
                        contentColor: colorScheme.onSecondary,
                        notificationCount: state.receivedRequestsCount,
                      ),
                    ],
                  ),
                ),

                // Section 2: tabs
                Expanded(
                  child: CustomTabView(
                    tabs: [l10n.alerts, l10n.followUps, l10n.history],
                    children: [
                      _buildAlertsList(context, l10n),
                      const Placeholder(),
                      const Placeholder(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
