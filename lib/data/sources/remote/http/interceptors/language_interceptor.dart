import 'package:dio/dio.dart';

/// A function type that validates a language code.
typedef LanguageValidator = bool Function(String languageCode);

/// An interceptor that adds a language code to the request path.
///
/// The [LanguageInterceptor] class intercepts HTTP requests and adds a
/// language code to the request path. It also provides a method to update
/// the language code.
class LanguageInterceptor extends Interceptor {
  /// Creates an instance of [LanguageInterceptor] with the specified
  /// [languageCode] and [validateLanguageCode].
  ///
  /// The [languageCode] must be a valid language code supported by the
  /// application.
  LanguageInterceptor({
    required String languageCode,
    required LanguageValidator validateLanguageCode,
  }) : assert(
         validateLanguageCode(languageCode),
         'Language code $languageCode is not supported by the application',
       ),
       _validateLanguageCode = validateLanguageCode,
       _languageCode = languageCode;

  /// The language code to be added to the request path.
  String _languageCode;

  /// The function used to validate the language code.
  final LanguageValidator _validateLanguageCode;

  /// Intercepts the request to add the language code to the request path.
  ///
  /// [options] The request options.
  /// [handler] The request interceptor handler.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.queryParameters.containsKey('lang')) {
      handler.next(options);
      return;
    }

    final newOptions = options.copyWith(
      queryParameters: {...options.queryParameters, 'lang': _languageCode},
    );

    handler.next(newOptions);
  }

  /// Updates the language code used in the interceptor.
  ///
  /// The [languageCode] must be a valid language code supported by the
  /// application.
  void updateLanguageCode(String languageCode) {
    assert(
      _validateLanguageCode(languageCode),
      'Language code $languageCode is not supported by the application',
    );
    _languageCode = languageCode;
  }
}
