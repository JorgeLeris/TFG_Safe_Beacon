import 'dart:async';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class PanicButtonScreen extends StatefulWidget {
  const PanicButtonScreen({super.key});

  @override
  State<PanicButtonScreen> createState() => _PanicButtonScreenState();
}

class _PanicButtonScreenState extends State<PanicButtonScreen> {
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

  void _showInfoDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.panicButton,
      content: Text(l10n.panicButtonInfoContent),
      buttonText: l10n.accept,
    );
  }

  void _showFutureDialog(BuildContext context, AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.notAvailableYet,
      content: Text(l10n.futureUpdateContent),
      buttonText: l10n.accept,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Header with info
          SectionHeader(
            text: l10n.panicButton,
            trailingIcon: Icons.info_outline_rounded,
            onTrailingIconPressed: () => _showInfoDialog(context, l10n),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add to device shortcut button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SectionButton(
                      icon: Icons.add_rounded,
                      text: l10n.addPanicButtonToDevice,
                      onPressed: () {
                        // TODO: add panic button shortcut to device
                      },
                      showArrow: false,
                      backgroundColor: colorScheme.secondary,
                      contentColor: colorScheme.onSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Panic button status card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PanicButtonCard(
                      state: _panicState,
                      onPanicPressed: _handlePanicPressed,
                      cooldownProgress: _cooldownProgress,
                      elapsed: _elapsed,
                      cooldownSeconds: _cooldownSeconds,
                      l10n: l10n,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Customization options
                  SettingsOptionsList(
                    horizontalPadding: 24,
                    sectionTitle: l10n.customization,
                    options: [
                      SettingsOption(
                        icon: Icons.settings_outlined,
                        title: l10n.featuresSettings,
                        description: l10n.featuresSettingsDescription,
                        onPressed: () {
                          // TODO: navigate to features settings
                          _showFutureDialog(context, l10n);
                        },
                      ),
                      SettingsOption(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.deactivationPin,
                        description: l10n.deactivationPinDescription,
                        onPressed: () {
                          // TODO: navigate to PIN setup
                          _showFutureDialog(context, l10n);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Subwidgets

// Card showing panic button status and main action button
class _PanicButtonCard extends StatelessWidget {
  final PanicButtonState state;
  final VoidCallback onPanicPressed;
  final double cooldownProgress;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final int elapsed;
  final int cooldownSeconds;

  const _PanicButtonCard({
    required this.state,
    required this.onPanicPressed,
    required this.cooldownProgress,
    required this.l10n,
    required this.colorScheme,
    required this.textTheme,
    required this.elapsed,
    required this.cooldownSeconds,
  });

  String get _statusLabel {
    switch (state) {
      case PanicButtonState.normal:
        return l10n.panicButtonStatusStandby;
      case PanicButtonState.active:
        return l10n.panicButtonStatusActive;
      case PanicButtonState.disabled:
        return l10n.panicButtonStatusDisabled;
    }
  }

  IconData get _statusIcon {
    switch (state) {
      case PanicButtonState.normal:
        return Icons.check_circle_outline_rounded;
      case PanicButtonState.active:
        return Icons.check_circle_rounded;
      case PanicButtonState.disabled:
        return Icons.cancel_outlined;
    }
  }

  Color get _statusIconColor {
    switch (state) {
      case PanicButtonState.normal:
        return Colors.grey;
      case PanicButtonState.active:
        return Colors.green;
      case PanicButtonState.disabled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status row: title left, icon right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(_statusIcon, color: _statusIconColor, size: 26),
              ],
            ),

            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 5),

            // Panic button widget centered
            Center(
              child: PanicButton(
                state: state,
                onPressed: onPanicPressed,
                cooldownProgress: cooldownProgress,
                secondsLeft: cooldownSeconds - elapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
