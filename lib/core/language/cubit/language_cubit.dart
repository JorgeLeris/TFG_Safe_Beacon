import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/data/sources/remote/http/interceptors/language_interceptor.dart';
import 'package:safe_beacon/data/repositories/app_settings_repository.dart';

part 'language_cubit.freezed.dart';
part 'language_state.dart';

/// A [Cubit] that manages the state of the language settings in the
/// application.
///
/// The [LanguageCubit] class is responsible for changing the locale and
/// persisting the language code using the [AppSettingsRepository].
class LanguageCubit extends Cubit<LanguageState> {
  /// Creates a [LanguageCubit] with the given [locale] and
  /// [appSettingsRepository].
  ///
  /// The [locale] and [appSettingsRepository] parameters must not be null.
  LanguageCubit({
    required Locale locale,
    required AppSettingsRepository appSettingsRepository,
    required LanguageInterceptor interceptor,
  }) : _appSettingsRepository = appSettingsRepository,
       _interceptor = interceptor,
       super(LanguageState.initial(locale: locale));

  /// The repository for managing application settings.
  final AppSettingsRepository _appSettingsRepository;

  /// The interceptor for managing language changes.
  final LanguageInterceptor _interceptor;

  /// Changes the locale and persists the language code.
  ///
  /// The [locale] parameter must not be null. This method updates the state
  /// with the new locale.
  Future<void> changeLocale(Locale locale) async {
    await _appSettingsRepository.setLanguageCode(
      languageCode: locale.languageCode,
    );
    _interceptor.updateLanguageCode(locale.languageCode);
    emit(LanguageState.initial(locale: locale));
  }
}
