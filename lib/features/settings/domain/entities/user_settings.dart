import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserSettings extends Equatable {
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
  final bool isRandomThemeEnabled;
  final int randomThemeIntervalSeconds;

  const UserSettings({
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
    required this.isRandomThemeEnabled,
    required this.randomThemeIntervalSeconds,
  });

  UserSettings copyWith({
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
    bool? isRandomThemeEnabled,
    int? randomThemeIntervalSeconds,
  }) {
    return UserSettings(
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
      isRandomThemeEnabled: isRandomThemeEnabled ?? this.isRandomThemeEnabled,
      randomThemeIntervalSeconds:
          randomThemeIntervalSeconds ?? this.randomThemeIntervalSeconds,
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
    isRandomThemeEnabled,
    randomThemeIntervalSeconds,
  ];
}
