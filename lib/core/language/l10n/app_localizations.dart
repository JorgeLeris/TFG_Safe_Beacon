import 'package:flutter/widgets.dart';
import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';

export 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';

/// Extension on [BuildContext] to provide easier access to [AppLocalizations].
extension AppLocalizationsX on BuildContext {
  /// Provides access to the localized strings.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
