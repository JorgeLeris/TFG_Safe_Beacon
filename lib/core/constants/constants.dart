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
}
