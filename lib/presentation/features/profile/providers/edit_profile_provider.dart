import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/edit_profile_cubit.dart';

class EditProfileProvider extends StatelessWidget {
  const EditProfileProvider({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return RepositoryProvider<UserProfileRepository>(
      create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
      child: BlocProvider(
        create: (context) => EditProfileCubit(
          uid: uid,
          userProfileRepository: context.read<UserProfileRepository>(),
        ),
        child: child,
      ),
    );
  }
}
