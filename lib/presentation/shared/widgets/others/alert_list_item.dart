import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/date_extensions.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

/// Data model for a single alert entry.
class AlertItem {
  final String alertType;
  final String username;
  final String? profilePhoto;
  final bool isActive;
  final DateTime dateTime;

  const AlertItem({
    required this.alertType,
    required this.username,
    this.profilePhoto,
    required this.isActive,
    required this.dateTime,
  });
}

/// Alert list item.
class AlertListItem extends StatelessWidget {
  const AlertListItem({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onProfileTap,
  });

  final AlertItem alert;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the avatar is tapped.
  final VoidCallback onProfileTap;

  static const double _avatarRadius = 30.0;

  ImageProvider _resolveImage() {
    final photo = alert.profilePhoto;
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return NetworkImage(photo);
      }
      try {
        return MemoryImage(base64Decode(photo));
      } catch (_) {}
    }
    return const AssetImage(AppImages.placeholderProfileImage);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = alert.isActive
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F));

    final statusBg = isDark
        ? statusColor.withValues(alpha: 0.15)
        : HSLColor.fromColor(
            statusColor,
          ).withLightness(0.92).withSaturation(0.55).toColor();

    // Format date as "dd/MM/yyyy HH:mm"
    final dt = alert.dateTime;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${dt.toStringDate()}  $timeStr';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: _resolveImage(),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Content column
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Alert type
                            Text(
                              alert.alertType,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Username
                            Text(
                              alert.username.capitalized(),
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Status tag
                            _StatusTag(
                              isActive: alert.isActive,
                              statusColor: statusColor,
                              statusBg: statusBg,
                              textTheme: textTheme,
                            ),

                            const SizedBox(height: 8),

                            // Date row
                            Row(
                              children: [
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.onSecondary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Fecha: $dateStr',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Trailing arrow
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 8),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colorScheme.onSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  final bool isActive;
  final Color statusColor;
  final Color statusBg;
  final TextTheme textTheme;

  const _StatusTag({
    required this.isActive,
    required this.statusColor,
    required this.statusBg,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}
