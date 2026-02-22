import 'package:dio/dio.dart';
import 'package:safe_beacon/app/config/environment.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/auth_interceptor.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/logging_interceptor.dart';

Dio buildDio(Environment env, {AuthTokenProvider? tokens}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(LoggingInterceptor(enabled: env.logNetwork));
  dio.interceptors.add(AuthInterceptor(tokens: tokens));
  return dio;
}
