import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/panic_button/cubits/panic_button_cubit.dart';
import 'package:safe_beacon/presentation/features/panic_button/routes/panic_button_routes.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _cooldownProgress = 1.0;
  Timer? _cooldownTimer;
  static const int _cooldownSeconds = 10;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    context.read<PanicButtonCubit>().loadAlertState();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ==============================================
  // MARK: - Timer management
  // ==============================================

  void _startCooldownTimer({int alreadyElapsed = 0}) {
    _cooldownTimer?.cancel();
    _elapsed = alreadyElapsed;
    _cooldownProgress = (_elapsed / _cooldownSeconds).clamp(0.0, 1.0);

    if (_elapsed >= _cooldownSeconds) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownProgress = (_elapsed / _cooldownSeconds).clamp(0.0, 1.0);
      });
      if (_elapsed >= _cooldownSeconds) timer.cancel();
    });
  }

  void _resetTimer() {
    _cooldownTimer?.cancel();
    setState(() {
      _elapsed = 0;
      _cooldownProgress = 1.0;
    });
  }

  // ==============================================
  // MARK: - Cubit state transitions
  // ==============================================

  void _onCubitStateChanged(BuildContext context, PanicButtonCubitState state) {
    // If active: restore/start the cooldown timer from the saved activatedAt.
    if (state.buttonState == PanicButtonState.active &&
        state.activeAlertActivatedAt != null) {
      final alreadyElapsed = DateTime.now()
          .difference(state.activeAlertActivatedAt!)
          .inSeconds
          .clamp(0, _cooldownSeconds);
      setState(() {});
      _startCooldownTimer(alreadyElapsed: alreadyElapsed);
    } else if (state.buttonState == PanicButtonState.normal) {
      _resetTimer();
    }

    // Show error feedback on activation/deactivation failures.
    if (state.activateFailure != null || state.deactivateFailure != null) {
      _showErrorSnackBar(context);
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.errorDescription)));
  }

  // ==============================================
  // MARK: - Button interactions
  // ==============================================

  void _handlePanicPressed(BuildContext context, PanicButtonCubitState state) {
    final l10n = context.l10n;
    final cubit = context.read<PanicButtonCubit>();

    if (state.buttonState == PanicButtonState.normal) {
      cubit.activateAlert();
    } else if (state.buttonState == PanicButtonState.active) {
      if (_cooldownProgress < 1.0) {
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonCooldownTitle,
          content: Text(l10n.panicButtonCooldownContent),
          buttonText: l10n.accept,
        );
      } else {
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonDeactivateTitle,
          content: Text(l10n.panicButtonDeactivateContent),
          buttonText: l10n.panicButtonDeactivate,
          onInputButtonPressed: (reason) {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.deactivateAlert(reason: reason);
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

    return BlocConsumer<PanicButtonCubit, PanicButtonCubitState>(
      listenWhen: (prev, curr) =>
          (prev.isLoading && !curr.isLoading) ||
          (prev.isActivating && !curr.isActivating) ||
          (prev.isDeactivating && !curr.isDeactivating),
      listener: _onCubitStateChanged,
      builder: (context, state) {
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
                  state: state.isLoading
                      ? PanicButtonState.disabled
                      : state.buttonState,
                  onPressed:
                      state.isLoading ||
                          state.isActivating ||
                          state.isDeactivating
                      ? null
                      : () => _handlePanicPressed(context, state),
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
                      onPressed: () {
                        const PanicButtonRoute().push(context).then((_) {
                          if (context.mounted) {
                            context.read<PanicButtonCubit>().loadAlertState();
                          }
                        });
                      },
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
      },
    );
  }
}
