import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PanicButtonState _panicState = PanicButtonState.normal;

  void _handlePanicPressed() {
    // TODO: Load first state with data from bd (when loading, not permissions or not contacts state disabled)
    setState(() {
      if (_panicState == PanicButtonState.normal) {
        _panicState = PanicButtonState.active;
        // TODO: activate alarm and send notifications to trusted contacts
      } else if (_panicState == PanicButtonState.active) {
        _panicState = PanicButtonState.normal;
        // TODO: deactivate alarm
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(showBottomBorder: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Contacts button
            SectionButton(
              icon: Icons.group_outlined,
              text: l10n.yourTrustedContacts,
              onPressed: () => const TrustedContactsRoute().push(context),
              backgroundColor: colorScheme.secondary,
              contentColor: colorScheme.onSecondary,
            ),
            const SizedBox(height: 20),

            // Panic button
            const Divider(),
            PanicButton(state: _panicState, onPressed: _handlePanicPressed),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
