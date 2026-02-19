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
  final String pageVisualFamily;
  final String vintagePaperVariant;
  final String animationIntensity;

  const SettingsLoaded({
    required this.themeMode,
    required this.locale,
    required this.fontFamily,
    required this.themePreset,
    required this.showAttachmentBackdrop,
    required this.notebookCoverColor,
    required this.notebookCoverTexture,
    required this.pageVisualFamily,
    required this.vintagePaperVariant,
    required this.animationIntensity,
  });

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? fontFamily,
    String? themePreset,
    bool? showAttachmentBackdrop,
    int? notebookCoverColor,
    String? notebookCoverTexture,
    String? pageVisualFamily,
    String? vintagePaperVariant,
    String? animationIntensity,
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
      pageVisualFamily: pageVisualFamily ?? this.pageVisualFamily,
      vintagePaperVariant: vintagePaperVariant ?? this.vintagePaperVariant,
      animationIntensity: animationIntensity ?? this.animationIntensity,
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
    pageVisualFamily,
    vintagePaperVariant,
    animationIntensity,
  ];
}
