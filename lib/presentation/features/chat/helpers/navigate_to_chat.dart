import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safe_beacon/data/repositories/chat_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/presentation/features/chat/routes/chat_routes.dart';

/// Navigates to a chat conversation with [otherUid].
///
/// If a chat between the current user and [otherUid] already exists,
/// navigates directly. Otherwise creates a new chat first.
Future<void> navigateToChat(
  BuildContext context, {
  required String otherUid,
  required String otherDisplayName,
  String? otherProfilePhoto,
}) async {
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid == null) return;

  final repo = ChatRepositoryImpl(api: ChatApi());
  final result = await repo.getOrCreateChat(
    currentUid: currentUid,
    otherUid: otherUid,
  );

  if (!context.mounted) return;

  result.when(
    success: (chatId) {
      ConversationRoute(
        chatId: chatId,
        username: otherDisplayName,
        profilePhoto: otherProfilePhoto,
      ).push(context);
    },
    failure: (_) {
      // Silently fail: the user can retry.
    },
  );
}
