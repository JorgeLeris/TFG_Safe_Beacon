import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/repositories/contact_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_api.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/presentation/features/fall_detection/cubits/fall_detection_cubit.dart';

/// Provides [FallDetectionCubit] and its repository dependencies.
class FallDetectionProvider extends StatelessWidget {
  const FallDetectionProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AlertRepository>(
          create: (_) => AlertRepositoryImpl(api: AlertApi()),
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
        create: (context) => FallDetectionCubit(
          uid: uid,
          contactRepository: context.read<ContactRepository>(),
          alertRepository: context.read<AlertRepository>(),
        )..loadState(),
        child: child,
      ),
    );
  }
}
