import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/constants/constants.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/extensions/duration_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/helpers/helpers.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/presentation/features/control/cubits/alert_detail_cubit.dart';
import 'package:safe_beacon/presentation/features/control/widgets/alert_detail_dialog.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  // ---------------------------------------------------------------------------
  // Alert detail dialog
  // ---------------------------------------------------------------------------

  void _showAlertDetailDialog(
    BuildContext context,
    AppLocalizations l10n,
    Alert alert,
    String displayName,
  ) {
    final typeLabel = AlertHelper.alertTypeLabelSimple(alert.alertType, l10n);
    final isActive = alert.status == AlertStatus.active;
    final battery = '${alert.batteryLevel}%';

    String? timeActive;

    if (!isActive) {
      if (alert.deactivatedAt != null) {
        final duration = alert.deactivatedAt!.difference(alert.activatedAt);
        timeActive = duration.formatDuration();
      }
    }

    AlertDetailDialog.show(
      context: context,
      username: displayName.capitalized(),
      alertType: typeLabel,
      isActive: isActive,
      date: alert.activatedAt.toStringDate(),
      time: alert.activatedAt.toStringTime(),
      battery: battery,
      deactivationReason: alert.cancellationReason,
      deactivationDate: alert.deactivatedAt?.toStringDate(),
      deactivationTime: alert.deactivatedAt?.toStringTime(),
      timeActive: timeActive,
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
    Alert alert,
    String displayName,
  ) {
    final isActive = alert.status == AlertStatus.active;
    final dateStr =
        '${alert.activatedAt.toStringDate()} - ${alert.activatedAt.toStringTime()}';

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
            isActive
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            color: isActive
                ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
                : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F)),
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? l10n.activeAlertOfUser(displayName.capitalized())
                : l10n.inactiveAlertOfUser(displayName.capitalized()),
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

  Widget _buildAlertDataCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
    Alert alert,
    String displayName,
  ) {
    final isActive = alert.status == AlertStatus.active;

    final statusColor = isActive
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
          onTap: () =>
              _showAlertDetailDialog(context, l10n, alert, displayName),
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
                        AlertHelper.alertTypeLabelComplete(
                          alert.alertType,
                          l10n,
                        ),
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
                              isActive ? l10n.activeAlert : l10n.inactiveAlert,
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
                        '${alert.activatedAt.toStringDate()} - ${alert.activatedAt.toStringTime()}',
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

  Widget _buildMap(
    Alert alert,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final point = LatLng(alert.latitude, alert.longitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 225,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: Constants.openStreetMapTileUrl,
                      userAgentPackageName: Constants.bundleId,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 25, // same as MapLocationPin size
                          height: 35, // size * 1.4
                          alignment: Alignment.topCenter,
                          child: const MapLocationPin(size: 25),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          Constants.openStreetMapAttribution,
                          onTap: () => launchUrl(
                            Uri.parse(Constants.openStreetMapCopyrightUrl),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final url = Uri.parse(
                  Constants.googleMapsUrl(alert.latitude, alert.longitude),
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: Icon(Icons.map_outlined, color: colorScheme.tertiary),
              label: Text(
                l10n.openInGoogleMaps,
                style: TextStyle(color: colorScheme.tertiary),
              ),
            ),
          ),
        ],
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
        height: 225,
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

  Widget _buildContactButton(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    String displayName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.startChatWith(displayName.capitalized()),
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
      body: BlocBuilder<AlertDetailCubit, AlertDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.failure != null || state.alert == null) {
            return Column(
              children: [
                SectionHeader(text: l10n.alertDetailHeader('-')),
                Expanded(
                  child: EmptyStateView(
                    type: EmptyStateType.error,
                    title: l10n.errorTitle,
                    description: l10n.alertLoadError,
                  ),
                ),
              ],
            );
          }

          final alert = state.alert!;
          final displayName = state.displayName;
          final hasCoordinates =
              alert.latitude != 0.0 || alert.longitude != 0.0;

          return Column(
            children: [
              SectionHeader(
                text: l10n.alertDetailHeader(displayName.capitalized()),
              ),

              // Section 1: Info section
              _buildInfoSection(
                context,
                l10n,
                colorScheme,
                textTheme,
                isDark,
                alert,
                displayName,
              ),

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
                        alert,
                        displayName,
                      ),

                      // Location
                      _buildSectionTitle(
                        l10n.locationOnActivationSection,
                        textTheme,
                        colorScheme,
                      ),
                      if (hasCoordinates)
                        _buildMap(alert, l10n, colorScheme, textTheme)
                      else
                        _buildMapPlaceholder(l10n, colorScheme, textTheme),

                      // Contact
                      _buildSectionTitle(
                        l10n.contactSection,
                        textTheme,
                        colorScheme,
                      ),
                      _buildContactButton(l10n, colorScheme, displayName),
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
