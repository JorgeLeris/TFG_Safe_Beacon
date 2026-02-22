/// A class that holds the paths to icon assets used in the application.
///
/// This class is abstract and final, meaning it cannot be instantiated or
/// extended. It provides static constants and final variables for the paths
/// to various icon assets.
abstract final class AppIcons {
  static const _basePath = 'assets/icons';

  // TODO(Team): replace with real images
  /// The path to mock image use for onboarding.
  static const mockIcon = '$_basePath/mock-icon.svg';
}
