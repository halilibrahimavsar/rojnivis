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
  final ThemeMode themeMode;
  final Locale locale;
  final String fontFamily;
  final String themePreset;
  final bool showAttachmentBackdrop;

  const SettingsLoaded({
    required this.themeMode,
    required this.locale,
    required this.fontFamily,
    required this.themePreset,
    required this.showAttachmentBackdrop,
  });

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? fontFamily,
    String? themePreset,
    bool? showAttachmentBackdrop,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontFamily: fontFamily ?? this.fontFamily,
      themePreset: themePreset ?? this.themePreset,
      showAttachmentBackdrop:
          showAttachmentBackdrop ?? this.showAttachmentBackdrop,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    locale,
    fontFamily,
    themePreset,
    showAttachmentBackdrop,
  ];
}
