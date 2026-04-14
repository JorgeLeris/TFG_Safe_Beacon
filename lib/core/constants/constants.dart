/// A class containing constant values used throughout the application.
abstract final class Constants {
  /// Male value for dropdown fields.
  static const maleFieldKey = 'male';

  /// Female value for dropdown fields.
  static const femaleFieldKey = 'female';

  /// Other value for dropdown fields.
  static const otherFieldKey = 'other';

  /// Regular expression for validating email addresses.
  static final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Panic Button alert type key.
  static const String panicButtonAlertTypeKey = 'panic_button';

  /// Guardian Mode alert type key.
  static const String guardianModeAlertTypeKey = 'guardian_mode';

  /// OpenStreetMap tile URL.
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// URL for OpenStreetMap copyright information.
  static const String openStreetMapCopyrightUrl =
      'https://openstreetmap.org/copyright';

  /// User agent for OpenStreetMap tile requests.
  static const String openStreetMapAttribution = 'OpenStreetMap contributors';

  /// Bundle ID of the application.
  static const String bundleId = 'com.jlerisla.safebeacon';

  /// OSRM public routing API base URL (walking/foot profile).
  static const String osrmRoutingUrl =
      'https://routing.openstreetmap.de/routed-foot/route/v1/driving/';

  /// Returns the Google Maps search URL for the given coordinates.
  static String googleMapsUrl(double latitude, double longitude) =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}
