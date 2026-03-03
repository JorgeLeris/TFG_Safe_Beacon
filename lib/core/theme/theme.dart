import 'package:flutter/material.dart';

// TODO: Add cubit to manage the dark mode state (by default, if nothing is saved locally, use the device setting; otherwise, use the one saved in local storage).

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF86A7D5),
    brightness: brightness,
  );

  // TODO: organize colors
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: base.copyWith(
      primary: isDark ? const Color(0xFF070F26) : const Color(0xFF86A7D5),
      secondary: isDark ? const Color(0xFF3B486F) : const Color(0xFF48527A),
      tertiary: isDark ? const Color(0xFF3B486F) : Colors.white,
      onPrimary: isDark ? Colors.white : Colors.black,
      onSecondary: Colors.white,
      onTertiary: isDark ? Colors.white : const Color(0xFF6785C1),
    ),
  );
}
