import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/presentation/features/test/cubit/test_cubit.dart';
import 'package:safe_beacon/presentation/features/test/cubit/test_state.dart';
import 'package:safe_beacon/presentation/features/test/provider/test_provider.dart';

/// Main screen for the Test feature, displaying a list of items and allowing the user to add new items.
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  // This test screen is designed to be manually substituted in the runApp of the main when testing is needed.
  // Therefore, it has the provider placed outside the MaterialApp. In the normal case, with MaterialApp configured
  // using go_router, each screen will be wrapped in its own provider within a general MaterialApp.

  @override
  Widget build(BuildContext context) {
    return TestProvider(child: MaterialApp(home: _TestView()));
  }
}

// Internal widget for the TestScreen, responsible for building the UI based on the current state of the TestCubit.
class _TestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Test')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TestCubit>().addItem(),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TestCubit, TestState>(
        builder: (context, state) {
          return state.when(
            initial: () => Center(
              child: ElevatedButton(
                onPressed: () => context.read<TestCubit>().load(),
                child: const Text('Load Items'),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.createdAt.toLocal().toString()),
                );
              },
            ),
            error: (failure) => Center(child: Text('Error: $failure')),
          );
        },
      ),
    );
  }
}
