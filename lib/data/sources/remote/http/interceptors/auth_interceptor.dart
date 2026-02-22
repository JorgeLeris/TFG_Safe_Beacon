import 'package:dio/dio.dart';

abstract class AuthTokenProvider {
  String? get token;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.tokens});
  final AuthTokenProvider? tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = tokens?.token;
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    super.onRequest(options, handler);
  }
}
