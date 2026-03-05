import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';

class DropdownInputField<T> extends StatefulWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;

  const DropdownInputField({
    super.key,
    required this.hint,
    required this.items,
    this.onChanged,
    this.value,
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

    return Material(
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
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.tertiary.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
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
    );
  }
}
