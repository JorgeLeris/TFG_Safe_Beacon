import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';

class DropdownInputField<T> extends StatefulWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? errorText;

  const DropdownInputField({
    super.key,
    required this.hint,
    required this.items,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  State<DropdownInputField<T>> createState() => _DropdownInputFieldState<T>();
}

class _DropdownInputFieldState<T> extends State<DropdownInputField<T>> {
  T? _selected;

  bool get _hasValue => _selected != null;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  List<DropdownMenuItem<T>> _buildStyledItems(ColorScheme colorScheme) {
    return widget.items.map((item) {
      final isSelected = item.value == _selected;

      return DropdownMenuItem<T>(
        value: item.value,
        enabled: item.enabled,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colorScheme.onSurface),
          child: Row(
            children: [
              Expanded(child: item.child),
              isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: colorScheme.tertiary,
                    )
                  : const SizedBox(width: 18),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSelectedItemWidgets() {
    return widget.items.map((item) => item.child).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: colorScheme.tertiary.withValues(alpha: 0.12),
                  focusColor: colorScheme.tertiary.withValues(alpha: 0.12),
                  hoverColor: colorScheme.tertiary.withValues(alpha: 0.12),
                ),
                child: DropdownButtonFormField<T>(
                  initialValue: _selected,
                  items: _buildStyledItems(colorScheme),
                  selectedItemBuilder: (_) => _buildSelectedItemWidgets(),
                  onChanged: (value) {
                    setState(() => _selected = value);
                    widget.onChanged?.call(value);
                  },
                  style: const TextStyle(color: Colors.black),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: colorScheme.surfaceContainer,
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: hasError
                          ? BorderSide(color: Colors.red.shade700, width: 1.25)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: hasError
                          ? BorderSide(color: Colors.red.shade700, width: 1.25)
                          : BorderSide(
                              color: colorScheme.tertiary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                left: 15,
                top: _hasValue ? 6 : 16,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: _hasValue ? 11 : 16,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: Text(widget.hint),
                ),
              ),
            ],
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
