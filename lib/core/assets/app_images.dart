/// A class that holds the paths to images assets used in the application.
///
/// This class is abstract and final, meaning it cannot be instantiated or
/// extended. It provides static constants for the paths to various images
/// assets.
abstract final class AppImages {
  /// The base path for all image assets.
  static const _basePath = 'assets/images';

  /// The path to the app icon image.
  static const appIconImage = '$_basePath/app-icon-android.png';

  /// The path to login image
  static const loginImage = '$_basePath/login-image.svg';
}
