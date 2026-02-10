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
  final int notebookCoverColor;
  final String notebookCoverTexture;
  final String aiApiKey;

  const SettingsLoaded({
    required this.themeMode,
    required this.locale,
    required this.fontFamily,
    required this.themePreset,
    required this.showAttachmentBackdrop,
    required this.notebookCoverColor,
    required this.notebookCoverTexture,
    required this.aiApiKey,
  });

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? fontFamily,
    String? themePreset,
    bool? showAttachmentBackdrop,
    int? notebookCoverColor,
    String? notebookCoverTexture,
    String? aiApiKey,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontFamily: fontFamily ?? this.fontFamily,
      themePreset: themePreset ?? this.themePreset,
      showAttachmentBackdrop:
          showAttachmentBackdrop ?? this.showAttachmentBackdrop,
      notebookCoverColor: notebookCoverColor ?? this.notebookCoverColor,
      notebookCoverTexture: notebookCoverTexture ?? this.notebookCoverTexture,
      aiApiKey: aiApiKey ?? this.aiApiKey,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    locale,
    fontFamily,
    themePreset,
    showAttachmentBackdrop,
    notebookCoverColor,
    notebookCoverTexture,
    aiApiKey,
  ];
}
