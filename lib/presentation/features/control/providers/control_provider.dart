import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/contact_request_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_request_api.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';

class ControlProvider extends StatelessWidget {
  const ControlProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return RepositoryProvider<ContactRequestRepository>(
      create: (_) => ContactRequestRepositoryImpl(api: ContactRequestApi()),
      child: BlocProvider(
        create: (context) => ControlCubit(
          uid: uid,
          contactRequestRepository: context.read<ContactRequestRepository>(),
        ),
        child: child,
      ),
    );
  }
}
