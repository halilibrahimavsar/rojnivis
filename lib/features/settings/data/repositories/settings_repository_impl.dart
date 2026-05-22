import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/page_studio_models.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl(this._prefs);

  static const _themeModeKey = StorageKeys.themeMode;
  static const _localeKey = StorageKeys.locale;
  static const _fontKey = StorageKeys.fontFamily;
  static const _themePresetKey = StorageKeys.themePreset;
  static const _attachmentBackdropKey = StorageKeys.attachmentBackdrop;
  static const _coverColorKey = StorageKeys.notebookCoverColor;
  static const _coverTextureKey = StorageKeys.notebookCoverTexture;
  static const _pageVisualFamilyKey = StorageKeys.pageVisualFamily;
  static const _vintagePaperVariantKey = StorageKeys.vintagePaperVariant;
  static const _animationIntensityKey = StorageKeys.animationIntensity;
  static const _randomThemeEnabledKey = StorageKeys.randomThemeEnabled;
  static const _randomThemeIntervalKey = StorageKeys.randomThemeIntervalSeconds;

  @override
  Future<(Failure?, UserSettings?)> getSettings() async {
    try {
      final themeModeRaw = _prefs.get(_themeModeKey);
      final themeMode = _parseThemeModeRaw(themeModeRaw);

      final themePreset =
          _readString(_themePresetKey) ?? AppDefaults.defaultThemePreset;
      final fontFamily = _readString(_fontKey) ?? AppDefaults.defaultFontFamily;
      final showAttachmentBackdrop =
          _readBool(_attachmentBackdropKey) ??
          AppDefaults.defaultAttachmentBackdrop;
      final notebookCoverColor =
          _prefs.getInt(_coverColorKey) ??
          AppDefaults.defaultNotebookCoverColor;
      final notebookCoverTexture =
          _readString(_coverTextureKey) ??
          AppDefaults.defaultNotebookCoverTexture;
      final pageVisualFamily =
          _readString(_pageVisualFamilyKey) ??
          AppDefaults.defaultPageVisualFamily;
      final vintagePaperVariant =
          _readString(_vintagePaperVariantKey) ??
          AppDefaults.defaultVintagePaperVariant;
      final animationIntensity =
          _readString(_animationIntensityKey) ??
          AppDefaults.defaultAnimationIntensity;
      final isRandomThemeEnabled =
          _readBool(_randomThemeEnabledKey) ??
          AppDefaults.defaultRandomThemeEnabled;
      final randomThemeIntervalSeconds =
          _prefs.getInt(_randomThemeIntervalKey) ??
          AppDefaults.defaultRandomThemeIntervalSeconds;

      final localeRaw =
          _readString(_localeKey) ??
          '${AppDefaults.defaultLocale}-${AppDefaults.defaultCountryCode}';
      final locale = _parseLocale(localeRaw);

      return (
        null,
        UserSettings(
          themeMode: themeMode,
          locale: locale,
          fontFamily: fontFamily,
          themePreset: themePreset,
          showAttachmentBackdrop: showAttachmentBackdrop,
          notebookCoverColor: notebookCoverColor,
          notebookCoverTexture: notebookCoverTexture,
          pageVisualFamily: _sanitizePageVisualFamily(pageVisualFamily),
          vintagePaperVariant: _sanitizeVintagePaperVariant(
            vintagePaperVariant,
          ),
          animationIntensity: _sanitizeAnimationIntensity(animationIntensity),
          isRandomThemeEnabled: isRandomThemeEnabled,
          randomThemeIntervalSeconds: randomThemeIntervalSeconds,
        ),
      );
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> updateSetting(UserSettings settings) async {
    try {
      await Future.wait([
        _prefs.setString(_themeModeKey, _themeModeToString(settings.themeMode)),
        _prefs.setString(
          _localeKey,
          '${settings.locale.languageCode}-${settings.locale.countryCode}',
        ),
        _prefs.setString(_fontKey, settings.fontFamily),
        _prefs.setString(_themePresetKey, settings.themePreset),
        _prefs.setBool(_attachmentBackdropKey, settings.showAttachmentBackdrop),
        _prefs.setInt(_coverColorKey, settings.notebookCoverColor),
        _prefs.setString(_coverTextureKey, settings.notebookCoverTexture),
        _prefs.setString(_pageVisualFamilyKey, settings.pageVisualFamily),
        _prefs.setString(_vintagePaperVariantKey, settings.vintagePaperVariant),
        _prefs.setString(_animationIntensityKey, settings.animationIntensity),
        _prefs.setBool(_randomThemeEnabledKey, settings.isRandomThemeEnabled),
        _prefs.setInt(
          _randomThemeIntervalKey,
          settings.randomThemeIntervalSeconds,
        ),
      ]);
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
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
    if (raw is String) {
      switch (raw) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    }
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
    final normalized = value.replaceAll('_', '-');
    final parts = normalized.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    if (parts.length == 1 && parts[0].isNotEmpty) {
      return Locale(parts[0]);
    }
    return const Locale(
      AppDefaults.defaultLocale,
      AppDefaults.defaultCountryCode,
    );
  }

  String? _readString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  bool? _readBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  String _sanitizePageVisualFamily(String value) {
    return PageVisualFamilyX.fromId(value).id;
  }

  String _sanitizeVintagePaperVariant(String value) {
    return VintagePaperVariantX.fromId(value).id;
  }

  String _sanitizeAnimationIntensity(String value) {
    return AnimationIntensityX.fromId(value).id;
  }
}
