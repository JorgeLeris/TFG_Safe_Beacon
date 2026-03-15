import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';

class DateInputField extends StatefulWidget {
  final String hint;
  final bool futureDates;
  final String? errorText;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? initialValue;

  const DateInputField({
    super.key,
    required this.hint,
    this.futureDates = false,
    this.errorText,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  DateTime? _selectedDate;

  bool get _hasDate => _selectedDate != null;

  String get _formattedDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final colorScheme = context.colorScheme;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: widget.futureDates ? now : DateTime(1900),
      lastDate: widget.futureDates ? DateTime(2150) : now,
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary,
              onPrimary: colorScheme.onPrimary,
              surface: colorScheme.surface,
              onSurface: colorScheme.onSurface,
              surfaceContainerHigh: colorScheme.surfaceContainer,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (picked != null) {
      setState(() => _selectedDate = picked);
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickDate,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: _formattedDate),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: hasError
                          ? BorderSide(color: Colors.red.shade700, width: 1.25)
                          : BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: hasError
                          ? BorderSide(color: Colors.red.shade700, width: 1.25)
                          : BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _pickDate,
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  left: 15,
                  top: _hasDate ? 6 : 16,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: _hasDate ? 11 : 16,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: Text(widget.hint),
                  ),
                ),
              ],
            ),
          ),
        ),

        hasError
            ? Padding(
                padding: const EdgeInsets.only(top: 6, left: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
