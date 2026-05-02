import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum AlertStatusFilter { all, active, inactive }

enum AlertFunctionalityFilter { all, panicButton, guardianMode, fallDetection }

class AlertFilters {
  const AlertFilters({
    this.status = AlertStatusFilter.all,
    this.functionality = AlertFunctionalityFilter.all,
  });

  final AlertStatusFilter status;
  final AlertFunctionalityFilter functionality;

  bool get isDefault =>
      status == AlertStatusFilter.all &&
      functionality == AlertFunctionalityFilter.all;

  int get activeCount {
    int count = 0;
    if (status != AlertStatusFilter.all) count++;
    if (functionality != AlertFunctionalityFilter.all) count++;
    return count;
  }

  AlertFilters copyWith({
    AlertStatusFilter? status,
    AlertFunctionalityFilter? functionality,
  }) {
    return AlertFilters(
      status: status ?? this.status,
      functionality: functionality ?? this.functionality,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlertFilters &&
      other.status == status &&
      other.functionality == functionality;

  @override
  int get hashCode => Object.hash(status, functionality);
}

// ---------------------------------------------------------------------------
// AlertFilterDialog
// ---------------------------------------------------------------------------

class AlertFilterDialog extends StatefulWidget {
  const AlertFilterDialog({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final AlertFilters initialFilters;
  final ValueChanged<AlertFilters> onApply;

  static Future<void> show({
    required BuildContext context,
    required AlertFilters initialFilters,
    required ValueChanged<AlertFilters> onApply,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          AlertFilterDialog(initialFilters: initialFilters, onApply: onApply),
    );
  }

  @override
  State<AlertFilterDialog> createState() => _AlertFilterDialogState();
}

class _AlertFilterDialogState extends State<AlertFilterDialog> {
  late AlertStatusFilter _status;
  late AlertFunctionalityFilter _functionality;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilters.status;
    _functionality = widget.initialFilters.functionality;
  }

  void _reset() {
    setState(() {
      _status = AlertStatusFilter.all;
      _functionality = AlertFunctionalityFilter.all;
    });
  }

  void _apply() {
    widget.onApply(
      AlertFilters(status: _status, functionality: _functionality),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filterAlertsTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const Divider(),
            const SizedBox(height: 15),

            // Section 1: Por estado
            _SectionLabel(label: l10n.filterByStatus),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip<AlertStatusFilter>(
                  label: l10n.allMasculine,
                  value: AlertStatusFilter.all,
                  groupValue: _status,
                  onSelected: (v) => setState(() => _status = v),
                ),
                _FilterChip<AlertStatusFilter>(
                  label: l10n.disabledAlerts,
                  value: AlertStatusFilter.inactive,
                  groupValue: _status,
                  onSelected: (v) => setState(() => _status = v),
                ),
                _FilterChip<AlertStatusFilter>(
                  label: l10n.activeAlerts,
                  value: AlertStatusFilter.active,
                  groupValue: _status,
                  onSelected: (v) => setState(() => _status = v),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 2: Por funcionalidad
            _SectionLabel(label: l10n.filterByFunctionality),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip<AlertFunctionalityFilter>(
                  label: l10n.allFeminine,
                  value: AlertFunctionalityFilter.all,
                  groupValue: _functionality,
                  onSelected: (v) => setState(() => _functionality = v),
                ),
                _FilterChip<AlertFunctionalityFilter>(
                  label: l10n.panicButton,
                  value: AlertFunctionalityFilter.panicButton,
                  groupValue: _functionality,
                  onSelected: (v) => setState(() => _functionality = v),
                ),
                _FilterChip<AlertFunctionalityFilter>(
                  label: l10n.guardianMode,
                  value: AlertFunctionalityFilter.guardianMode,
                  groupValue: _functionality,
                  onSelected: (v) => setState(() => _functionality = v),
                ),
                _FilterChip<AlertFunctionalityFilter>(
                  label: l10n.sensors,
                  value: AlertFunctionalityFilter.fallDetection,
                  groupValue: _functionality,
                  onSelected: (v) => setState(() => _functionality = v),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Clear filters text button
            TextButton(
              onPressed: _reset,
              child: Text(
                l10n.clearFilters,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: colorScheme.tertiary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Apply button
            CustomFilledButton(
              text: l10n.filter,
              onPressed: _apply,
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              colorText: colorScheme.onSecondary,
              fontSizeText: textTheme.labelLarge!.fontSize!,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.tertiary.withValues(alpha: 0.15)
              : colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.tertiary
                : colorScheme.onSurface.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isSelected ? colorScheme.tertiary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
