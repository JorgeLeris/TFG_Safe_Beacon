import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/presentation/features/panic_button/cubits/panic_button_cubit.dart';
import 'package:safe_beacon/presentation/features/panic_button/widget/panic_widget_service.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// TODO: manage disable case in feature configuration (also in home screen) - add to state other disabled cases

class PanicButtonScreen extends StatefulWidget {
  const PanicButtonScreen({super.key});

  @override
  State<PanicButtonScreen> createState() => _PanicButtonScreenState();
}

class _PanicButtonScreenState extends State<PanicButtonScreen> {
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

  /// Starts the cooldown timer from [alreadyElapsed] seconds.
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

  /// Called by [BlocListener] when a notable state transition occurs.
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

  // ==============================================
  // MARK: - "Add to device" action
  // ==============================================

  /// Handles the "Add panic button to device" button.
  Future<void> _handleAddToDevice(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (Platform.isAndroid) {
      try {
        await PanicWidgetService.requestPinWidget();
      } catch (_) {
        if (!context.mounted) return;
        unawaited(
          CustomDialog.show(
            context: context,
            title: l10n.addWidgetTitle,
            content: Text(l10n.addWidgetAndroidNotSupported),
            buttonText: l10n.accept,
          ),
        );
      }
    } else {
      unawaited(
        CustomDialog.show(
          context: context,
          title: l10n.addWidgetTitle,
          content: Text(l10n.addWidgetInstructions),
          buttonText: l10n.accept,
        ),
      );
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

    return BlocConsumer<PanicButtonCubit, PanicButtonCubitState>(
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
                          onPressed: () => _handleAddToDevice(context, l10n),
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
                          state: state.buttonState,
                          disabledSubtitle: _disabledSubtitle(state, l10n),
                          onPanicPressed: () =>
                              _handlePanicPressed(context, state),
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
                              _showFutureDialog(context, l10n);
                            },
                          ),
                          SettingsOption(
                            icon: Icons.lock_outline_rounded,
                            title: l10n.deactivationPin,
                            description: l10n.deactivationPinDescription,
                            onPressed: () {
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
      },
    );
  }
}

// MARK: - Subwidgets

// Card showing panic button status and main action button
class _PanicButtonCard extends StatelessWidget {
  final PanicButtonState state;
  final String? disabledSubtitle;
  final VoidCallback onPanicPressed;
  final double cooldownProgress;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final int elapsed;
  final int cooldownSeconds;

  const _PanicButtonCard({
    required this.state,
    this.disabledSubtitle,
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
      case PanicButtonState.loading:
        return l10n.panicButtonStatusLoading;
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
      case PanicButtonState.loading:
        return Icons.hourglass_top_rounded;
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
      case PanicButtonState.loading:
        return Colors.grey;
      case PanicButtonState.active:
        return Colors.green;
      case PanicButtonState.disabled:
        return Colors.orange;
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
                disabledSubtitle: disabledSubtitle,
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
