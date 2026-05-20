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

  const SettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];

  SettingsLoaded copyWith({UserSettings? settings}) {
    return SettingsLoaded(settings: settings ?? this.settings);
  }
}
