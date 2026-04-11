import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

class DurationInputField extends StatefulWidget {
  final String hint;
  final bool readOnly;
  final ValueChanged<Duration>? onChanged;

  const DurationInputField({
    super.key,
    required this.hint,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<DurationInputField> createState() => _DurationInputFieldState();
}

class _DurationInputFieldState extends State<DurationInputField> {
  final TextEditingController _daysCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _minsCtrl = TextEditingController();
  final FocusNode _daysFocus = FocusNode();
  final FocusNode _hoursFocus = FocusNode();
  final FocusNode _minsFocus = FocusNode();

  bool get _anyFocused =>
      !widget.readOnly &&
      (_daysFocus.hasFocus || _hoursFocus.hasFocus || _minsFocus.hasFocus);

  Duration get currentDuration => Duration(
    days: int.tryParse(_daysCtrl.text) ?? 0,
    hours: int.tryParse(_hoursCtrl.text) ?? 0,
    minutes: int.tryParse(_minsCtrl.text) ?? 0,
  );

  @override
  void initState() {
    super.initState();
    _daysFocus.addListener(_onFocusChange);
    _hoursFocus.addListener(_onFocusChange);
    _minsFocus.addListener(_onFocusChange);
    _updateCanRequestFocus();
  }

  @override
  void didUpdateWidget(covariant DurationInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnly != oldWidget.readOnly) {
      _updateCanRequestFocus();
      if (widget.readOnly) {
        if (_daysFocus.hasFocus) _daysFocus.unfocus();
        if (_hoursFocus.hasFocus) _hoursFocus.unfocus();
        if (_minsFocus.hasFocus) _minsFocus.unfocus();
      }
    }
  }

  void _updateCanRequestFocus() {
    _daysFocus.canRequestFocus = !widget.readOnly;
    _hoursFocus.canRequestFocus = !widget.readOnly;
    _minsFocus.canRequestFocus = !widget.readOnly;
  }

  void _onFocusChange() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_anyFocused) _normalize();
    });
  }

  void _normalize() {
    final totalMins =
        (int.tryParse(_daysCtrl.text) ?? 0) * 24 * 60 +
        (int.tryParse(_hoursCtrl.text) ?? 0) * 60 +
        (int.tryParse(_minsCtrl.text) ?? 0);

    final nd = totalMins ~/ (24 * 60);
    final nh = (totalMins % (24 * 60)) ~/ 60;
    final nm = totalMins % 60;

    setState(() {
      _daysCtrl.text = nd > 0 ? '$nd' : '';
      _hoursCtrl.text = nh > 0 ? '$nh' : '';
      _minsCtrl.text = nm > 0 ? '$nm' : '';
    });

    widget.onChanged?.call(Duration(days: nd, hours: nh, minutes: nm));
  }

  @override
  void dispose() {
    _daysCtrl.dispose();
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    _daysFocus.dispose();
    _hoursFocus.dispose();
    _minsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _anyFocused
                ? colorScheme.tertiary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hint,
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
            const SizedBox(height: 2),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _UnitColumn(
                      controller: _daysCtrl,
                      focusNode: _daysFocus,
                      label: l10n.durationDays,
                      readOnly: widget.readOnly,
                      onChanged: (_) => widget.onChanged?.call(currentDuration),
                    ),
                  ),
                  VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _UnitColumn(
                      controller: _hoursCtrl,
                      focusNode: _hoursFocus,
                      label: l10n.durationHours,
                      readOnly: widget.readOnly,
                      onChanged: (_) => widget.onChanged?.call(currentDuration),
                    ),
                  ),
                  VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _UnitColumn(
                      controller: _minsCtrl,
                      focusNode: _minsFocus,
                      label: l10n.durationMinutes,
                      readOnly: widget.readOnly,
                      onChanged: (_) => widget.onChanged?.call(currentDuration),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unit column
// ---------------------------------------------------------------------------

class _UnitColumn extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const _UnitColumn({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.readOnly,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.2),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
