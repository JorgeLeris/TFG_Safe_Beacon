import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/extensions/string_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/chat/cubits/chat_list_cubit.dart';
import 'package:safe_beacon/presentation/features/chat/routes/chat_routes.dart';
import 'package:safe_beacon/presentation/features/profile/routes/profile_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Key _searchKey = UniqueKey();
  String _query = '';

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ChatListState state,
  ) {
    // Error state
    if (state.failure != null) {
      return Expanded(
        child: EmptyStateView(
          type: EmptyStateType.error,
          title: l10n.errorTitle,
          description: l10n.errorDescription,
        ),
      );
    }

    // Loading
    if (state.isLoading && state.chats.isEmpty) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // No chats at all
    if (state.chats.isEmpty) {
      return Expanded(
        child: EmptyStateView(
          type: EmptyStateType.empty,
          title: l10n.noChatsTitle,
          description: l10n.noChatsDescription,
        ),
      );
    }

    // Apply search filter
    final chats = state.chats;
    final filtered = _query.isEmpty
        ? chats
        : chats
            .where(
              (c) =>
                  c.displayName.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Expanded(
      child: Column(
        children: [
          // Search field + divider
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
                  final entry = filtered[index];
                  final chatItem = ChatItem(
                    chatId: entry.chatId,
                    username: entry.displayName.capitalized(),
                    profilePhoto: entry.profilePhoto,
                    lastMessage: entry.lastMessage,
                    lastMessageIsFromMe: entry.lastMessageIsFromMe,
                    unreadCount: entry.unreadCount,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ChatListItem(
                      chat: chatItem,
                      youLabel: l10n.youPrefix,
                      onProfileTap: () {
                        OtherProfileRoute(uid: entry.otherUid).push(context);
                      },
                      onTap: () {
                        ConversationRoute(
                          chatId: entry.chatId,
                          username: entry.displayName,
                          profilePhoto: entry.profilePhoto,
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
        body: BlocBuilder<ChatListCubit, ChatListState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(text: l10n.tabChat),
                _buildContent(context, l10n, state),
              ],
            );
          },
        ),
      ),
    );
  }
}


