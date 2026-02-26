import 'package:flutter/material.dart';

// TODO: Add cubit to manage the dark mode state (by default, if nothing is saved locally, use the device setting; otherwise, use the one saved in local storage).

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0066FF),
    brightness: brightness,
  );
}
