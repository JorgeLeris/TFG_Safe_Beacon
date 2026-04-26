import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/chat_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
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
    final chatApi = ChatApi();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>(
          create: (_) => ChatRepositoryImpl(api: chatApi),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
      ],
      child: _ConversationLoader(
        chatId: chatId,
        uid: uid,
        chatApi: chatApi,
        child: child,
      ),
    );
  }
}

/// Resolves participant UIDs from the chat document before creating the cubit.
class _ConversationLoader extends StatefulWidget {
  const _ConversationLoader({
    required this.chatId,
    required this.uid,
    required this.chatApi,
    required this.child,
  });

  final String chatId;
  final String uid;
  final ChatApi chatApi;
  final Widget child;

  @override
  State<_ConversationLoader> createState() => _ConversationLoaderState();
}

class _ConversationLoaderState extends State<_ConversationLoader> {
  List<String>? _participantUids;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final record = await widget.chatApi.findChatById(widget.chatId);
    if (mounted) {
      setState(() {
        _participantUids = record?.dto.participantUids ?? [widget.uid];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants = _participantUids;
    if (participants == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (context) => ConversationCubit(
        chatId: widget.chatId,
        currentUid: widget.uid,
        chatRepository: context.read<ChatRepository>(),
        userProfileRepository: context.read<UserProfileRepository>(),
        participantUids: participants,
      )..watchMessages(),
      child: widget.child,
    );
  }
}
