import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/data/repositories/contact_repository_impl.dart';
import 'package:safe_beacon/data/repositories/contact_request_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_request_api.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/contacts/cubits/protected_people_cubit.dart';

class ProtectedPeopleProvider extends StatelessWidget {
  const ProtectedPeopleProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
        RepositoryProvider<ContactRequestRepository>(
          create: (_) => ContactRequestRepositoryImpl(api: ContactRequestApi()),
        ),
        RepositoryProvider<ContactRepository>(
          create: (_) => ContactRepositoryImpl(
            api: ContactApi(),
            alertApi: AlertApi(),
            guardianSessionApi: GuardianSessionApi(),
            chatApi: ChatApi(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => ProtectedPeopleCubit(
          uid: uid,
          userProfileRepository: context.read<UserProfileRepository>(),
          contactRequestRepository: context.read<ContactRequestRepository>(),
          contactRepository: context.read<ContactRepository>(),
        ),
        child: child,
      ),
    );
  }
}
