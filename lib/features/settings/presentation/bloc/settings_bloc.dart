import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _prefs;

  SettingsBloc(this._prefs) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeFont>(_onChangeFont);
  }

  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language_code';
  static const String _fontKey = 'font_family';

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    final themeIndex =
        _prefs.getInt(_themeKey) ?? 0; // 0: System, 1: Light, 2: Dark
    final langCode = _prefs.getString(_langKey) ?? 'tr';
    final fontFamily = _prefs.getString(_fontKey) ?? 'Poppins';

    emit(
      SettingsLoaded(
        themeMode: ThemeMode.values[themeIndex],
        locale: Locale(langCode, langCode == 'en' ? 'US' : 'TR'),
        fontFamily: fontFamily,
      ),
    );
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setInt(_themeKey, event.themeMode.index);
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      emit(currentState.copyWith(themeMode: event.themeMode));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setString(_langKey, event.locale.languageCode);
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      emit(currentState.copyWith(locale: event.locale));
    }
  }

  Future<void> _onChangeFont(
    ChangeFont event,
    Emitter<SettingsState> emit,
  ) async {
    await _prefs.setString(_fontKey, event.fontFamily);
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      emit(currentState.copyWith(fontFamily: event.fontFamily));
    }
  }
}
