import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';

class InputField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final int maxLines;
  final String? errorText;

  const InputField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isActive => _focusNode.hasFocus || _hasText;

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
              TextField(
                focusNode: _focusNode,
                onChanged: (value) =>
                    setState(() => _hasText = value.isNotEmpty),
                obscureText: widget.isPassword && _obscureText,
                maxLines: widget.isPassword ? 1 : widget.maxLines,
                minLines: widget.isPassword ? 1 : widget.maxLines,
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
                            color: colorScheme.tertiary.withValues(alpha: 0.4),
                          ),
                  ),
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : null,
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                left: 15,
                top: _isActive ? 6 : 16,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: _isActive ? 11 : 16,
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
                padding: const EdgeInsets.only(top: 4, left: 10),
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
