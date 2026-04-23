import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/chat/routes/chat_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// TODO: this screen has to update automatically when a new chat is created or a new message is received.

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Key _searchKey = UniqueKey();
  String _query = '';

  // ---------------------------------------------------------------------------
  //  TODO:replace MOCKS with real Cubit state
  // ---------------------------------------------------------------------------

  static const bool _mockHasError = false;

  static final List<ChatItem> _mockChats = [
    const ChatItem(
      chatId: '1',
      username: 'Ana García',
      lastMessage: '¿Todo bien por ahí?',
      lastMessageIsFromMe: false,
      unreadCount: 3,
    ),
    const ChatItem(
      chatId: '2',
      username: 'Carlos López',
      lastMessage: 'Sí, ya llegué a casa.',
      lastMessageIsFromMe: true,
    ),
    const ChatItem(
      chatId: '3',
      username: 'María Fernández',
      lastMessage: 'Te aviso cuando salga.',
      lastMessageIsFromMe: false,
      unreadCount: 1,
    ),
    const ChatItem(
      chatId: '4',
      username: 'Pedro Martínez',
      lastMessage: 'Gracias por el aviso.',
      lastMessageIsFromMe: true,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    // Error state
    if (_mockHasError) {
      return Expanded(
        child: EmptyStateView(
          type: EmptyStateType.error,
          title: l10n.errorTitle,
          description: l10n.errorDescription,
        ),
      );
    }

    // No chats at all
    if (_mockChats.isEmpty) {
      return Expanded(
        child: EmptyStateView(
          type: EmptyStateType.empty,
          title: l10n.noChatsTitle,
          description: l10n.noChatsDescription,
        ),
      );
    }

    // Apply search filter
    final filtered = _query.isEmpty
        ? _mockChats
        : _mockChats
            .where(
              (c) => c.username.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Expanded(
      child: Column(
        children: [
          // Ssearch field + divider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 25, 16, 12),
            child: SearchInputField(
              key: _searchKey,
              hint: l10n.searchChat,
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 30),
          ),

          // Scrollable: only the list items
          if (filtered.isEmpty)
            Expanded(
              child: EmptyStateView(
                type: EmptyStateType.noResults,
                title: l10n.noResultsTitle,
                description: l10n.noResultsDescription,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChatListItem(
                      chat: chat,
                      youLabel: l10n.youPrefix,
                      onProfileTap: () {
                        // TODO: navigate to contact profile
                      },
                      onTap: () {
                        ConversationRoute(
                          chatId: chat.chatId,
                          username: chat.username,
                          profilePhoto: chat.profilePhoto,
                        ).push(context);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(text: l10n.tabChat),
            _buildContent(context, l10n),
          ],
        ),
      ),
    );
  }
}


