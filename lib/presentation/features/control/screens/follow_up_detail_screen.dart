import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/extensions/duration_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/presentation/features/chat/helpers/navigate_to_chat.dart';
import 'package:safe_beacon/presentation/features/control/cubits/follow_up_detail_cubit.dart';
import 'package:safe_beacon/presentation/features/control/widgets/follow_up_map.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class FollowUpDetailScreen extends StatelessWidget {
  const FollowUpDetailScreen({super.key});

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _secondaryTagLabel(
    GuardianSessionSecondaryStatus status,
    AppLocalizations l10n,
  ) {
    return switch (status) {
      GuardianSessionSecondaryStatus.routeDeviation => l10n.routeDeviationTag,
      GuardianSessionSecondaryStatus.estimatedTimeExceeded =>
        l10n.estimatedTimeExceededTag,
      GuardianSessionSecondaryStatus.completedByArrival =>
        l10n.completionByArrivalTag,
      GuardianSessionSecondaryStatus.completedByCancellation =>
        l10n.completionByCancellationTag,
    };
  }

  String _buildStatusLabel(GuardianSession session, AppLocalizations l10n) {
    final isActive = session.status == GuardianSessionStatus.active;
    final primary = isActive ? l10n.activeFollowUp : l10n.finishedFollowUp;
    final secondaries = session.secondaryStatuses
        .map((s) => _secondaryTagLabel(s, l10n))
        .join(' - ');
    return secondaries.isEmpty ? primary : '$primary - $secondaries';
  }

  String _completionCause(GuardianSession session, AppLocalizations l10n) {
    final cause = session.secondaryStatuses
        .where(
          (s) =>
              s == GuardianSessionSecondaryStatus.completedByArrival ||
              s == GuardianSessionSecondaryStatus.completedByCancellation,
        )
        .firstOrNull;
    return cause != null ? _secondaryTagLabel(cause, l10n) : '-';
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

  Widget _buildInfoSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
    GuardianSession session,
    String displayName,
  ) {
    final isActive = session.status == GuardianSessionStatus.active;
    final dateStr =
        '${session.activatedAt.toStringDate()} - ${session.activatedAt.toStringTime()}';

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
                ? l10n.activeFollowUpOfUser(displayName.capitalized())
                : l10n.inactiveFollowUpOfUser(displayName.capitalized()),
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
    GuardianSession session,
    String displayName,
  ) {
    final isActive = session.status == GuardianSessionStatus.active;
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
          onTap: () => _showDetailDialog(context, l10n, session, displayName),
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
                      if (session.secondaryStatuses.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: session.secondaryStatuses
                              .map(
                                (s) => _Tag(
                                  label: _secondaryTagLabel(s, l10n),
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
                        '${session.activatedAt.toStringDate()} - ${session.activatedAt.toStringTime()}',
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

  void _showDetailDialog(
    BuildContext context,
    AppLocalizations l10n,
    GuardianSession session,
    String displayName,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = session.status == GuardianSessionStatus.active;

    final endTime = session.deactivatedAt ?? DateTime.now();
    final elapsed = endTime.difference(session.activatedAt);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(
          label: l10n.followUpGeneratorUser,
          value: displayName.capitalized(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.status,
          value: _buildStatusLabel(session, l10n),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.followUpDescription,
          value: session.description.orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationDateDetail,
          value: session.activatedAt.toStringDate().orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.activationTimeDetail,
          value: session.activatedAt.toStringTime().orDash(),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 14),
        _DetailRow(
          label: l10n.followUpEstimatedTime,
          value: session.estimatedDuration.formatDuration(),
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
          _DetailRow(
            label: l10n.followUpCompletionCause,
            value: _completionCause(session, l10n),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: l10n.followUpCompletionReason,
            value: session.completionJustification.orDash(),
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

  Widget _buildContactButton(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    String displayName,
    String otherUid,
    String? otherProfilePhoto,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.startChatWith(displayName.capitalized()),
        icon: Icons.chat_outlined,
        onPressed: () {
          navigateToChat(
            context,
            otherUid: otherUid,
            otherDisplayName: displayName,
            otherProfilePhoto: otherProfilePhoto,
          );
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
      body: BlocBuilder<FollowUpDetailCubit, FollowUpDetailState>(
        builder: (context, state) {
          if (state.isLoading && state.session == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.failure != null || state.session == null) {
            return Column(
              children: [
                SectionHeader(text: l10n.followUpDetailHeader('-')),
                Expanded(
                  child: EmptyStateView(
                    type: EmptyStateType.error,
                    title: l10n.errorTitle,
                    description: l10n.errorDescription,
                  ),
                ),
              ],
            );
          }

          final session = state.session!;
          final displayName = state.displayName;
          final displayProfilePhoto = state.profilePhoto;

          final startPoint = LatLng(
            session.originLocation.latitude,
            session.originLocation.longitude,
          );
          final userPoint = LatLng(
            session.currentLocation.latitude,
            session.currentLocation.longitude,
          );
          final destinationPoint = session.destination != null
              ? LatLng(
                  session.destination!.latitude,
                  session.destination!.longitude,
                )
              : null;

          final lastUpdate =
              session.lastLocationTimestamp ?? session.activatedAt;
          final lastUpdateStr =
              '${lastUpdate.toStringDate()} ${lastUpdate.toStringTime()}';

          final isActive = session.status == GuardianSessionStatus.active;

          return Column(
            children: [
              SectionHeader(
                text: l10n.followUpDetailHeader(displayName.capitalized()),
                onRefresh: isActive
                    ? () => context
                          .read<FollowUpDetailCubit>()
                          .loadFollowUpDetail()
                    : null,
              ),

              // Info banner
              _buildInfoSection(
                l10n,
                colorScheme,
                textTheme,
                isDark,
                session,
                displayName,
              ),

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
                      _buildDataCard(
                        context,
                        l10n,
                        colorScheme,
                        textTheme,
                        isDark,
                        session,
                        displayName,
                      ),

                      // Location & destination
                      _buildSectionTitle(
                        l10n.followUpLocationSection,
                        textTheme,
                        colorScheme,
                      ),
                      FollowUpMap(
                        startPoint: startPoint,
                        userPoint: userPoint,
                        destinationPoint: destinationPoint,
                        lastUpdateLabel: l10n.followUpLastUpdate(lastUpdateStr),
                        userPointLabel:
                            session.status == GuardianSessionStatus.active
                            ? l10n.followUpCurrentLocationLabel
                            : l10n.followUpLastLocationLabel,
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
                      _buildContactButton(
                        context,
                        l10n,
                        colorScheme,
                        displayName,
                        session.ownerUid,
                        displayProfilePhoto,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
