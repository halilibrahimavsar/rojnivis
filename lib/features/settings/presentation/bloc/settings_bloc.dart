import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/theme/app_theme.dart';

import '../../domain/entities/user_settings.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  Timer? _randomThemeTimer;

  SettingsBloc(this._getSettings, this._updateSettings)
    : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoad);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLocale>(_onUpdateLocale);
    on<UpdateFontFamily>(_onUpdateFontFamily);
    on<UpdateThemePreset>(_onUpdateThemePreset);
    on<UpdateAttachmentBackdrop>(_onUpdateAttachmentBackdrop);
    on<UpdateNotebookCoverColor>(_onUpdateNotebookCoverColor);
    on<UpdateNotebookCoverTexture>(_onUpdateNotebookCoverTexture);
    on<UpdatePageVisualFamily>(_onUpdatePageVisualFamily);
    on<UpdateVintagePaperVariant>(_onUpdateVintagePaperVariant);
    on<UpdateAnimationIntensity>(_onUpdateAnimationIntensity);
    on<UpdateRandomThemeEnabled>(_onUpdateRandomThemeEnabled);
    on<UpdateRandomThemeInterval>(_onUpdateRandomThemeInterval);
    on<_RotateRandomTheme>(_onRotateRandomTheme);
  }

  @override
  Future<void> close() {
    _randomThemeTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    final (failure, settings) = await _getSettings();

    if (failure != null || settings == null) {
      // Handle failure or emit default
      return;
    }

    _updateRandomThemeTimer(settings);
    emit(SettingsLoaded(settings: settings));
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(themeMode: event.themeMode);
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateLocale(
    UpdateLocale event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(locale: event.locale);
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateFontFamily(
    UpdateFontFamily event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(fontFamily: event.fontFamily);
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateThemePreset(
    UpdateThemePreset event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        themePreset: event.themePreset,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateAttachmentBackdrop(
    UpdateAttachmentBackdrop event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        showAttachmentBackdrop: event.enabled,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateNotebookCoverColor(
    UpdateNotebookCoverColor event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        notebookCoverColor: event.color,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateNotebookCoverTexture(
    UpdateNotebookCoverTexture event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        notebookCoverTexture: event.texture,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdatePageVisualFamily(
    UpdatePageVisualFamily event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        pageVisualFamily: event.pageVisualFamily,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateVintagePaperVariant(
    UpdateVintagePaperVariant event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        vintagePaperVariant: event.vintagePaperVariant,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateAnimationIntensity(
    UpdateAnimationIntensity event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        animationIntensity: event.animationIntensity,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onUpdateRandomThemeEnabled(
    UpdateRandomThemeEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        isRandomThemeEnabled: event.enabled,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        _updateRandomThemeTimer(newSettings);
        emit(
          state.copyWith(
            settings: newSettings,
            clearRandomTheme: !event.enabled,
          ),
        );
      }
    }
  }

  Future<void> _onUpdateRandomThemeInterval(
    UpdateRandomThemeInterval event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded) {
      final newSettings = state.settings.copyWith(
        randomThemeIntervalSeconds: event.seconds,
      );
      final (failure, _) = await _updateSettings(newSettings);
      if (failure == null) {
        _updateRandomThemeTimer(newSettings);
        emit(state.copyWith(settings: newSettings));
      }
    }
  }

  Future<void> _onRotateRandomTheme(
    _RotateRandomTheme event,
    Emitter<SettingsState> emit,
  ) async {
    final state = this.state;
    if (state is SettingsLoaded && state.settings.isRandomThemeEnabled) {
      final random = Random();
      final values =
          AppThemePreset.values
              .where((p) => p != AppThemePreset.defaultPreset)
              .toList();
      final randomPreset = values[random.nextInt(values.length)];
      emit(state.copyWith(activeRandomThemePreset: randomPreset.id));
    }
  }

  void _updateRandomThemeTimer(UserSettings settings) {
    _randomThemeTimer?.cancel();
    if (settings.isRandomThemeEnabled) {
      // Trigger once immediately
      add(const _RotateRandomTheme());
      _randomThemeTimer = Timer.periodic(
        Duration(seconds: settings.randomThemeIntervalSeconds),
        (_) => add(const _RotateRandomTheme()),
      );
    }
  }
}
