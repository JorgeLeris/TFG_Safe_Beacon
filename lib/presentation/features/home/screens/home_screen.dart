import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/presentation/features/contacts/routes/contacts_routes.dart';
import 'package:safe_beacon/presentation/features/fall_detection/providers/fall_detection_provider.dart';
import 'package:safe_beacon/presentation/features/fall_detection/widgets/fall_detection_card.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/cubits/guardian_mode_cubit.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/routes/guardian_mode_routes.dart';
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

  bool _isGuardianModeLoadingOpen = false;

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

    // Show error dialogs on activation/deactivation failures.
    if (state.activateFailure != null) {
      _showActivateErrorDialog(context);
    } else if (state.deactivateFailure != null) {
      _showDeactivateErrorDialog(context);
    }

    // Show informational dialog when the native permission request was denied.
    if (state.permissionRequestDenied) {
      _showPermissionDeniedAfterRequestDialog(context);
    }
  }

  void _showPermissionDeniedAfterRequestDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.panicButtonPermissionDeniedTitle,
      content: Text(l10n.panicButtonPermissionDeniedContent),
      buttonText: l10n.panicButtonPermissionDeniedButton,
      onButtonPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.read<PanicButtonCubit>().openLocationSettings();
      },
      secondButtonText: l10n.cancel,
    );
  }

  void _showActivateErrorDialog(BuildContext context) {
    final l10n = context.l10n;
    final failure = context.read<PanicButtonCubit>().state.activateFailure;
    final isConflict = failure is ConflictFailure;
    CustomDialog.show(
      context: context,
      title: isConflict
          ? l10n.panicButtonAlreadyActiveTitle
          : l10n.panicButtonActivateErrorTitle,
      content: Text(
        isConflict
            ? l10n.panicButtonAlreadyActiveContent
            : l10n.panicButtonActivateErrorContent,
      ),
      buttonText: l10n.accept,
    );
  }

  void _showDeactivateErrorDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.panicButtonDeactivateErrorTitle,
      content: Text(l10n.panicButtonDeactivateErrorContent),
      buttonText: l10n.accept,
    );
  }

  // ==============================================
  // MARK: - Button interactions
  // ==============================================

  String? _disabledSubtitle(
    PanicButtonCubitState state,
    AppLocalizations l10n,
  ) {
    if (state.buttonState != PanicButtonState.disabled) return null;
    return switch (state.disabledReason) {
      DisabledReason.noTrustedContacts => l10n.panicButtonDisabledNoContacts,
      DisabledReason.locationPermissionDenied ||
      DisabledReason.locationPermissionDeniedForever =>
        l10n.panicButtonDisabledNoPermission,
      null => null,
    };
  }

  void _handlePanicPressed(BuildContext context, PanicButtonCubitState state) {
    final l10n = context.l10n;
    final cubit = context.read<PanicButtonCubit>();

    switch (state.buttonState) {
      case PanicButtonState.normal:
        cubit.activateAlert(l10n);
      case PanicButtonState.active:
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
      case PanicButtonState.disabled:
        _handleDisabledTap(context, state, l10n, cubit);
      case PanicButtonState.loading:
        break;
    }
  }

  void _handleDisabledTap(
    BuildContext context,
    PanicButtonCubitState state,
    AppLocalizations l10n,
    PanicButtonCubit cubit,
  ) {
    switch (state.disabledReason) {
      case DisabledReason.noTrustedContacts:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonNoContactsTitle,
          content: Text(l10n.panicButtonNoContactsContent),
          buttonText: l10n.panicButtonNoContactsButton,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.loadAlertState();
          },
        );
      case DisabledReason.locationPermissionDenied:
        // Trigger the native OS permission dialog directly.
        cubit.requestLocationPermission();
      case DisabledReason.locationPermissionDeniedForever:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonPermissionDeniedTitle,
          content: Text(l10n.panicButtonPermissionDeniedContent),
          buttonText: l10n.panicButtonPermissionDeniedButton,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.openLocationSettings();
          },
          secondButtonText: l10n.cancel,
        );
      case null:
        break;
    }
  }

  // ==============================================
  // MARK: - Guardian mode navigation guard
  // ==============================================

  void _onGuardianModeStateChanged(
    BuildContext context,
    GuardianModeCubitState state,
  ) {
    if (state.isChecking) {
      if (!_isGuardianModeLoadingOpen) {
        _isGuardianModeLoadingOpen = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }
      return;
    }

    // Close the loading dialog if it was open.
    if (_isGuardianModeLoadingOpen) {
      _isGuardianModeLoadingOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (state.canNavigate) {
      context.read<GuardianModeCubit>().consumeNavigation();
      const GuardianModeRoute().push(context).then((_) {
        if (context.mounted) {
          context.read<PanicButtonCubit>().loadAlertState();
        }
      });
    } else if (state.permissionJustGranted) {
      context.read<GuardianModeCubit>().consumePermissionGranted();
      context.read<PanicButtonCubit>().loadAlertState();
    } else if (state.showPermissionDeniedDialog) {
      _showGuardianModePermissionDeniedAfterRequestDialog(context);
    } else if (state.blockedReason != null) {
      _handleGuardianModeBlocked(context, state);
    }
  }

  void _handleGuardianModeBlocked(
    BuildContext context,
    GuardianModeCubitState state,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<GuardianModeCubit>();
    cubit.consumeBlockedReason();

    switch (state.blockedReason) {
      case GuardianModeBlockedReason.noTrustedContacts:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonNoContactsTitle,
          content: Text(l10n.guardianModeNoContactsContent),
          buttonText: l10n.accept,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        );
      case GuardianModeBlockedReason.locationPermissionDenied:
        // Trigger the native OS permission dialog directly.
        cubit.requestLocationPermission();
      case GuardianModeBlockedReason.locationPermissionDeniedForever:
        CustomDialog.show(
          context: context,
          title: l10n.panicButtonPermissionDeniedTitle,
          content: Text(l10n.guardianModePermissionDeniedContent),
          buttonText: l10n.panicButtonPermissionDeniedButton,
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cubit.openLocationSettings();
          },
          secondButtonText: l10n.cancel,
        );
      case null:
        break;
    }
  }

  void _showGuardianModePermissionDeniedAfterRequestDialog(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.panicButtonPermissionDeniedTitle,
      content: Text(l10n.guardianModePermissionDeniedContent),
      buttonText: l10n.panicButtonPermissionDeniedButton,
      onButtonPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.read<GuardianModeCubit>().openLocationSettings();
      },
      secondButtonText: l10n.cancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<GuardianModeCubit, GuardianModeCubitState>(
      listenWhen: (prev, curr) =>
          prev.isChecking != curr.isChecking ||
          (!prev.canNavigate && curr.canNavigate) ||
          (!prev.permissionJustGranted && curr.permissionJustGranted) ||
          (prev.blockedReason != curr.blockedReason &&
              curr.blockedReason != null) ||
          (!prev.showPermissionDeniedDialog && curr.showPermissionDeniedDialog),
      listener: _onGuardianModeStateChanged,
      child: BlocConsumer<PanicButtonCubit, PanicButtonCubitState>(
        listenWhen: (prev, curr) =>
            (prev.isLoading && !curr.isLoading) ||
            (prev.isActivating && !curr.isActivating) ||
            (prev.isDeactivating && !curr.isDeactivating) ||
            (prev.activateFailure != curr.activateFailure &&
                curr.activateFailure != null) ||
            (prev.deactivateFailure != curr.deactivateFailure &&
                curr.deactivateFailure != null) ||
            (!prev.permissionRequestDenied && curr.permissionRequestDenied),
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
                    state: state.buttonState,
                    disabledSubtitle: _disabledSubtitle(state, l10n),
                    onPressed: () => _handlePanicPressed(context, state),
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
                          context.read<GuardianModeCubit>().requestNavigate();
                        },
                        backgroundColor: colorScheme.secondary,
                        contentColor: colorScheme.onSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Fall detection card
                  const FallDetectionProvider(
                    child: FallDetectionCard(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
