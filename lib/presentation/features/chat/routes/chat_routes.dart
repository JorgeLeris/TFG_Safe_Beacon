import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:safe_beacon/presentation/features/chat/providers/chat_list_provider.dart';
import 'package:safe_beacon/presentation/features/chat/providers/conversation_provider.dart';
import 'package:safe_beacon/presentation/features/chat/screens/chat_screen.dart';
import 'package:safe_beacon/presentation/features/chat/screens/conversation_screen.dart';

part 'chat_routes.g.dart';

/// Chat feature routes
///
/// Routes related to chat functionality.
@TypedGoRoute<ChatRoute>(path: '/chat')
class ChatRoute extends GoRouteData with $ChatRoute {
  const ChatRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ChatListProvider(child: ChatScreen());
}

@TypedGoRoute<ConversationRoute>(
  path: '/conversation/:chatId',
)
class ConversationRoute extends GoRouteData with $ConversationRoute {
  const ConversationRoute({
    required this.chatId,
    required this.username,
    this.profilePhoto,
  });

  final String chatId;
  final String username;
  final String? profilePhoto;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ConversationProvider(
        chatId: chatId,
        child: ConversationScreen(
          chatId: chatId,
          username: username,
          profilePhoto: profilePhoto,
        ),
      );
}
