import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

class ResultCallAdapter<T>
    extends CallAdapter<Future<HttpResponse<T>>, Future<Result<T>>> {
  ResultCallAdapter();

  @override
  Future<Result<T>> adapt(Future<HttpResponse<T>> Function() call) async {
    try {
      final response = await call();
      final statusCode = response.response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;
        if (data == null) {
          return const Result.failure(AppFailure.notFound());
        }
        return Result.success(data);
      }
      return Result.failure(
        _mapStatusToFailure(
          statusCode,
          message: response.response.statusMessage,
        ),
      );
    } on DioException catch (error) {
      return Result.failure(_mapDioException(error));
    } on FormatException catch (error) {
      return Result.failure(AppFailure.serialization(error.message));
    } catch (error) {
      return Result.failure(AppFailure.unknown(error.toString()));
    }
  }

  AppFailure _mapDioException(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
      final message = error.response?.statusMessage ?? error.message;
      return _mapStatusToFailure(status, message: message);
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const AppFailure.network(
        message: 'Connection timeout',
      ),
      DioExceptionType.badCertificate => const AppFailure.forbidden(),
      DioExceptionType.badResponse => AppFailure.network(
        message: error.message,
      ),
      DioExceptionType.cancel => const AppFailure.business('Request cancelled'),
      DioExceptionType.unknown ||
      DioExceptionType.connectionError => AppFailure.unknown(error.message),
    };
  }

  AppFailure _mapStatusToFailure(int status, {String? message}) {
    switch (status) {
      case 401:
        return const AppFailure.unauthorized();
      case 403:
        return const AppFailure.forbidden();
      case 404:
        return const AppFailure.notFound();
      case 409:
        return const AppFailure.conflict();
      default:
        return AppFailure.network(status: status, message: message);
    }
  }
}
