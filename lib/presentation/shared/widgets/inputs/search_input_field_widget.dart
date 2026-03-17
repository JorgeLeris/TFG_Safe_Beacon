import 'package:flutter/material.dart';

class SearchInputField extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const SearchInputField({super.key, required this.hint, this.onChanged});

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _unfocus() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : Colors.black;

    return GestureDetector(
      onTap: _unfocus,
      behavior: HitTestBehavior.translucent,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 42,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              setState(() => _hasText = value.isNotEmpty);
              widget.onChanged?.call(value);
            },
            style: TextStyle(color: contentColor, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.10),
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: contentColor.withValues(alpha: 0.4),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: contentColor.withValues(alpha: 0.5),
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: _hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: contentColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _hasText = false);
                        widget.onChanged?.call('');
                      },
                    )
                  : const SizedBox.shrink(),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                maxWidth: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
