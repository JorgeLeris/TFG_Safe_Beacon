import 'package:safe_beacon/core/language/generated/l10n/app_localizations.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';

class AlertHelper {
  /// Converts domain [AlertType] enum to a localised label simple.
  static String alertTypeLabelSimple(AlertType type, AppLocalizations l10n) {
    return switch (type) {
      AlertType.panic => l10n.panicButton,
      AlertType.guardian => l10n.guardianMode,
      AlertType.sensors => l10n.sensors,
      _ => type.name,
    };
  }

  /// Converts domain [AlertType] enum to a localised label complete.
  static String alertTypeLabelComplete(AlertType type, AppLocalizations l10n) {
    return switch (type) {
      AlertType.panic => l10n.alertOfFeature(l10n.panicButton),
      AlertType.guardian => l10n.alertOfFeature(l10n.guardianMode),
      AlertType.sensors => l10n.alertOfFeature(l10n.sensors),
      _ => l10n.alertOfFeature(type.name),
    };
  }
}
