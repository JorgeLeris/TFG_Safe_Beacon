import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';

part 'result.freezed.dart';

// Note: Use only for special APIs not based on general MiCC API response code
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppFailure failure) = Failure<T>;
}

extension ResultX<T> on Result<T> {
  /// Returns true if this Result is a Success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this Result is a Failure
  bool get isFailure => this is Failure<T>;

  /// Returns the success value or null if this Result is a Failure
  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;

  /// Handles only the success case while preserving the original Result.
  /// Useful for side effects without changing the Result.
  ///
  /// Example:
  /// ```dart
  /// result.onSuccess((data) => analytics.logSuccess());
  /// ```
  Result<T> onSuccess(Function(T value) action) {
    if (this is Success<T>) {
      action((this as Success<T>).value);
    }
    return this;
  }

  /// Handles only the failure case while preserving the original Result.
  /// Useful for error logging without affecting the flow.
  ///
  /// Example:
  /// ```dart
  /// result.onFailure((error) => logger.logError(error));
  /// ```
  Result<T> onFailure(Function(AppFailure failure) action) {
    if (this is Failure<T>) {
      action((this as Failure<T>).failure);
    }
    return this;
  }

  /// Transforms a successful `Result<T>` into `Result<R>`, preserving failures.
  /// Useful for chaining transformations on success values.
  ///
  /// Example:
  /// ```dart
  /// Result<User> userResult = getUserFromApi();
  /// Result<String> nameResult = userResult.mapSuccess((user) => user.name);
  /// ```
  Result<R> mapSuccess<R>(R Function(T) transform) {
    return when(
      success: (value) => Result<R>.success(transform(value)),
      failure: (error) => Result<R>.failure(error),
    );
  }
}
