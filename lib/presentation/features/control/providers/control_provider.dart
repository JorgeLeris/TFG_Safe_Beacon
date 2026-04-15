import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/repositories/contact_request_repository_impl.dart';
import 'package:safe_beacon/data/repositories/guardian_session_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_request_api.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';

class ControlProvider extends StatelessWidget {
  const ControlProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ContactRequestRepository>(
          create: (_) => ContactRequestRepositoryImpl(api: ContactRequestApi()),
        ),
        RepositoryProvider<AlertRepository>(
          create: (_) => AlertRepositoryImpl(api: AlertApi()),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
        RepositoryProvider<GuardianSessionRepository>(
          create: (_) =>
              GuardianSessionRepositoryImpl(api: GuardianSessionApi()),
        ),
      ],
      child: BlocProvider(
        create: (context) => ControlCubit(
          uid: uid,
          contactRequestRepository: context.read<ContactRequestRepository>(),
          alertRepository: context.read<AlertRepository>(),
          userProfileRepository: context.read<UserProfileRepository>(),
          guardianSessionRepository: context.read<GuardianSessionRepository>(),
        ),
        child: child,
      ),
    );
  }
}
