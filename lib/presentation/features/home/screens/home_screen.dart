import 'dart:async';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/panic_button/routes/panic_button_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Load first state with data from bd (when loading, not permissions or not contacts state disabled)
  PanicButtonState _panicState = PanicButtonState.normal;
  // TODO: Manage timer with db timestamp and actual time instead of in-memory timer
  double _cooldownProgress = 1.0;
  Timer? _cooldownTimer;
  static const int _cooldownSeconds = 10;
  int _elapsed = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _elapsed = 0;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed++;

      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _cooldownProgress = _elapsed / _cooldownSeconds;
      });

      if (_elapsed >= _cooldownSeconds) {
        timer.cancel();
      }
    });
  }

  void _handlePanicPressed() {
    if (_panicState == PanicButtonState.normal) {
      setState(() {
        _panicState = PanicButtonState.active;
        _cooldownProgress = 0.0;
        // TODO: activate alarm and send notifications to trusted contacts
      });
      _startCooldownTimer();
    } else if (_panicState == PanicButtonState.active) {
      if (_cooldownProgress < 1.0) {
        final l10n = context.l10n;
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonCooldownTitle,
          content: Text(l10n.panicButtonCooldownContent),
          buttonText: l10n.accept,
        );
      } else {
        final l10n = context.l10n;
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonDeactivateTitle,
          content: Text(l10n.panicButtonDeactivateContent),
          buttonText: l10n.panicButtonDeactivate,
          onInputButtonPressed: (_) {
            Navigator.of(context, rootNavigator: true).pop();
            setState(() {
              _panicState = PanicButtonState.normal;
              _cooldownProgress = 1.0;
              // TODO: deactivate alarm
            });
          },
          secondButtonText: l10n.cancel,
          inputHint: l10n.panicButtonDeactivateReasonHint,
        );
      }
    }
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
            PanicButton(
              state: _panicState,
              onPressed: _handlePanicPressed,
              cooldownProgress: _cooldownProgress,
              secondsLeft: _cooldownSeconds - _elapsed,
            ),
            const Divider(),

            const SizedBox(height: 20),

            // Feature grid buttons
            FeatureGridButtons(
              items: [
                FeatureGridItem(
                  icon: Icons.crisis_alert_rounded,
                  label: l10n.panicButton,
                  // TODO: update state of panic button when navigating back from panic button screen
                  onPressed: () => const PanicButtonRoute().push(context),
                  backgroundColor: colorScheme.secondary,
                  contentColor: colorScheme.onSecondary,
                ),
                FeatureGridItem(
                  icon: Icons.location_on_outlined,
                  label: l10n.guardianMode,
                  onPressed: () {
                    // TODO: navigate to guardian mode
                  },
                  backgroundColor: colorScheme.secondary,
                  contentColor: colorScheme.onSecondary,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
