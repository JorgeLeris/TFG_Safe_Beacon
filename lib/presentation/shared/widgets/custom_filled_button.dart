import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  const CustomFilledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.colorText,
    this.fontSizeText,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? colorText;
  final double? fontSizeText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.inversePrimary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSizeText ?? textTheme.labelLarge!.fontSize!,
          color: colorText ?? colorScheme.onPrimary,
        ),
      ),
    );
  }
}
