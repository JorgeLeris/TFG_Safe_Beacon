import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/repositories/contact_repository_impl.dart';
import 'package:safe_beacon/data/repositories/guardian_session_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_api.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/cubits/guardian_mode_cubit.dart';

class GuardianModeProvider extends StatelessWidget {
  const GuardianModeProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ContactRepository>(
          create: (_) => ContactRepositoryImpl(
            api: ContactApi(),
            alertApi: AlertApi(),
            guardianSessionApi: GuardianSessionApi(),
            chatApi: ChatApi(),
          ),
        ),
        RepositoryProvider<GuardianSessionRepository>(
          create: (_) =>
              GuardianSessionRepositoryImpl(api: GuardianSessionApi()),
        ),
        RepositoryProvider<AlertRepository>(
          create: (_) => AlertRepositoryImpl(api: AlertApi()),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
      ],
      child: BlocProvider(
        create: (context) => GuardianModeCubit(
          uid: uid,
          contactRepository: context.read<ContactRepository>(),
          guardianSessionRepository: context.read<GuardianSessionRepository>(),
          alertRepository: context.read<AlertRepository>(),
        ),
        child: child,
      ),
    );
  }
}
