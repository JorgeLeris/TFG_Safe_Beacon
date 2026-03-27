import 'package:flutter/material.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/control/widgets/alert_detail_dialog.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  // ---------------------------------------------------------------------------
  // TODO: replace mocked data with real data passed through route parameters
  // ---------------------------------------------------------------------------

  static const String _mockedUsername = 'maria_garcia';
  static const String _mockedAlertType = Constants.panicButtonAlertTypeKey;
  static const bool _mockedIsActive = true;
  static final DateTime _mockedDateTime = DateTime(2025, 6, 12, 14, 32);
  static const String _mockedBattery = '72%';
  static const String _mockedDeactivationReason = 'Desactivación manual';
  static const String _mockedTimeActive = '15 min';

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getAlertTypeLabel(String alertTypeKey, AppLocalizations l10n) {
    return switch (alertTypeKey) {
      Constants.panicButtonAlertTypeKey => l10n.panicButton,
      Constants.guardianModeAlertTypeKey => l10n.guardianMode,
      _ => alertTypeKey,
    };
  }

  // ---------------------------------------------------------------------------
  // Alert detail dialog
  // ---------------------------------------------------------------------------

  void _showAlertDetailDialog(BuildContext context, AppLocalizations l10n) {
    final typeLabel = _getAlertTypeLabel(_mockedAlertType, l10n);

    AlertDetailDialog.show(
      context: context,
      username: _mockedUsername,
      alertType: typeLabel,
      isActive: _mockedIsActive,
      date: _mockedDateTime.toStringDate(),
      time: _mockedDateTime.toStringTime(),
      battery: _mockedBattery,
      deactivationReason: _mockedDeactivationReason,
      timeActive: _mockedTimeActive,
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildInfoSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final dateStr =
        '${_mockedDateTime.toStringDate()} - ${_mockedDateTime.toStringTime()}';

    return Container(
      width: double.infinity,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : colorScheme.surfaceContainerHigh.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _mockedIsActive
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            color: _mockedIsActive
                ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
                : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F)),
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            _mockedIsActive
                ? l10n.activeAlertOfUser(_mockedUsername.capitalized())
                : l10n.inactiveAlertOfUser(_mockedUsername.capitalized()),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: textTheme.titleMedium?.fontSize != null
                  ? textTheme.titleMedium!.fontSize! + 2
                  : null,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.activationDate(dateStr),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
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

  Widget _buildAlertDataCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final typeLabel = _getAlertTypeLabel(_mockedAlertType, l10n);

    final statusColor = _mockedIsActive
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F));

    final statusBg = isDark
        ? statusColor.withValues(alpha: 0.15)
        : HSLColor.fromColor(
            statusColor,
          ).withLightness(0.92).withSaturation(0.55).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () => _showAlertDetailDialog(context, l10n),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.alertOfFeature(typeLabel),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                            width: 0.75,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _mockedIsActive
                                  ? l10n.activeAlert
                                  : l10n.inactiveAlert,
                              style: textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.activationDateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_mockedDateTime.toStringDate()} - ${_mockedDateTime.toStringTime()}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.mapPlaceholder,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(AppLocalizations l10n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.startChatWith(_mockedUsername.capitalized()),
        icon: Icons.chat_outlined,
        onPressed: () {
          // TODO: navigate to chat with user
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          SectionHeader(
            text: l10n.alertDetailHeader(_mockedUsername.capitalized()),
          ),

          // Section 1: Info section
          _buildInfoSection(context, l10n, colorScheme, textTheme, isDark),

          // Section 2: Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert data
                  _buildSectionTitle(
                    l10n.alertDataSection,
                    textTheme,
                    colorScheme,
                  ),
                  _buildAlertDataCard(
                    context,
                    l10n,
                    colorScheme,
                    textTheme,
                    isDark,
                  ),

                  // Location
                  _buildSectionTitle(
                    l10n.locationOnActivationSection,
                    textTheme,
                    colorScheme,
                  ),
                  _buildMapPlaceholder(l10n, colorScheme, textTheme),

                  // Contact
                  _buildSectionTitle(
                    l10n.contactSection,
                    textTheme,
                    colorScheme,
                  ),
                  _buildContactButton(l10n, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
