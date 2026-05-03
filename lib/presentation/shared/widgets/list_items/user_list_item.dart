import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';

class UserListItem extends StatelessWidget {
  const UserListItem({
    super.key,
    required this.username,
    this.profilePhoto,
    required this.onProfileTap,
    this.onDelete,
    this.onAccept,
  });

  final String username;
  final String? profilePhoto;
  final VoidCallback onProfileTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAccept;

  static const double _avatarRadius = 30.0;
  static const double _avatarOverlap = 20.0;

  ImageProvider _resolveImage() {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      if (profilePhoto!.startsWith('http://') ||
          profilePhoto!.startsWith('https://')) {
        return NetworkImage(profilePhoto!);
      }
      try {
        return MemoryImage(base64Decode(profilePhoto!));
      } catch (_) {}
    }
    return const AssetImage(AppImages.placeholderProfileImage);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deleteColor = isDark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFD32F2F);
    final acceptColor = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: _avatarOverlap),
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.only(
            left: _avatarRadius * 2 - _avatarOverlap + 10,
            right: 12,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  username,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (onDelete != null) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline,
                  color: deleteColor,
                  isDark: isDark,
                  onTap: onDelete!,
                ),
              ],
              if (onAccept != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.check,
                  color: acceptColor,
                  isDark: isDark,
                  onTap: onAccept!,
                ),
              ],
            ],
          ),
        ),

        // Overlapping avatar
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onProfileTap,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.secondary, width: 2.5),
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
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? color.withValues(alpha: 0.15)
        : HSLColor.fromColor(
            color,
          ).withLightness(0.88).withSaturation(0.60).toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.35),
            width: 0.75,
          ),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
