import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

/// Data model for a single chat entry.
class ChatItem {
  final String chatId;
  final String username;
  final String? profilePhoto;
  final String? lastMessage;

  /// Whether the last message was sent by the current user.
  final bool lastMessageIsFromMe;
  final int unreadCount;

  const ChatItem({
    required this.chatId,
    required this.username,
    this.profilePhoto,
    this.lastMessage,
    required this.lastMessageIsFromMe,
    this.unreadCount = 0,
  });
}

/// Chat list item widget.
///
/// Shows a circular avatar on the left and a card with username, last message
/// preview and a forward arrow on the right. An unread-count badge (red circle)
/// is displayed in the top-right corner when [ChatItem.unreadCount] > 0.
class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onProfileTap,
    required this.youLabel,
  });

  final ChatItem chat;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the avatar is tapped.
  final VoidCallback onProfileTap;

  /// Localised label for "You" used in the last-message prefix.
  final String youLabel;

  static const double _avatarRadius = 30.0;

  ImageProvider _resolveImage() {
    final photo = chat.profilePhoto;
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
    final l10n = context.l10n;

    final hasUnread = chat.unreadCount > 0;
    final unreadLabel = chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}';

    final lastMessagePrefix = chat.lastMessageIsFromMe
        ? '$youLabel: '
        : '${chat.username}: ';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------------
            // Avatar
            // ------------------------------------------------------------------
            Semantics(
              label: l10n.profilePhotoTapToView,
              button: true,
              child: GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      width: 1.25,
                    ),
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

            const SizedBox(width: 10),

            // ------------------------------------------------------------------
            // Card
            // ------------------------------------------------------------------
            Expanded(
              child: Card(
                elevation: 2,
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 0.75,
                  ),
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
                        children: [
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username
                                Text(
                                  chat.username,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                if (chat.lastMessage != null) ...[
                                  const SizedBox(height: 4),
                                  // Last message preview
                                  RichText(
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    text: TextSpan(
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: lastMessagePrefix,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(text: chat.lastMessage),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Arrow
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // --------------------------------------------------------------------
        // Unread badge
        // --------------------------------------------------------------------
        if (hasUnread)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.75),
                  width: 1.25,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  unreadLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
