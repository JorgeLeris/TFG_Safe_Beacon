import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Available logging levels in the application and their recommended usage:
///
/// * [Level.FINEST] (300): Extremely detailed information, useful for deep debugging.
///   Example: Internal variable values, intermediate calculation states.
///
/// * [Level.FINER] (400): Very detailed information about execution.
///   Example: Entry/exit of internal methods, iterations in complex loops.
///
/// * [Level.FINE] (500): Detailed information of interest during development.
///   Example: HTTP request entry/exit, state changes in components.
///
/// * [Level.CONFIG] (700): Static or dynamic configuration information.
///   Example: Values read from configuration files, environment variables.
///
/// * [Level.INFO] (800): General information about application flow.
///   Example: Start/end of important processes, user events.
///
/// * [Level.WARNING] (900): Potentially problematic but recoverable situations.
///   Example: Use of deprecated APIs, operation retries, unexpected data.
///
/// * [Level.SEVERE] (1000): Serious errors that prevent proper functioning.
///   Example: Unhandled exceptions, critical connectivity failures.
///
/// * [Level.SHOUT] (1200): Fatal errors requiring immediate attention.
///   Example: Data corruption, security violations, system errors.
///
/// NOTE: In debug mode, all levels are displayed. In production, only WARNING and above.
/// For SEVERE and SHOUT errors, it's recommended to send them to error monitoring systems.

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((r) {
    if (kDebugMode) {
      // In debug mode, print everything to console
      // ignore: avoid_print
      print('${r.level.name} ${r.time} ${r.loggerName}: ${r.message}');
      if (r.error != null) {
        // ignore: avoid_print
        print(r.error);
        // ignore: avoid_print
        print(r.stackTrace);
      }
    } else {
      // In production mode:
      if (r.level >= Level.SEVERE) {
        // PROD: Send critical errors to crash reporting tool
        // TODO: Uncomment and implement when ready for production
        // FirebaseCrashlytics.instance.recordError(
        //   r.error ?? r.message,
        //   r.stackTrace,
        //   reason: r.message,
        // );
      }
    }
  });
}

/// Global logger instance for all application logging.
///
/// Usage examples:
/// ```dart
/// // Basic info logging
/// appLogger.info('User logged in');
///
/// // Warning for potential issues
/// appLogger.warning('API rate limit approaching');
///
/// // Error logging with exception and stack trace
/// try {
///   // some code
/// } catch (e, stack) {
///   appLogger.severe('Failed to process data', e, stack);
/// }
/// ```
final Logger appLogger = Logger('App');
