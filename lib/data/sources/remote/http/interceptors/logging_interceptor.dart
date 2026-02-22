import 'package:dio/dio.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.enabled = true});
  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      appLogger.fine('--> ${options.method} ${options.uri}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      appLogger.info(
        '<-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      appLogger.warning(
        'xx  ${err.response?.statusCode} ${err.requestOptions.uri} ${err.message}',
      );
    }
    super.onError(err, handler);
  }
}
