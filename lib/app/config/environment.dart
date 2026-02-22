/// Enum representing different environments for the application.
enum Environment {
  /// Test environment.
  dev,

  /// Pre-production environment.
  pre,

  /// Production environment.
  production;

  /// Gets the base URL for the current environment.
  String get baseUrl {
    return switch (this) {
      Environment.dev => 'https://dev-xyz.es',
      Environment.pre => 'https://pre-xyz.es',
      Environment.production => 'https://xyz.es',
    };
  }

  /// Example flag: enable network logs for non-production builds.
  bool get logNetwork => this != Environment.production;
}
