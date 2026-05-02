import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/presentation/features/fall_detection/cubits/fall_detection_cubit.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

/// Card shown on the home screen that controls automatic fall detection.
///
/// Reads its state from [FallDetectionCubit] which must be provided above
/// this widget in the tree (via [FallDetectionProvider]).
class FallDetectionCard extends StatelessWidget {
  const FallDetectionCard({super.key});

  // ==============================================
  // MARK: - Dialog
  // ==============================================

  void _showDeactivateDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.fallDetectionDeactivateTitle,
      content: Text(l10n.fallDetectionDeactivateContent),
      buttonText: l10n.fallDetectionDeactivateButton,
      onInputButtonPressed: (justification) {
        Navigator.of(context, rootNavigator: true).pop();
        context.read<FallDetectionCubit>().deactivate(reason: justification);
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.fallDetectionJustificationHint,
    );
  }

  void _showDisabledDialog(
    BuildContext context,
    FallDetectionDisabledReason reason,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<FallDetectionCubit>();
    switch (reason) {
      case FallDetectionDisabledReason.noTrustedContacts:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonNoContactsTitle,
          content: Text(l10n.panicButtonNoContactsContent),
          buttonText: l10n.panicButtonNoContactsButton,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.loadState();
          },
        );
      case FallDetectionDisabledReason.locationPermissionDenied:
        cubit.requestLocationPermission();
      case FallDetectionDisabledReason.locationPermissionDeniedForever:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonPermissionDeniedTitle,
          content: Text(l10n.panicButtonPermissionDeniedContent),
          buttonText: l10n.panicButtonPermissionDeniedButton,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.openLocationSettings();
          },
          secondButtonText: l10n.cancel,
        );
    }
  }

  // ==============================================
  // MARK: - Switch interaction
  // ==============================================

  void _handleSwitchTap(
    BuildContext context,
    FallDetectionCubitState state,
  ) {
    final cubit = context.read<FallDetectionCubit>();
    switch (state.status) {
      case FallDetectionStatus.inactive:
        // Activate: start background service.
        final locale = Localizations.localeOf(context).languageCode;
        cubit.activate(locale);
      case FallDetectionStatus.active:
      case FallDetectionStatus.alertActive:
        // Deactivate: show confirmation dialog.
        _showDeactivateDialog(context);
      case FallDetectionStatus.disabled:
        // Show explanation for why it's disabled.
        if (state.disabledReason != null) {
          _showDisabledDialog(context, state.disabledReason!);
        }
      case FallDetectionStatus.loading:
        break;
    }
  }

  // ==============================================
  // MARK: - Status banner
  // ==============================================

  Widget _buildStatus({
    required FallDetectionStatus status,
    required Color fgColor,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    if (status == FallDetectionStatus.alertActive) {
      final reddishWhite = Color.alphaBlend(
        colorScheme.error.withValues(alpha: 0.20),
        Colors.white,
      );
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.error, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.warning_amber_rounded,
                color: reddishWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fallDetectionStatusFallDetected,
                    style: textTheme.bodySmall?.copyWith(
                      color: reddishWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.fallDetectionStatusAlertGenerated,
                    style: textTheme.bodySmall?.copyWith(
                      color: reddishWhite.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isActive = status == FallDetectionStatus.active;
    final icon = isActive ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final label = isActive
        ? l10n.fallDetectionStatusNoFalls
        : l10n.fallDetectionStatusInactive;
    final itemColor = isActive ? fgColor : fgColor.withValues(alpha: 0.6);
    final borderColor = isActive
        ? fgColor.withValues(alpha: 0.5)
        : fgColor.withValues(alpha: 0.25);
    final bgColor = isActive
        ? fgColor.withValues(alpha: 0.18)
        : fgColor.withValues(alpha: 0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: itemColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: itemColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? fgColor : fgColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // MARK: - Build
  // ==============================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FallDetectionCubit, FallDetectionCubitState>(
      listenWhen: (prev, curr) =>
          (prev.permissionRequestDenied != curr.permissionRequestDenied &&
              curr.permissionRequestDenied) ||
          (prev.failure != curr.failure && curr.failure != null),
      listener: (context, state) {
        if (state.permissionRequestDenied) {
          context
              .read<FallDetectionCubit>()
              .consumePermissionRequestDenied();
          final l10n = context.l10n;
          CustomDialog.show(
            context: context,
            title: l10n.panicButtonPermissionDeniedTitle,
            content: Text(l10n.panicButtonPermissionDeniedContent),
            buttonText: l10n.panicButtonPermissionDeniedButton,
            onButtonPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.read<FallDetectionCubit>().openLocationSettings();
            },
            secondButtonText: l10n.cancel,
          );
        }
        if (state.failure != null) {
          final l10n = context.l10n;
          CustomDialog.show(
            context: context,
            title: l10n.fallDetectionDeactivateTitle,
            content: Text(
              state.failure is ConflictFailure
                  ? l10n.panicButtonAlreadyActiveContent
                  : l10n.panicButtonActivateErrorContent,
            ),
            buttonText: l10n.accept,
          );
        }
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final fgColor = colorScheme.onSecondary;
        final l10n = context.l10n;

        final isLoading = state.status == FallDetectionStatus.loading ||
            state.isActivating ||
            state.isDeactivating;
        final isEnabled = state.status == FallDetectionStatus.active ||
            state.status == FallDetectionStatus.alertActive;
        final isDisabled = state.status == FallDetectionStatus.disabled;

        return Material(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: title + switch
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fallDetectionTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fgColor.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: isDisabled
                            ? () => _handleSwitchTap(context, state)
                            : null,
                        child: Transform.scale(
                          scale: 0.80,
                          child: Switch(
                            value: isEnabled,
                            onChanged: isDisabled
                                ? null
                                : (_) => _handleSwitchTap(context, state),
                            activeThumbColor: colorScheme.onTertiary,
                            activeTrackColor: colorScheme.tertiary,
                            inactiveThumbColor: fgColor.withValues(alpha: 0.6),
                            inactiveTrackColor:
                                fgColor.withValues(alpha: 0.15),
                            trackOutlineColor:
                                WidgetStateProperty.resolveWith(
                              (states) =>
                                  states.contains(WidgetState.selected)
                                      ? Colors.transparent
                                      : fgColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 2),

                // Disabled reason subtitle
                if (isDisabled && state.disabledReason != null) ...[
                  Text(
                    _disabledSubtitle(state.disabledReason!, l10n),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Description
                Text(
                  l10n.fallDetectionDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: fgColor.withValues(alpha: 0.85),
                  ),
                ),

                const SizedBox(height: 12),

                // Divider
                Divider(color: fgColor.withValues(alpha: 0.4), height: 1),

                const SizedBox(height: 12),

                // Status banner
                if (!isLoading)
                  _buildStatus(
                    status: state.status,
                    fgColor: fgColor,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    l10n: l10n,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _disabledSubtitle(
    FallDetectionDisabledReason reason,
    AppLocalizations l10n,
  ) {
    return switch (reason) {
      FallDetectionDisabledReason.noTrustedContacts =>
        l10n.fallDetectionDisabledNoContacts,
      FallDetectionDisabledReason.locationPermissionDenied ||
      FallDetectionDisabledReason.locationPermissionDeniedForever =>
        l10n.fallDetectionDisabledNoPermission,
    };
  }
}
