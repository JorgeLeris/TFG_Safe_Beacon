import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

/// Helper to show the alert detail dialog.
///
/// Shows different content depending on whether the alert is active or inactive.
class AlertDetailDialog {
  AlertDetailDialog._();

  static Future<void> show({
    required BuildContext context,
    required String username,
    required String alertType,
    required bool isActive,
    required bool isGuardianMode,
    required String date,
    required String time,
    required String battery,
    String? deactivationReason,
    String? deactivationDate,
    String? deactivationTime,
    String? timeActive,
  }) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(
          label: l10n.alertGeneratorUser,
          value: username.capitalized().orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.alertType,
          value: alertType.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.status,
          value: isActive ? l10n.activeAlert : l10n.inactiveAlert,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationDateDetail,
          value: date.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationTimeDetail,
          value: time.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.batteryOnActivation,
          value: battery.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        // Deactivation section (only when inactive)
        if (!isActive) ...[
          const SizedBox(height: 20),
          Text(
            l10n.deactivationDataTitle,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: textTheme.titleMedium?.fontSize != null
                  ? textTheme.titleMedium!.fontSize! * 1.1
                  : null,
            ),
          ),
          const Divider(height: 16),
          _DetailRow(
            label: l10n.deactivationReason,
            value: deactivationReason.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: l10n.deactivationDateDetail,
            value: deactivationDate.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: l10n.deactivationTimeDetail,
            value: deactivationTime.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: l10n.timeActive,
            value: timeActive.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
        // Guardian mode follow-up access
        if (isGuardianMode) ...[
          const SizedBox(height: 20),
          Text(
            l10n.accessDetailedFollowUpSection,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: textTheme.titleMedium?.fontSize != null
                  ? textTheme.titleMedium!.fontSize! * 1.1
                  : null,
            ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: () {
                // TODO: Navigate to guardian mode follow-up detail - we need to send the id too.
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.accessDetailedFollowUpButton,
                      style: TextStyle(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.onTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
          const Divider(height: 16),
        ],
      ],
    );

    return CustomDialog.show(
      context: context,
      title: l10n.alertDetailsTitle,
      content: content,
      buttonText: l10n.accept,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
