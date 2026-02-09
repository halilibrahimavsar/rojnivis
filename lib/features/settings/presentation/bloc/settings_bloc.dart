import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._prefs) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoad);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLocale>(_onUpdateLocale);
    on<UpdateFontFamily>(_onUpdateFontFamily);
    on<UpdateThemePreset>(_onUpdateThemePreset);
    on<UpdateAttachmentBackdrop>(_onUpdateAttachmentBackdrop);
    on<UpdateNotebookCoverColor>(_onUpdateNotebookCoverColor);
    on<UpdateNotebookCoverTexture>(_onUpdateNotebookCoverTexture);
  }

  final SharedPreferences _prefs;

  static const _themeModeKey = StorageKeys.themeMode;
  static const _localeKey = StorageKeys.locale;
  static const _fontKey = StorageKeys.fontFamily;
  static const _themePresetKey = StorageKeys.themePreset;
  static const _attachmentBackdropKey = StorageKeys.attachmentBackdrop;
  static const _coverColorKey = StorageKeys.notebookCoverColor;
  static const _coverTextureKey = StorageKeys.notebookCoverTexture;

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      final themeModeRaw = _prefs.get(_themeModeKey);
      final themeMode = _parseThemeModeRaw(themeModeRaw);
      final themeModeStr = _themeModeToString(themeMode);

      final themePreset =
          _readString(_themePresetKey) ?? AppDefaults.defaultThemePreset;
      final fontFamily = _readString(_fontKey) ?? AppDefaults.defaultFontFamily;
      final showAttachmentBackdrop =
          _readBool(_attachmentBackdropKey) ??
          AppDefaults.defaultAttachmentBackdrop;
      final notebookCoverColor =
          _prefs.getInt(_coverColorKey) ?? AppDefaults.defaultNotebookCoverColor;
      final notebookCoverTexture =
          _readString(_coverTextureKey) ?? AppDefaults.defaultNotebookCoverTexture;

      final localeRaw =
          _readString(_localeKey) ??
          '${AppDefaults.defaultLocale}-${AppDefaults.defaultCountryCode}';
      final normalizedLocaleStr = _normalizeLocale(localeRaw);
      final locale = _parseLocale(normalizedLocaleStr);

      emit(
        SettingsLoaded(
          themeMode: themeMode,
          locale: locale,
          fontFamily: fontFamily,
          themePreset: themePreset,
          showAttachmentBackdrop: showAttachmentBackdrop,
          notebookCoverColor: notebookCoverColor,
          notebookCoverTexture: notebookCoverTexture,
        ),
      );

      final futures = <Future<void>>[];
      if (themeModeRaw is! String || themeModeRaw != themeModeStr) {
        futures.add(_prefs.setString(_themeModeKey, themeModeStr));
      }
      if (localeRaw != normalizedLocaleStr) {
        futures.add(_prefs.setString(_localeKey, normalizedLocaleStr));
      }
      await Future.wait(futures);
    } catch (_) {
      emit(
        const SettingsLoaded(
          themeMode: ThemeMode.system,
          locale: Locale(AppDefaults.defaultLocale, AppDefaults.defaultCountryCode),
          fontFamily: AppDefaults.defaultFontFamily,
          themePreset: AppDefaults.defaultThemePreset,
          showAttachmentBackdrop: AppDefaults.defaultAttachmentBackdrop,
          notebookCoverColor: AppDefaults.defaultNotebookCoverColor,
          notebookCoverTexture: AppDefaults.defaultNotebookCoverTexture,
        ),
      );
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setString(_themeModeKey, _themeModeToString(event.themeMode));
    emit(current.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onUpdateLocale(
    UpdateLocale event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    final localeStr =
        '${event.locale.languageCode}-${event.locale.countryCode}';
    await _prefs.setString(_localeKey, localeStr);
    emit(current.copyWith(locale: event.locale));
  }

  Future<void> _onUpdateFontFamily(
    UpdateFontFamily event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setString(_fontKey, event.fontFamily);
    emit(current.copyWith(fontFamily: event.fontFamily));
  }

  Future<void> _onUpdateThemePreset(
    UpdateThemePreset event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setString(_themePresetKey, event.themePreset);
    emit(current.copyWith(themePreset: event.themePreset));
  }

  Future<void> _onUpdateAttachmentBackdrop(
    UpdateAttachmentBackdrop event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setBool(_attachmentBackdropKey, event.enabled);
    emit(current.copyWith(showAttachmentBackdrop: event.enabled));
  }

  Future<void> _onUpdateNotebookCoverColor(
    UpdateNotebookCoverColor event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setInt(_coverColorKey, event.color);
    emit(current.copyWith(notebookCoverColor: event.color));
  }

  Future<void> _onUpdateNotebookCoverTexture(
    UpdateNotebookCoverTexture event,
    Emitter<SettingsState> emit,
  ) async {
    final current = _requireLoaded();
    await _prefs.setString(_coverTextureKey, event.texture);
    emit(current.copyWith(notebookCoverTexture: event.texture));
  }

  SettingsLoaded _requireLoaded() {
    final state = this.state;
    if (state is SettingsLoaded) return state;
    return const SettingsLoaded(
      themeMode: ThemeMode.system,
      locale: Locale(AppDefaults.defaultLocale, AppDefaults.defaultCountryCode),
      fontFamily: AppDefaults.defaultFontFamily,
      themePreset: AppDefaults.defaultThemePreset,
      showAttachmentBackdrop: AppDefaults.defaultAttachmentBackdrop,
      notebookCoverColor: AppDefaults.defaultNotebookCoverColor,
      notebookCoverTexture: AppDefaults.defaultNotebookCoverTexture,
    );
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  ThemeMode _parseThemeModeRaw(Object? raw) {
    if (raw is int) {
      switch (raw) {
        case 1:
          return ThemeMode.light;
        case 2:
          return ThemeMode.dark;
        case 0:
        default:
          return ThemeMode.system;
      }
    }
    if (raw is String) return _parseThemeMode(raw);
    return ThemeMode.system;
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Locale _parseLocale(String value) {
    final normalized = _normalizeLocale(value);
    final parts = normalized.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    if (parts.length == 1 && parts[0].isNotEmpty) {
      return Locale(parts[0]);
    }
    return const Locale(AppDefaults.defaultLocale, AppDefaults.defaultCountryCode);
  }

  String _normalizeLocale(String value) => value.replaceAll('_', '-');

  String? _readString(String key) {
    final value = _prefs.get(key);
    if (value is String) return value;
    return null;
  }

  bool? _readBool(String key) {
    final value = _prefs.get(key);
    if (value is bool) return value;
    return null;
  }
}
