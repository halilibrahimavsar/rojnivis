part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final String fontFamily;

  const SettingsLoaded({
    required this.themeMode,
    required this.locale,
    required this.fontFamily,
  });

  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? fontFamily,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  List<Object> get props => [themeMode, locale, fontFamily];
}
