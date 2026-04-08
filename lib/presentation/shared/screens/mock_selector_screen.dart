import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// DEVELOPMENT, MAINTENANCE AND DEMO PURPOSES
// Access with: flutter run --dart-define=MOCK=true
// Long press to navigate to /mock-selector
class MockSelectorScreen extends StatelessWidget {
  const MockSelectorScreen({super.key});

  Future<String?> _getSelection(BuildContext context) async {
    final prefs = context.read<SharedPreferences>();
    return prefs.getString('mockType');
  }

  Future<void> _saveSelection(BuildContext context, String mockValue) async {
    final prefs = context.read<SharedPreferences>();
    await prefs.setString('mockType', mockValue);
    appLogger.info('Saved mockType as: $mockValue');
    if (!context.mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona el mock')),
      body: FutureBuilder(
        future: _getSelection(context),
        builder: (context, snapshot) {
          final selected = snapshot.data;
          final items = {
            'ok': 'Mocks escenario ok',
            'empty': 'Mocks escenario ok empty',
            'error': 'Mocks escenario error',
            '': 'Sin mock',
          };
          return ListView(
            children: items.keys.map((key) {
              final output = items[key];
              return ListTile(
                title: Text(output!),
                trailing: selected == key ? const Icon(Icons.check) : null,
                onTap: () => _saveSelection(context, key),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
