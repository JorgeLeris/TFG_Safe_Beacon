import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

/// Card shown on the home screen that controls automatic fall detection.
///
/// All state is mocked locally with TODOs until the feature logic is wired up.
class FallDetectionCard extends StatefulWidget {
  const FallDetectionCard({super.key});

  @override
  State<FallDetectionCard> createState() => _FallDetectionCardState();
}

class _FallDetectionCardState extends State<FallDetectionCard> {
  // TODO: replace with real fall detection state
  bool _isEnabled = true;
  final bool _hasFallAlert = true;

  // ==============================================
  // MARK: - Dialog
  // ==============================================

  void _showDeactivateDialog() {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.fallDetectionDeactivateTitle,
      content: Text(l10n.fallDetectionDeactivateContent),
      buttonText: l10n.fallDetectionDeactivateButton,
      onInputButtonPressed: (justification) {
        Navigator.of(context, rootNavigator: true).pop();
        // TODO: add logic to deactivate fall detection with justification
        setState(() => _isEnabled = false);
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.fallDetectionJustificationHint,
    );
  }

  // ==============================================
  // MARK: - Status banner
  // ==============================================

  Widget _buildStatus({
    required Color fgColor,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    if (_isEnabled && _hasFallAlert) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
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
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.fallDetectionStatusAlertGenerated,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final icon = _isEnabled ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final label = _isEnabled
        ? l10n.fallDetectionStatusNoFalls
        : l10n.fallDetectionStatusInactive;
    final itemColor =
        _isEnabled ? fgColor : fgColor.withValues(alpha: 0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fgColor.withValues(alpha: _isEnabled ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
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
              color: _isEnabled ? fgColor : fgColor.withValues(alpha: 0.3),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fgColor = colorScheme.onSecondary;
    final l10n = context.l10n;

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
                Transform.scale(
                  scale: 0.80,
                  child: Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      if (!value) {
                        _showDeactivateDialog();
                      } else {
                        // TODO: add logic to activate fall detection
                        setState(() => _isEnabled = true);
                      }
                    },
                    activeThumbColor: colorScheme.onTertiary,
                    activeTrackColor: colorScheme.tertiary,
                    inactiveThumbColor: fgColor.withValues(alpha: 0.6),
                    inactiveTrackColor: fgColor.withValues(alpha: 0.15),
                    trackOutlineColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.transparent
                          : fgColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

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
            _buildStatus(
              fgColor: fgColor,
              colorScheme: colorScheme,
              textTheme: textTheme,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}
