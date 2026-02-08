part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeTheme(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class ChangeLanguage extends SettingsEvent {
  final Locale locale;

  const ChangeLanguage(this.locale);

  @override
  List<Object> get props => [locale];
}

class ChangeFont extends SettingsEvent {
  final String fontFamily;

  const ChangeFont(this.fontFamily);

  @override
  List<Object> get props => [fontFamily];
}
