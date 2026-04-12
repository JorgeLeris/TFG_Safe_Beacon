import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/extensions/duration_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/control/widgets/follow_up_map.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Mock data model (inline, no domain entity)
// TODO(follow-ups): Replace with data from service.
// ---------------------------------------------------------------------------

class _MockFollowUpDetail {
  final String username;
  final bool isActive;
  final List<String> primaryTags;
  final List<String> secondaryTags;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String description;
  final Duration estimatedTime;
  final String? completionReason;
  final LatLng startPoint;
  final LatLng userPoint;
  final LatLng destinationPoint;
  final DateTime lastLocationUpdate;

  const _MockFollowUpDetail({
    required this.username,
    required this.isActive,
    required this.primaryTags,
    required this.secondaryTags,
    required this.startedAt,
    this.endedAt,
    required this.description,
    required this.estimatedTime,
    this.completionReason,
    required this.startPoint,
    required this.userPoint,
    required this.destinationPoint,
    required this.lastLocationUpdate,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FollowUpDetailScreen extends StatelessWidget {
  const FollowUpDetailScreen({super.key});

  // TODO(follow-ups): Replace _mock with data loaded from service.
  static final _MockFollowUpDetail _mock = _MockFollowUpDetail(
    username: 'Maria García',
    isActive: false,
    primaryTags: ['Seguimiento activo'],
    secondaryTags: ['Desviación de la ruta'],
    startedAt: DateTime.now().subtract(const Duration(minutes: 35)),
    description: 'Trayecto al trabajo por la avenida principal.',
    estimatedTime: const Duration(hours: 1, minutes: 15),
    startPoint: const LatLng(40.4168, -3.7038),
    userPoint: const LatLng(40.4220, -3.6950),
    destinationPoint: const LatLng(40.4530, -3.6883),
    lastLocationUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
    endedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    completionReason: 'Ya he llegado a mi destino.',
  );

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

  Widget _buildInfoSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final isActive = _mock.isActive;
    final dateStr =
        '${_mock.startedAt.toStringDate()} - ${_mock.startedAt.toStringTime()}';

    final iconColor = isActive
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F));

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
            isActive ? Icons.track_changes_rounded : Icons.cancel_outlined,
            color: iconColor,
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? l10n.activeFollowUpOfUser(_mock.username.capitalized())
                : l10n.inactiveFollowUpOfUser(_mock.username.capitalized()),
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
            l10n.followUpActivationDate(dateStr),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final isActive = _mock.isActive;
    final primaryColor = isActive
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F));

    final primaryBg = isDark
        ? primaryColor.withValues(alpha: 0.15)
        : HSLColor.fromColor(
            primaryColor,
          ).withLightness(0.92).withSaturation(0.55).toColor();

    final orangeColor = isDark
        ? const Color(0xFFFFA726)
        : const Color(0xFFE65100);
    final orangeBg = isDark
        ? orangeColor.withValues(alpha: 0.15)
        : const Color(0xFFFFF3E0);

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
          onTap: () => _showDetailDialog(context, l10n),
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
                        l10n.followUpDataTitle,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Primary status tag
                      _Tag(
                        label: isActive
                            ? l10n.activeFollowUp
                            : l10n.finishedFollowUp,
                        color: primaryColor,
                        bg: primaryBg,
                        textTheme: textTheme,
                      ),
                      // Secondary tags
                      if (_mock.secondaryTags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _mock.secondaryTags
                              .map(
                                (tag) => _Tag(
                                  label: tag,
                                  color: orangeColor,
                                  bg: orangeBg,
                                  textTheme: textTheme,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        l10n.activationDateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_mock.startedAt.toStringDate()} - ${_mock.startedAt.toStringTime()}',
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

  void _showDetailDialog(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = _mock.isActive;

    final elapsed = DateTime.now().difference(_mock.startedAt);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(
          label: l10n.followUpGeneratorUser,
          value: _mock.username.capitalized(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.status,
          value: isActive ? l10n.activeFollowUp : l10n.finishedFollowUp,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.followUpDescription,
          value: _mock.description.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationDateDetail,
          value: _mock.startedAt.toStringDate().orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationTimeDetail,
          value: _mock.startedAt.toStringTime().orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.followUpEstimatedTime,
          value: _mock.estimatedTime.formatDuration(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.followUpElapsedTime,
          value: elapsed.formatDuration(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        if (!isActive) ...[
          const SizedBox(height: 20),
          Text(
            l10n.followUpCompletionSection,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: textTheme.titleMedium?.fontSize != null
                  ? textTheme.titleMedium!.fontSize! * 1.1
                  : null,
            ),
          ),
          const Divider(height: 16),
          // TODO: detect if is cancelation or normal completion
          _DetailRow(
            label: l10n.followUpCompletionCause,
            value: _mock.secondaryTags.first.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: l10n.followUpCompletionReason,
            value: _mock.completionReason.orDash(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
      ],
    );

    CustomDialog.show(
      context: context,
      title: l10n.followUpDataTitle,
      content: content,
      buttonText: l10n.accept,
    );
  }

  Widget _buildContactButton(AppLocalizations l10n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.startChatWith(_mock.username.capitalized()),
        icon: Icons.chat_outlined,
        onPressed: () {
          // TODO: Navigate to chat with user.
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

    final lastUpdateStr =
        '${_mock.lastLocationUpdate.toStringDate()} ${_mock.lastLocationUpdate.toStringTime()}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          SectionHeader(
            text: l10n.followUpDetailHeader(_mock.username.capitalized()),
            onRefresh: () {
              // TODO: implement refresh logic to reload follow-up details from service.
              return Future.delayed(const Duration(seconds: 1));
            },
          ),

          // Info banner
          _buildInfoSection(l10n, colorScheme, textTheme, isDark),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Follow-up data
                  _buildSectionTitle(
                    l10n.followUpDataSection,
                    textTheme,
                    colorScheme,
                  ),
                  _buildDataCard(context, l10n, colorScheme, textTheme, isDark),

                  // Location & destination
                  _buildSectionTitle(
                    l10n.followUpLocationSection,
                    textTheme,
                    colorScheme,
                  ),
                  FollowUpMap(
                    startPoint: _mock.startPoint,
                    userPoint: _mock.userPoint,
                    destinationPoint: _mock.destinationPoint,
                    lastUpdateLabel: l10n.followUpLastUpdate(lastUpdateStr),
                    l10n: l10n,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),

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

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.bg,
    required this.textTheme,
  });

  final String label;
  final Color color;
  final Color bg;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
