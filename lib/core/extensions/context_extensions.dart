import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/language.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  AppLocalizations get l10n => AppLocalizations.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
}
