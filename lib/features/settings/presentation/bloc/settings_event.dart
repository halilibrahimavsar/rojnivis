part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateLocale extends SettingsEvent {
  final Locale locale;

  const UpdateLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

class UpdateFontFamily extends SettingsEvent {
  final String fontFamily;

  const UpdateFontFamily(this.fontFamily);

  @override
  List<Object?> get props => [fontFamily];
}

class UpdateThemePreset extends SettingsEvent {
  final String themePreset;

  const UpdateThemePreset(this.themePreset);

  @override
  List<Object?> get props => [themePreset];
}

class UpdateAttachmentBackdrop extends SettingsEvent {
  final bool enabled;

  const UpdateAttachmentBackdrop(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateNotebookCoverColor extends SettingsEvent {
  final int color;

  const UpdateNotebookCoverColor(this.color);

  @override
  List<Object?> get props => [color];
}

class UpdateNotebookCoverTexture extends SettingsEvent {
  final String texture;

  const UpdateNotebookCoverTexture(this.texture);

  @override
  List<Object?> get props => [texture];
}

class UpdatePageVisualFamily extends SettingsEvent {
  final String pageVisualFamily;

  const UpdatePageVisualFamily(this.pageVisualFamily);

  @override
  List<Object?> get props => [pageVisualFamily];
}

class UpdateVintagePaperVariant extends SettingsEvent {
  final String vintagePaperVariant;

  const UpdateVintagePaperVariant(this.vintagePaperVariant);

  @override
  List<Object?> get props => [vintagePaperVariant];
}

class UpdateAnimationIntensity extends SettingsEvent {
  final String animationIntensity;

  const UpdateAnimationIntensity(this.animationIntensity);

  @override
  List<Object?> get props => [animationIntensity];
}
