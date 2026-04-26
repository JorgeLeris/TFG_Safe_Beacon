import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/chat_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/chat/cubits/chat_list_cubit.dart';

class ChatListProvider extends StatelessWidget {
  const ChatListProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>(
          create: (_) => ChatRepositoryImpl(api: ChatApi()),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
      ],
      child: BlocProvider(
        create: (context) => ChatListCubit(
          uid: uid,
          chatRepository: context.read<ChatRepository>(),
          userProfileRepository: context.read<UserProfileRepository>(),
        )..watchChats(),
        child: child,
      ),
    );
  }
}
