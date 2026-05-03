import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';

part 'theme_cubit.freezed.dart';
part 'theme_state.dart';

/// A [Cubit] that manages the [ThemeMode] of the application.
///
/// When [ThemeMode.system], the app follows the device setting. Once the user
/// picks a preference from settings, it is persisted and always takes priority.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required ThemeMode themeMode,
    required AppSettingsRepository appSettingsRepository,
  }) : _appSettingsRepository = appSettingsRepository,
       super(ThemeState.initial(themeMode: themeMode));

  final AppSettingsRepository _appSettingsRepository;

  /// Updates the [ThemeMode] and persists the user preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _appSettingsRepository.setThemeMode(
      themeMode: mode == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(ThemeState.initial(themeMode: mode));
  }
}
