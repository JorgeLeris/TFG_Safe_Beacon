import 'package:flutter/material.dart';

// TODO: Add cubit to manage the dark mode state (by default, if nothing is saved locally, use the device setting; otherwise, use the one saved in local storage).

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF86A7D5),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: base.copyWith(
      // Surface and surface variant
      surface: isDark ? const Color(0xFF070F26) : Colors.white,
      surfaceContainerHigh: isDark
          ? const Color(0xFF070F26)
          : const Color(0xFF86A7D5),
      onSurface: isDark ? Colors.white : Colors.black,

      // Surface containers
      surfaceContainer: isDark ? const Color(0xFF1D264D) : Colors.white,
      onSurfaceVariant: isDark ? Colors.white : const Color(0xFF6785C1),

      // Components color (mid intensity)
      primary: isDark ? const Color(0xFF476189) : const Color(0xFF6785C1),
      onPrimary: Colors.white,

      // Components color (mid intensity)
      secondary: isDark ? const Color(0xFF3B486F) : const Color(0xFF7198CE),
      onSecondary: Colors.white,

      // Components color (mid intensity)
      tertiary: isDark ? const Color(0xFFE1E7F3) : const Color(0xFF0080B1),
      onTertiary: Colors.white,

      // Components color (always dark)
      inversePrimary: isDark
          ? const Color(0xFF3B486F)
          : const Color(0xFF48527A),
      //* onPrimary: Colors.white,
    ),

    navigationBarTheme: NavigationBarThemeData(
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF6785C1),
        );
      }),

      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = isDark ? Colors.white : const Color(0xFF6785C1);
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          );
        }
        return TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
      }),

      indicatorColor: isDark ? const Color(0xFF476189) : null,
    ),
  );
}
