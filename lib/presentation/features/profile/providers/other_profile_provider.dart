import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/profile/cubits/profile_cubit.dart';

class OtherProfileProvider extends StatelessWidget {
  const OtherProfileProvider({
    required this.uid,
    required this.child,
    super.key,
  });

  final String uid;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<UserProfileRepository>(
      create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
      child: BlocProvider(
        create: (context) => ProfileCubit(
          uid: uid,
          userProfileRepository: context.read<UserProfileRepository>(),
        ),
        child: child,
      ),
    );
  }
}
