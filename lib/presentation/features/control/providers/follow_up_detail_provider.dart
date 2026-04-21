import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/data/repositories/guardian_session_repository_impl.dart';
import 'package:safe_beacon/data/repositories/user_profile_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/follow_up_detail_cubit.dart';

class FollowUpDetailProvider extends StatelessWidget {
  const FollowUpDetailProvider({
    required this.sessionId,
    required this.child,
    super.key,
  });

  final String sessionId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GuardianSessionRepository>(
          create: (_) =>
              GuardianSessionRepositoryImpl(api: GuardianSessionApi()),
        ),
        RepositoryProvider<UserProfileRepository>(
          create: (_) => UserProfileRepositoryImpl(api: UserProfileApi()),
        ),
      ],
      child: BlocProvider(
        create: (context) => FollowUpDetailCubit(
          sessionId: sessionId,
          guardianSessionRepository: context.read<GuardianSessionRepository>(),
          userProfileRepository: context.read<UserProfileRepository>(),
        )..loadFollowUpDetail(),
        child: child,
      ),
    );
  }
}
