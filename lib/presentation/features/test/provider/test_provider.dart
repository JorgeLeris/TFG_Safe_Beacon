import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:safe_beacon/data/repositories/test_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/test/test_firestore_api.dart';
import 'package:safe_beacon/domain/test/test_repository.dart';
import 'package:safe_beacon/presentation/features/test/cubit/test_cubit.dart';

/// Provider for the Test feature, setting up the necessary dependencies and state management.
class TestProvider extends StatelessWidget {
  final Widget child;
  const TestProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final testApi = TestFirestoreApi(firestore);

    return RepositoryProvider<TestRepository>(
      create: (_) => TestRepositoryImpl(testApi),
      child: BlocProvider<TestCubit>(
        create: (context) => TestCubit(context.read<TestRepository>())..load(),
        child: child,
      ),
    );
  }
}
