import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String hint;
  final bool isPassword;

  const InputField({super.key, required this.hint, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? Icon(
                Icons.visibility_off_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              )
            : null,
      ),
    );
  }
}
