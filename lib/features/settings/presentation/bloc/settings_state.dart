part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  final UserSettings settings;
  final String? activeRandomThemePreset;

  const SettingsLoaded({required this.settings, this.activeRandomThemePreset});

  String get effectiveThemePreset =>
      activeRandomThemePreset ?? settings.themePreset;

  @override
  List<Object?> get props => [settings, activeRandomThemePreset];

  SettingsLoaded copyWith({
    UserSettings? settings,
    String? activeRandomThemePreset,
    bool clearRandomTheme = false,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      activeRandomThemePreset:
          clearRandomTheme
              ? null
              : (activeRandomThemePreset ?? this.activeRandomThemePreset),
    );
  }
}
