import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure {
  const factory AppFailure.network({int? status, String? message}) =
      NetworkFailure;
  const factory AppFailure.unauthorized() = UnauthorizedFailure;
  const factory AppFailure.forbidden() = ForbiddenFailure;
  const factory AppFailure.notFound([String? resource]) = NotFoundFailure;
  const factory AppFailure.conflict([String? hint]) = ConflictFailure;
  const factory AppFailure.serialization([String? message]) =
      SerializationFailure;
  const factory AppFailure.business([String? message]) = BusinessFailure;
  const factory AppFailure.unknown([String? message]) = UnknownFailure;
}
