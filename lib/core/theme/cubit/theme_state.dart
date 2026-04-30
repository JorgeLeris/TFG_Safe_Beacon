part of 'theme_cubit.dart';

@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState.initial({required ThemeMode themeMode}) = _Initial;
}
