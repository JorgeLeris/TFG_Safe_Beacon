import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/helpers/helpers.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';
import 'package:safe_beacon/presentation/features/control/routes/control_routes.dart';
import 'package:safe_beacon/presentation/features/control/widgets/alert_list_header.dart';
import 'package:safe_beacon/presentation/features/control/widgets/follow_up_list_header.dart';
import 'package:safe_beacon/presentation/features/profile/routes/profile_routes.dart';
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

  Key _followUpsSearchKey = UniqueKey();
  String _followUpsQuery = '';

  // Current filters applied to the follow-ups list
  FollowUpFilters _followUpFilters = const FollowUpFilters();

  // TODO(follow-ups): Replace with data from service and manage error from service too.
  static final List<FollowUpItem> _mockFollowUps = [
    FollowUpItem(
      uid: 'mock-uid-1',
      username: 'maria_garcia',
      isActive: true,
      secondaryTags: [FollowUpSecondaryTag.routeDeviation],
      dateTime: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    FollowUpItem(
      uid: 'mock-uid-2',
      username: 'carlos_lopez',
      isActive: false,
      secondaryTags: [FollowUpSecondaryTag.completionByArrival],
      dateTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    ),
    FollowUpItem(
      uid: 'mock-uid-3',
      username: 'ana_martinez',
      isActive: true,
      secondaryTags: [
        FollowUpSecondaryTag.routeDeviation,
        FollowUpSecondaryTag.estimatedTimeExceeded,
      ],
      dateTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
    ),
    FollowUpItem(
      uid: 'mock-uid-4',
      username: 'pedro_sanchez',
      isActive: false,
      secondaryTags: [FollowUpSecondaryTag.completionByCancellation],
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    FollowUpItem(
      uid: 'mock-uid-5',
      username: 'lucia_fernandez',
      isActive: false,
      secondaryTags: [
        FollowUpSecondaryTag.estimatedTimeExceeded,
        FollowUpSecondaryTag.completionByArrival,
      ],
      dateTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ControlCubit>();
    cubit.loadReceivedRequestsCount();
    cubit.loadAlerts();
  }

  void _onTabChanged(int index) {
    setState(() {
      _alertsSearchKey = UniqueKey();
      _alertsQuery = '';
      _followUpsSearchKey = UniqueKey();
      _followUpsQuery = '';
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ---------------------------------------------------------------------------
  // Alert mapping helpers
  // ---------------------------------------------------------------------------

  /// Converts domain [AlertType] to the filter key used by [AlertFunctionalityFilter].
  bool _matchesFunctionalityFilter(
    AlertType type,
    AlertFunctionalityFilter filter,
  ) {
    return switch (filter) {
      AlertFunctionalityFilter.all => true,
      AlertFunctionalityFilter.panicButton => type == AlertType.panic,
      AlertFunctionalityFilter.guardianMode => type == AlertType.guardian,
    };
  }

  List<Alert> _applyFilters(List<Alert> alerts) {
    return alerts.where((alert) {
      final passesStatus = switch (_alertFilters.status) {
        AlertStatusFilter.all => true,
        AlertStatusFilter.active => alert.status == AlertStatus.active,
        AlertStatusFilter.inactive => alert.status == AlertStatus.deactivated,
      };

      final passesFunctionality = _matchesFunctionalityFilter(
        alert.alertType,
        _alertFilters.functionality,
      );

      return passesStatus && passesFunctionality;
    }).toList();
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
    ControlState state,
  ) {
    if (state.isApplyingFilters || state.isLoadingAlerts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.alertsFailure != null) {
      return EmptyStateView(
        type: EmptyStateType.error,
        title: l10n.errorTitle,
        description: l10n.errorDescription,
      );
    }

    if (state.alerts.isEmpty) {
      return EmptyStateView(
        type: EmptyStateType.empty,
        title: l10n.noAlertsTitle,
        description: l10n.noAlertsDescription,
      );
    }

    // Apply active filters, then the search query
    final afterFilters = _applyFilters(state.alerts);
    final filtered = _alertsQuery.isEmpty
        ? afterFilters
        : afterFilters.where((a) {
            final displayName =
                state.alertDisplayNames[a.ownerUid] ?? a.ownerUsername;
            return displayName.toLowerCase().contains(
              _alertsQuery.toLowerCase(),
            );
          }).toList();

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
            ...filtered.map((alert) {
              final displayName =
                  (state.alertDisplayNames[alert.ownerUid] ??
                          alert.ownerUsername)
                      .capitalized();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AlertListItem(
                  alert: AlertItem(
                    alertType: AlertHelper.alertTypeLabelComplete(
                      alert.alertType,
                      l10n,
                    ),
                    username: displayName,
                    profilePhoto: state.alertProfilePhotos[alert.ownerUid],
                    isActive: alert.status == AlertStatus.active,
                    dateTime: alert.activatedAt,
                  ),
                  onTap: () {
                    AlertDetailRoute(alertId: alert.id).push(context);
                  },
                  onProfileTap: () {
                    OtherProfileRoute(uid: alert.ownerUid).push(context);
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab — Follow-ups
  // ---------------------------------------------------------------------------

  List<FollowUpItem> _applyFollowUpFilters(List<FollowUpItem> followUps) {
    return followUps.where((f) {
      final passesStatus = switch (_followUpFilters.status) {
        FollowUpStatusFilter.all => true,
        FollowUpStatusFilter.active => f.isActive,
        FollowUpStatusFilter.finished => !f.isActive,
      };

      final passesEvent = switch (_followUpFilters.event) {
        FollowUpEventFilter.all => true,
        FollowUpEventFilter.routeDeviation => f.secondaryTags.contains(
          FollowUpSecondaryTag.routeDeviation,
        ),
        FollowUpEventFilter.estimatedTimeExceeded => f.secondaryTags.contains(
          FollowUpSecondaryTag.estimatedTimeExceeded,
        ),
      };

      final passesCompletion = switch (_followUpFilters.completion) {
        FollowUpCompletionFilter.all => true,
        FollowUpCompletionFilter.completionByArrival =>
          f.secondaryTags.contains(FollowUpSecondaryTag.completionByArrival),
        FollowUpCompletionFilter.completionByCancellation =>
          f.secondaryTags.contains(
            FollowUpSecondaryTag.completionByCancellation,
          ),
      };

      return passesStatus && passesEvent && passesCompletion;
    }).toList();
  }

  Future<void> _applyFollowUpFiltersWithLoading(FollowUpFilters filters) async {
    // TODO(follow-ups): Replace with cubit call.
    setState(() => _followUpFilters = filters);
  }

  void _openFollowUpFilterDialog() {
    FollowUpFilterDialog.show(
      context: context,
      initialFilters: _followUpFilters,
      onApply: _applyFollowUpFiltersWithLoading,
    );
  }

  Widget _buildFollowUpsList(BuildContext context, AppLocalizations l10n) {
    final afterFilters = _applyFollowUpFilters(_mockFollowUps);
    final filtered = _followUpsQuery.isEmpty
        ? afterFilters
        : afterFilters
              .where(
                (f) => f.username.toLowerCase().contains(
                  _followUpsQuery.toLowerCase(),
                ),
              )
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Counter + filter button
          FollowUpsListHeader(
            followUpCount: afterFilters.length,
            activeFilterCount: _followUpFilters.activeCount,
            onFilterTap: _openFollowUpFilterDialog,
          ),

          const SizedBox(height: 12),

          // Search field
          SearchInputField(
            key: _followUpsSearchKey,
            hint: l10n.searchContact,
            onChanged: (q) => setState(() => _followUpsQuery = q),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(height: 30),
          ),

          if (_mockFollowUps.isEmpty)
            EmptyStateView(
              type: EmptyStateType.empty,
              title: l10n.noFollowUpsTitle,
              description: l10n.noFollowUpsDescription,
            )
          else if (filtered.isEmpty)
            EmptyStateView(
              type: EmptyStateType.noResults,
              title: l10n.noResultsTitle,
              description: l10n.noResultsDescription,
            )
          else
            ...filtered.map((followUp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FollowUpListItem(
                  followUp: followUp,
                  onTap: () {
                    const FollowUpDetailRoute().push(context);
                  },
                  onProfileTap: () {
                    OtherProfileRoute(uid: followUp.uid).push(context);
                  },
                ),
              );
            }),
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
                  onRefresh: () async {
                    await Future.wait([
                      context.read<ControlCubit>().loadReceivedRequestsCount(),
                      context.read<ControlCubit>().loadAlerts(),
                    ]);
                  },
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
                      _buildAlertsList(context, l10n, state),
                      _buildFollowUpsList(context, l10n),
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
