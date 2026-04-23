import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/chat_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/presentation/features/chat/cubits/conversation_cubit.dart';

class ConversationProvider extends StatelessWidget {
  const ConversationProvider({
    required this.chatId,
    required this.child,
    super.key,
  });

  final String chatId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return RepositoryProvider<ChatRepository>(
      create: (_) => ChatRepositoryImpl(api: ChatApi()),
      child: BlocProvider(
        create: (context) => ConversationCubit(
          chatId: chatId,
          currentUid: uid,
          chatRepository: context.read<ChatRepository>(),
        )..watchMessages(),
        child: child,
      ),
    );
  }
}
