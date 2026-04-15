import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/cubits/guardian_mode_cubit.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/widgets/guardian_mode_map.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];

  /// Duration estimated by the map widget (OSRM or fallback), used for the suggestion.
  Duration? _estimatedDuration;

  /// Incremented to force recreation of [DurationInputField] and [InputField]
  int _durationResetKey = 0;
  int _descriptionResetKey = 0;

  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    context.read<GuardianModeCubit>().loadSessionState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {
      // Permission already granted (enforced by navigation guard) — ignore.
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==============================================
  // MARK: - Cubit state transitions
  // ==============================================

  void _onCubitStateChanged(
    BuildContext context,
    GuardianModeCubitState state,
  ) {
    // Activation succeeded: show confirmation dialog and reset form widgets.
    if (!state.isActivating && state.activeSession != null) {
      _showActivationConfirmationDialog(context);
      _scrollToTop();
      setState(() {
        _estimatedDuration = null;
        _durationResetKey++;
        _descriptionResetKey++;
      });
    }

    // Activation failed: show error dialog.
    if (state.activateFailure != null) {
      _showActivateErrorDialog(context, state.activateFailure!);
      context.read<GuardianModeCubit>().consumeActivateFailure();
    }

    // Completion succeeded: show confirmation dialog and reset form.
    if (!state.isCompleting &&
        state.activeSession == null &&
        state.completeFailure == null) {
      _showCompletionConfirmationDialog(context);
      setState(() {
        _routePoints = [];
        _estimatedDuration = null;
        _durationResetKey++;
        _descriptionResetKey++;
      });
      _scrollToTop();
    }

    // Completion failed: show error dialog.
    if (state.completeFailure != null) {
      _showCompleteErrorDialog(context);
      context.read<GuardianModeCubit>().consumeCompleteFailure();
    }
  }

  void _showActivateErrorDialog(BuildContext context, AppFailure failure) {
    final l10n = context.l10n;
    final isConflict = failure is ConflictFailure;
    CustomDialog.show(
      context: context,
      title: isConflict
          ? l10n.guardianModeAlreadyActiveTitle
          : l10n.guardianModeActivateErrorTitle,
      content: Text(
        isConflict
            ? l10n.guardianModeAlreadyActiveContent
            : l10n.guardianModeActivateErrorContent,
      ),
      buttonText: l10n.accept,
    );
  }

  void _showCompleteErrorDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeCompleteErrorTitle,
      content: Text(l10n.guardianModeCompleteErrorContent),
      buttonText: l10n.accept,
    );
  }

  // ==============================================
  // MARK: - Dialogs
  // ==============================================

  void _showInfoDialog(AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.guardianMode,
      content: Text(l10n.guardianModeInfoContent),
      buttonText: l10n.accept,
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  void _showMissingDataDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeMissingDataTitle,
      content: Text(l10n.guardianModeMissingDataContent),
      buttonText: l10n.accept,
    );
  }

  void _showEstimatedTimeDialog(
    BuildContext context,
    AppLocalizations l10n,
    GuardianModeCubitState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<GuardianModeCubit>();

    // Use the map-computed estimate; fall back to straight-line calculation.
    final Duration estimated;
    if (_estimatedDuration != null) {
      estimated = _estimatedDuration!;
    } else if (_currentLocation != null && state.pendingDestination != null) {
      const walkSpeedMs = 5000.0 / 3600.0;
      final distMeters = const Distance()(
        _currentLocation!,
        LatLng(
          state.pendingDestination!.latitude,
          state.pendingDestination!.longitude,
        ),
      );
      estimated = Duration(seconds: (distMeters / walkSpeedMs * 1.25).round());
    } else {
      estimated = Duration.zero;
    }

    CustomDialog.show(
      context: context,
      title: l10n.guardianModeEstimatedTimeDialogTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.guardianModeEstimatedTimeDialogContent),
          const SizedBox(height: 14),
          Text(
            l10n.guardianModeEstimatedTimeLabel,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _formatDuration(estimated),
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      buttonText: l10n.guardianModeActivate,
      onButtonPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        cubit.updatePendingDuration(estimated);
        setState(() => _durationResetKey++);
        if (_currentLocation != null) {
          cubit.activateSession(
            initialLocation: GuardianCoordinate(
              latitude: _currentLocation!.latitude,
              longitude: _currentLocation!.longitude,
            ),
          );
        }
      },
      secondButtonText: l10n.cancel,
    );
  }

  void _onActivatePressed(
    BuildContext context,
    AppLocalizations l10n,
    GuardianModeCubitState state,
  ) {
    final hasDuration =
        state.pendingDuration != null && state.pendingDuration!.inMinutes > 0;
    final hasDestination = state.pendingDestination != null;

    if (!hasDestination && !hasDuration) {
      _showMissingDataDialog(context, l10n);
    } else if (hasDestination && !hasDuration) {
      _showEstimatedTimeDialog(context, l10n, state);
    } else if (_currentLocation != null) {
      context.read<GuardianModeCubit>().activateSession(
        initialLocation: GuardianCoordinate(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
        ),
      );
    }
  }

  void _showActivationConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeActivated,
      content: Text(l10n.guardianModeActivatedDescription),
      buttonText: l10n.accept,
    );
  }

  void _showCompletionConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeCompleteSuccessTitle,
      content: Text(l10n.guardianModeCompleteSuccessContent),
      buttonText: l10n.accept,
    );
  }

  void _showArrivalConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeConfirmArrival,
      content: Text(l10n.guardianModeArrivalDescription),
      buttonText: l10n.guardianModeConfirmArrival,
      onInputButtonPressed: (justification) {
        Navigator.of(context, rootNavigator: true).pop();
        context.read<GuardianModeCubit>().completeSession(
          completionStatus: GuardianSessionSecondaryStatus.completedByArrival,
          completionJustification: justification.trim().isEmpty
              ? null
              : justification.trim(),
        );
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.guardianModeJustification,
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeCancel,
      content: Text(l10n.guardianModeCancelDescription),
      buttonText: l10n.guardianModeCancel,
      onInputButtonPressed: (justification) {
        Navigator.of(context, rootNavigator: true).pop();
        context.read<GuardianModeCubit>().completeSession(
          completionStatus:
              GuardianSessionSecondaryStatus.completedByCancellation,
          completionJustification: justification.trim().isEmpty
              ? null
              : justification.trim(),
        );
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.guardianModeJustification,
    );
  }

  void _showFutureDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.notAvailableYet,
      content: Text(l10n.futureUpdateContent),
      buttonText: l10n.accept,
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Divider(height: 20),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStatusBanner(
    bool isActive,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final backgroundColor = isActive
        ? colorScheme.tertiary.withValues(alpha: 0.12)
        : colorScheme.onSurface.withValues(alpha: 0.06);
    final iconColor = isActive
        ? colorScheme.tertiary
        : colorScheme.onSurface.withValues(alpha: 0.4);
    final textColor = isActive
        ? colorScheme.tertiary
        : colorScheme.onSurface.withValues(alpha: 0.5);
    final icon = isActive ? Icons.shield_rounded : Icons.shield_outlined;
    final label = isActive
        ? l10n.guardianModeStatusActive
        : l10n.guardianModeStatusInactive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.tertiary
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    bool isActive,
    bool isActivating,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    GuardianModeCubitState state,
  ) {
    if (isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            CustomFilledButton(
              text: l10n.guardianModeConfirmArrival,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => _showArrivalConfirmationDialog(context),
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              colorText: colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            CustomFilledButton(
              text: l10n.guardianModeCancel,
              icon: Icons.cancel_outlined,
              onPressed: () => _showCancelConfirmationDialog(context),
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              colorText: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: double.infinity,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.guardianModeActivate,
        icon: Icons.shield_outlined,
        isLoading: isActivating,
        onPressed: () => _onActivatePressed(context, l10n, state),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        colorText: colorScheme.onTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        width: double.infinity,
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
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<GuardianModeCubit, GuardianModeCubitState>(
      listenWhen: (prev, curr) =>
          (prev.isActivating && !curr.isActivating) ||
          (curr.activateFailure != null && prev.activateFailure == null) ||
          (prev.isCompleting && !curr.isCompleting) ||
          (curr.completeFailure != null && prev.completeFailure == null),
      listener: _onCubitStateChanged,
      builder: (context, state) {
        final isActive = state.activeSession != null;
        final activeSession = state.activeSession;
        final pendingDest = state.pendingDestination;
        final LatLng? destinationPoint =
            isActive && activeSession?.destination != null
            ? LatLng(
                activeSession!.destination!.latitude,
                activeSession.destination!.longitude,
              )
            : pendingDest != null
            ? LatLng(pendingDest.latitude, pendingDest.longitude)
            : null;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              SectionHeader(
                text: l10n.guardianMode,
                trailingIcon: Icons.info_outline_rounded,
                onTrailingIconPressed: () => _showInfoDialog(l10n),
              ),

              Expanded(
                child: (_currentLocation == null || state.isLoadingSession)
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        behavior: HitTestBehavior.opaque,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status
                              _buildSectionTitle(
                                l10n.status,
                                textTheme,
                                colorScheme,
                              ),
                              _buildStatusBanner(
                                isActive,
                                l10n,
                                colorScheme,
                                textTheme,
                              ),

                              // Route / Destination
                              _buildSectionTitle(
                                l10n.guardianModeRouteSection,
                                textTheme,
                                colorScheme,
                              ),
                              GuardianModeMap(
                                currentLocation: _currentLocation!,
                                destinationPoint: destinationPoint,
                                routePoints: _routePoints,
                                isActive: isActive,
                                l10n: l10n,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                onDestinationChanged: isActive
                                    ? null
                                    : (point) {
                                        context
                                            .read<GuardianModeCubit>()
                                            .updatePendingDestination(
                                              GuardianCoordinate(
                                                latitude: point.latitude,
                                                longitude: point.longitude,
                                              ),
                                            );
                                      },
                                onRouteChanged: (points) =>
                                    setState(() => _routePoints = points),
                                onEstimatedDurationChanged: isActive
                                    ? null
                                    : (d) => setState(
                                        () => _estimatedDuration = d,
                                      ),
                              ),

                              // Estimated time
                              _buildSectionTitle(
                                l10n.guardianModeEstimatedTimeSection,
                                textTheme,
                                colorScheme,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: DurationInputField(
                                  key: ValueKey(
                                    'dur_${activeSession?.id}_$_durationResetKey',
                                  ),
                                  hint: l10n.guardianModeEstimatedTimeHint,
                                  readOnly: isActive,
                                  initialValue: isActive
                                      ? activeSession?.estimatedDuration
                                      : state.pendingDuration,
                                  onChanged: isActive
                                      ? null
                                      : (d) => context
                                            .read<GuardianModeCubit>()
                                            .updatePendingDuration(d),
                                ),
                              ),

                              // Description
                              _buildSectionTitle(
                                l10n.guardianModeDescriptionSection,
                                textTheme,
                                colorScheme,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: InputField(
                                  key: ValueKey(
                                    'desc_${activeSession?.id}_$_descriptionResetKey',
                                  ),
                                  hint: l10n.guardianModeDescriptionHint,
                                  maxLines: 3,
                                  readOnly: isActive,
                                  initialValue: isActive
                                      ? activeSession?.description
                                      : state.pendingDescription,
                                  onChanged: isActive
                                      ? null
                                      : (v) => context
                                            .read<GuardianModeCubit>()
                                            .updatePendingDescription(v),
                                ),
                              ),

                              // Action buttons
                              const SizedBox(height: 28),
                              _buildActionButtons(
                                isActive,
                                state.isActivating,
                                l10n,
                                colorScheme,
                                state,
                              ),
                              const SizedBox(height: 35),

                              // Customization options
                              SettingsOptionsList(
                                horizontalPadding: 24,
                                sectionTitle: l10n.customization,
                                options: [
                                  SettingsOption(
                                    icon: Icons.settings_outlined,
                                    title: l10n.featuresSettings,
                                    description:
                                        l10n.guardianModeSettingsDescription,
                                    onPressed: () =>
                                        _showFutureDialog(context, l10n),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
