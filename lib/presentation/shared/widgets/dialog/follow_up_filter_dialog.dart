import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum FollowUpSecondaryTag {
  routeDeviation,
  estimatedTimeExceeded,
  completionByArrival,
  completionByCancellation,
}

enum FollowUpStatusFilter { all, active, finished }

enum FollowUpEventFilter { all, routeDeviation, estimatedTimeExceeded }

enum FollowUpCompletionFilter {
  all,
  completionByArrival,
  completionByCancellation,
}

class FollowUpFilters {
  const FollowUpFilters({
    this.status = FollowUpStatusFilter.all,
    this.event = FollowUpEventFilter.all,
    this.completion = FollowUpCompletionFilter.all,
  });

  final FollowUpStatusFilter status;
  final FollowUpEventFilter event;
  final FollowUpCompletionFilter completion;

  bool get isDefault =>
      status == FollowUpStatusFilter.all &&
      event == FollowUpEventFilter.all &&
      completion == FollowUpCompletionFilter.all;

  int get activeCount {
    int count = 0;
    if (status != FollowUpStatusFilter.all) count++;
    if (event != FollowUpEventFilter.all) count++;
    if (completion != FollowUpCompletionFilter.all) count++;
    return count;
  }

  FollowUpFilters copyWith({
    FollowUpStatusFilter? status,
    FollowUpEventFilter? event,
    FollowUpCompletionFilter? completion,
  }) {
    return FollowUpFilters(
      status: status ?? this.status,
      event: event ?? this.event,
      completion: completion ?? this.completion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FollowUpFilters &&
      other.status == status &&
      other.event == event &&
      other.completion == completion;

  @override
  int get hashCode => Object.hash(status, event, completion);
}

// ---------------------------------------------------------------------------
// FollowUpFilterDialog
// ---------------------------------------------------------------------------

class FollowUpFilterDialog extends StatefulWidget {
  const FollowUpFilterDialog({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  final FollowUpFilters initialFilters;
  final ValueChanged<FollowUpFilters> onApply;

  static Future<void> show({
    required BuildContext context,
    required FollowUpFilters initialFilters,
    required ValueChanged<FollowUpFilters> onApply,
  }) {
    return showDialog(
      context: context,
      builder: (_) => FollowUpFilterDialog(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FollowUpFilterDialog> createState() => _FollowUpFilterDialogState();
}

class _FollowUpFilterDialogState extends State<FollowUpFilterDialog> {
  late FollowUpStatusFilter _status;
  late FollowUpEventFilter _event;
  late FollowUpCompletionFilter _completion;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilters.status;
    _event = widget.initialFilters.event;
    _completion = widget.initialFilters.completion;
  }

  void _reset() {
    setState(() {
      _status = FollowUpStatusFilter.all;
      _event = FollowUpEventFilter.all;
      _completion = FollowUpCompletionFilter.all;
    });
  }

  void _apply() {
    widget.onApply(
      FollowUpFilters(status: _status, event: _event, completion: _completion),
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
      child: SingleChildScrollView(
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
                    l10n.filterFollowUpsTitle,
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

              // Section 1: By status
              _SectionLabel(label: l10n.filterByStatus),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip<FollowUpStatusFilter>(
                    label: l10n.allMasculine,
                    value: FollowUpStatusFilter.all,
                    groupValue: _status,
                    onSelected: (v) => setState(() => _status = v),
                  ),
                  _FilterChip<FollowUpStatusFilter>(
                    label: l10n.activeFollowUps,
                    value: FollowUpStatusFilter.active,
                    groupValue: _status,
                    onSelected: (v) => setState(() => _status = v),
                  ),
                  _FilterChip<FollowUpStatusFilter>(
                    label: l10n.finishedFollowUps,
                    value: FollowUpStatusFilter.finished,
                    groupValue: _status,
                    onSelected: (v) => setState(() => _status = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section 2: By event
              _SectionLabel(label: l10n.filterByEvent),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip<FollowUpEventFilter>(
                    label: l10n.allMasculine,
                    value: FollowUpEventFilter.all,
                    groupValue: _event,
                    onSelected: (v) => setState(() => _event = v),
                  ),
                  _FilterChip<FollowUpEventFilter>(
                    label: l10n.routeDeviationTag,
                    value: FollowUpEventFilter.routeDeviation,
                    groupValue: _event,
                    onSelected: (v) => setState(() => _event = v),
                  ),
                  _FilterChip<FollowUpEventFilter>(
                    label: l10n.estimatedTimeExceededTag,
                    value: FollowUpEventFilter.estimatedTimeExceeded,
                    groupValue: _event,
                    onSelected: (v) => setState(() => _event = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section 3: By completion type
              _SectionLabel(label: l10n.filterByCompletionType),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip<FollowUpCompletionFilter>(
                    label: l10n.allFeminine,
                    value: FollowUpCompletionFilter.all,
                    groupValue: _completion,
                    onSelected: (v) => setState(() => _completion = v),
                  ),
                  _FilterChip<FollowUpCompletionFilter>(
                    label: l10n.completionByArrivalTag,
                    value: FollowUpCompletionFilter.completionByArrival,
                    groupValue: _completion,
                    onSelected: (v) => setState(() => _completion = v),
                  ),
                  _FilterChip<FollowUpCompletionFilter>(
                    label: l10n.completionByCancellationTag,
                    value: FollowUpCompletionFilter.completionByCancellation,
                    groupValue: _completion,
                    onSelected: (v) => setState(() => _completion = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Clear filters
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ],
          ),
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
