part of 'language_cubit.dart';

/// A state class for managing language settings in the application.
///
/// The [LanguageState] class uses the `freezed` package to generate immutable
/// state classes and union types.
@freezed
abstract class LanguageState with _$LanguageState {
  /// The initial state of the language settings.
  ///
  /// The [locale] parameter must not be null.
  const factory LanguageState.initial({required Locale locale}) = _Initial;
}
