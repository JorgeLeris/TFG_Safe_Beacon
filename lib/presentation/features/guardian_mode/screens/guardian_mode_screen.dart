import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/features/guardian_mode/widgets/guardian_mode_map.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  // TODO: Hardcoded for now — will be driven by cubit
  bool _isActive = false;

  LatLng? _currentLocation;
  LatLng? _destinationPoint;
  int _durationResetKey = 0;
  int _descriptionResetKey = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {
      // Permission already granted (enforced by navigation) - ignore errors.
    }
  }

  void _activate() => setState(() => _isActive = true);

  void _deactivate() {
    setState(() {
      _isActive = false;
      _destinationPoint = null;
      _durationResetKey++;
      _descriptionResetKey++;
    });
  }

  void _showInfoDialog(AppLocalizations l10n) {
    CustomDialog.show(
      context: context,
      title: l10n.guardianMode,
      content: Text(l10n.guardianModeInfoContent),
      buttonText: l10n.accept,
    );
  }

  // TODO: two dialog for de necesary data

  void _showActivationConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeActivated,
      content: Text(l10n.guardianModeActivatedDescription),
      buttonText: l10n.accept,
    );
  }

  void _showArrivalConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeConfirmArrival,
      content: Text(l10n.guardianModeArrivalDescription),
      buttonText: l10n.guardianModeConfirmArrival,
      onInputButtonPressed: (reason) {
        Navigator.of(context, rootNavigator: true).pop();
        _deactivate();
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.guardianModeJustification,
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    final l10n = context.l10n;
    CustomDialog.show(
      context: context,
      title: l10n.guardianModeCancel,
      content: Text(l10n.guardianModeCancelDescription),
      buttonText: l10n.guardianModeCancel,
      onInputButtonPressed: (reason) {
        Navigator.of(context, rootNavigator: true).pop();
        _deactivate();
      },
      secondButtonText: l10n.cancel,
      inputHint: l10n.guardianModeJustification,
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

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Divider(height: 20),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            CustomFilledButton(
              text: l10n.guardianModeConfirmArrival,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                _showArrivalConfirmationDialog(context);
              },
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              colorText: colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            CustomFilledButton(
              text: l10n.guardianModeCancel,
              icon: Icons.cancel_outlined,
              onPressed: () {
                _showCancelConfirmationDialog(context);
              },
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              colorText: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: double.infinity,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomFilledButton(
        text: l10n.guardianModeActivate,
        icon: Icons.shield_outlined,
        onPressed: () {
          _showActivationConfirmationDialog(context);
          _activate();
        },
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        colorText: colorScheme.onTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        width: double.infinity,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          SectionHeader(
            text: l10n.guardianMode,
            trailingIcon: Icons.info_outline_rounded,
            onTrailingIconPressed: () => _showInfoDialog(l10n),
          ),

          Expanded(
            child: _currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    behavior: HitTestBehavior.opaque,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route / Destination
                          _buildSectionTitle(
                            l10n.guardianModeRouteSection,
                            textTheme,
                            colorScheme,
                          ),
                          GuardianModeMap(
                            currentLocation: _currentLocation!,
                            destinationPoint: _destinationPoint,
                            isActive: _isActive,
                            l10n: l10n,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onDestinationChanged: (point) =>
                                setState(() => _destinationPoint = point),
                          ),

                          // Estimated time
                          _buildSectionTitle(
                            l10n.guardianModeEstimatedTimeSection,
                            textTheme,
                            colorScheme,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DurationInputField(
                              key: ValueKey(_durationResetKey),
                              hint: l10n.guardianModeEstimatedTimeHint,
                              readOnly: _isActive,
                            ),
                          ),

                          // Description
                          _buildSectionTitle(
                            l10n.guardianModeDescriptionSection,
                            textTheme,
                            colorScheme,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: InputField(
                              key: ValueKey(_descriptionResetKey),
                              hint: l10n.guardianModeDescriptionHint,
                              maxLines: 3,
                              readOnly: _isActive,
                            ),
                          ),

                          // Action buttons
                          const SizedBox(height: 28),
                          _buildActionButtons(l10n, colorScheme),
                          const SizedBox(height: 35),

                          // Customization options
                          SettingsOptionsList(
                            horizontalPadding: 24,
                            sectionTitle: l10n.customization,
                            options: [
                              SettingsOption(
                                icon: Icons.settings_outlined,
                                title: l10n.featuresSettings,
                                description:
                                    l10n.guardianModeSettingsDescription,
                                onPressed: () {
                                  _showFutureDialog(context, l10n);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
