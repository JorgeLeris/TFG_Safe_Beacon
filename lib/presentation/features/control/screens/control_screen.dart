import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';
import 'package:safe_beacon/presentation/features/control/routes/control_routes.dart';
import 'package:safe_beacon/presentation/features/control/widgets/alert_list_header.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  Key _alertsSearchKey = UniqueKey();
  String _alertsQuery = '';

  // Current filters applied to the alerts list
  AlertFilters _alertFilters = const AlertFilters();

  // ---------------------------------------------------------------------------
  // TODO: replace _mockedAlerts with real data from cubit/bloc
  // ---------------------------------------------------------------------------

  final List<AlertItem> _mockedAlerts = [
    AlertItem(
      alertType: Constants.panicButtonAlertTypeKey,
      username: 'maria_garcia',
      isActive: true,
      dateTime: DateTime(2025, 6, 12, 14, 32),
    ),
    AlertItem(
      alertType: Constants.panicButtonAlertTypeKey,
      username: 'carlos_lopez',
      isActive: false,
      dateTime: DateTime(2025, 6, 10, 9, 15),
    ),
    AlertItem(
      alertType: Constants.panicButtonAlertTypeKey,
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

  void _onTabChanged(int index) {
    setState(() {
      _alertsSearchKey = UniqueKey();
      _alertsQuery = '';
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ---------------------------------------------------------------------------
  // Filter helpers
  // ---------------------------------------------------------------------------

  List<AlertItem> _applyFilters(List<AlertItem> alerts) {
    return alerts.where((alert) {
      // Status filter
      final passesStatus = switch (_alertFilters.status) {
        AlertStatusFilter.all => true,
        AlertStatusFilter.active => alert.isActive,
        AlertStatusFilter.inactive => !alert.isActive,
      };

      // Functionality filter
      final passesFunctionality = switch (_alertFilters.functionality) {
        AlertFunctionalityFilter.all => true,
        AlertFunctionalityFilter.panicButton =>
          alert.alertType == Constants.panicButtonAlertTypeKey,
        AlertFunctionalityFilter.guardianMode =>
          alert.alertType == Constants.guardianModeAlertTypeKey,
      };

      return passesStatus && passesFunctionality;
    }).toList();
  }

  String _getAlertTypeLabel(String alertTypeKey, AppLocalizations l10n) {
    return switch (alertTypeKey) {
      Constants.panicButtonAlertTypeKey => l10n.alertOfFeature(
        l10n.panicButton,
      ),
      Constants.guardianModeAlertTypeKey => l10n.alertOfFeature(
        l10n.guardianMode,
      ),
      _ => alertTypeKey,
    };
  }

  Future<void> _applyFiltersWithLoading(AlertFilters filters) async {
    await context.read<ControlCubit>().applyFiltersWithLoading();
    if (!mounted) return;
    setState(() => _alertFilters = filters);
  }

  void _openFilterDialog() {
    AlertFilterDialog.show(
      context: context,
      initialFilters: _alertFilters,
      onApply: _applyFiltersWithLoading,
    );
  }

  // ---------------------------------------------------------------------------
  // Tab — Alerts
  // ---------------------------------------------------------------------------

  Widget _buildAlertsList(
    BuildContext context,
    AppLocalizations l10n,
    bool isApplyingFilters,
  ) {
    if (isApplyingFilters) {
      return const Center(child: CircularProgressIndicator());
    }

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

    // Apply active filters, then the search query
    final afterFilters = _applyFilters(_mockedAlerts);
    final filtered = _alertsQuery.isEmpty
        ? afterFilters
        : afterFilters
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
          // Counter + filter button
          AlertsListHeader(
            alertCount: afterFilters.length,
            activeFilterCount: _alertFilters.activeCount,
            onFilterTap: _openFilterDialog,
          ),

          const SizedBox(height: 12),

          // Search field
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
                  alert: AlertItem(
                    alertType: _getAlertTypeLabel(alert.alertType, l10n),
                    username: alert.username,
                    profilePhoto: alert.profilePhoto,
                    isActive: alert.isActive,
                    dateTime: alert.dateTime,
                  ),
                  onTap: () {
                    const AlertDetailRoute().push(context);
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
                    onTabChanged: _onTabChanged,
                    children: [
                      _buildAlertsList(context, l10n, state.isApplyingFilters),
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
