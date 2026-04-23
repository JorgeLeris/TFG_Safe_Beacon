import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/assets/assets.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// TODO: replace MOCKS with real domain entity
// ---------------------------------------------------------------------------

class _ChatMessage {
  final String id;
  final String text;
  final bool isFromMe;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isFromMe,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.username,
    this.profilePhoto,
  });

  final String chatId;
  final String username;
  final String? profilePhoto;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // TODO: replace mock messages with real Cubit state
  final List<_ChatMessage> _mockMessages = [
    const _ChatMessage(id: '1', text: 'Hola, ¿cómo estás?', isFromMe: false),
    const _ChatMessage(id: '2', text: 'Bien, ¿y tú?', isFromMe: true),
    const _ChatMessage(
      id: '3',
      text: '¿Todo bien por ahí?',
      isFromMe: false,
    ),
    const _ChatMessage(id: '4', text: 'Sí, ya llegué a casa.', isFromMe: true),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _mockMessages.add(
        _ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isFromMe: true,
        ),
      );
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Bubble helpers
  // ---------------------------------------------------------------------------

  ImageProvider _resolveAvatar() {
    final photo = widget.profilePhoto;
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

  Widget _buildBubble(
    BuildContext context,
    _ChatMessage message,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isMe = message.isFromMe;

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.tertiary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiary,
            ),
          ),
        ),
      );
    }

    // Other person's bubble - with avatar on the left
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: navigate to contact profile
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: _resolveAvatar(),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input bar
  // ---------------------------------------------------------------------------

  Widget _buildInputBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: l10n.typeMessageHint,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: colorScheme.tertiary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendMessage,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.send_rounded,
                    color: colorScheme.onTertiary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            SectionHeader(
              text: l10n.chatWithHeader(widget.username.capitalized()),
            ),

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _mockMessages.length,
                itemBuilder: (context, index) => _buildBubble(
                  context,
                  _mockMessages[index],
                  colorScheme,
                  textTheme,
                ),
              ),
            ),

            // Input bar
            _buildInputBar(context, l10n, colorScheme),
          ],
        ),
      ),
    );
  }
}
