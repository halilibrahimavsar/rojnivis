import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rojnivis/features/settings/presentation/bloc/settings_bloc.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  SettingsBloc buildBloc() => SettingsBloc(prefs);

  group('SettingsBloc', () {
    test('initial state is SettingsInitial', () {
      expect(buildBloc().state, const SettingsInitial());
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsLoaded with defaults when no values stored',
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.themeMode, ThemeMode.system);
          expect(state.fontFamily, 'Poppins');
          expect(state.pageVisualFamily, 'classic');
          expect(state.vintagePaperVariant, 'parchment');
          expect(state.animationIntensity, 'subtle');
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsLoaded with stored values',
        setUp: () async {
          await prefs.setString('theme_mode', 'dark');
          await prefs.setString('font_family', 'Roboto');
          await prefs.setString('theme_preset', 'ocean');
          await prefs.setString('page_visual_family', 'vintage');
          await prefs.setString('vintage_paper_variant', 'pressed_floral');
          await prefs.setString('animation_intensity', 'cinematic');
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.themeMode, ThemeMode.dark);
          expect(state.fontFamily, 'Roboto');
          expect(state.themePreset, 'ocean');
          expect(state.pageVisualFamily, 'vintage');
          expect(state.vintagePaperVariant, 'pressed_floral');
          expect(state.animationIntensity, 'cinematic');
        },
      );
    });

    group('UpdateThemeMode', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates theme mode and persists to SharedPreferences',
        build: buildBloc,
        seed:
            () => const SettingsLoaded(
              themeMode: ThemeMode.system,
              locale: Locale('tr', 'TR'),
              fontFamily: 'Poppins',
              themePreset: 'default',
              showAttachmentBackdrop: true,
              notebookCoverColor: 0xFF2C3E50,
              notebookCoverTexture: 'leather',
              pageVisualFamily: 'classic',
              vintagePaperVariant: 'parchment',
              animationIntensity: 'subtle',
            ),
        act: (bloc) => bloc.add(const UpdateThemeMode(ThemeMode.dark)),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.themeMode, ThemeMode.dark);
          expect(prefs.getString('theme_mode'), 'dark');
        },
      );
    });

    group('UpdateFontFamily', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates font family and persists',
        build: buildBloc,
        seed:
            () => const SettingsLoaded(
              themeMode: ThemeMode.system,
              locale: Locale('tr', 'TR'),
              fontFamily: 'Poppins',
              themePreset: 'default',
              showAttachmentBackdrop: true,
              notebookCoverColor: 0xFF2C3E50,
              notebookCoverTexture: 'leather',
              pageVisualFamily: 'classic',
              vintagePaperVariant: 'parchment',
              animationIntensity: 'subtle',
            ),
        act: (bloc) => bloc.add(const UpdateFontFamily('Inter')),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.fontFamily, 'Inter');
          expect(prefs.getString('font_family'), 'Inter');
        },
      );
    });

    group('UpdateThemePreset', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates theme preset and persists',
        build: buildBloc,
        seed:
            () => const SettingsLoaded(
              themeMode: ThemeMode.system,
              locale: Locale('tr', 'TR'),
              fontFamily: 'Poppins',
              themePreset: 'default',
              showAttachmentBackdrop: true,
              notebookCoverColor: 0xFF2C3E50,
              notebookCoverTexture: 'leather',
              pageVisualFamily: 'classic',
              vintagePaperVariant: 'parchment',
              animationIntensity: 'subtle',
            ),
        act: (bloc) => bloc.add(const UpdateThemePreset('sunset')),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.themePreset, 'sunset');
        },
      );
    });

    group('UpdateLocale', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates locale and persists',
        build: buildBloc,
        seed:
            () => const SettingsLoaded(
              themeMode: ThemeMode.system,
              locale: Locale('tr', 'TR'),
              fontFamily: 'Poppins',
              themePreset: 'default',
              showAttachmentBackdrop: true,
              notebookCoverColor: 0xFF2C3E50,
              notebookCoverTexture: 'leather',
              pageVisualFamily: 'classic',
              vintagePaperVariant: 'parchment',
              animationIntensity: 'subtle',
            ),
        act: (bloc) => bloc.add(const UpdateLocale(Locale('en', 'US'))),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.locale, const Locale('en', 'US'));
        },
      );
    });

    group('PageStudioSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates page visual family and persists',
        build: buildBloc,
        seed: () => const SettingsLoaded(
          themeMode: ThemeMode.system,
          locale: Locale('tr', 'TR'),
          fontFamily: 'Poppins',
          themePreset: 'default',
          showAttachmentBackdrop: true,
          notebookCoverColor: 0xFF2C3E50,
          notebookCoverTexture: 'leather',
          pageVisualFamily: 'classic',
          vintagePaperVariant: 'parchment',
          animationIntensity: 'subtle',
        ),
        act: (bloc) => bloc.add(const UpdatePageVisualFamily('vintage')),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.pageVisualFamily, 'vintage');
          expect(prefs.getString('page_visual_family'), 'vintage');
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'updates vintage paper variant and persists',
        build: buildBloc,
        seed: () => const SettingsLoaded(
          themeMode: ThemeMode.system,
          locale: Locale('tr', 'TR'),
          fontFamily: 'Poppins',
          themePreset: 'default',
          showAttachmentBackdrop: true,
          notebookCoverColor: 0xFF2C3E50,
          notebookCoverTexture: 'leather',
          pageVisualFamily: 'vintage',
          vintagePaperVariant: 'parchment',
          animationIntensity: 'subtle',
        ),
        act: (bloc) =>
            bloc.add(const UpdateVintagePaperVariant('sepia_diary')),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.vintagePaperVariant, 'sepia_diary');
          expect(prefs.getString('vintage_paper_variant'), 'sepia_diary');
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'updates animation intensity and persists',
        build: buildBloc,
        seed: () => const SettingsLoaded(
          themeMode: ThemeMode.system,
          locale: Locale('tr', 'TR'),
          fontFamily: 'Poppins',
          themePreset: 'default',
          showAttachmentBackdrop: true,
          notebookCoverColor: 0xFF2C3E50,
          notebookCoverTexture: 'leather',
          pageVisualFamily: 'vintage',
          vintagePaperVariant: 'parchment',
          animationIntensity: 'subtle',
        ),
        act: (bloc) =>
            bloc.add(const UpdateAnimationIntensity('cinematic')),
        expect: () => [isA<SettingsLoaded>()],
        verify: (bloc) {
          final state = bloc.state as SettingsLoaded;
          expect(state.animationIntensity, 'cinematic');
          expect(prefs.getString('animation_intensity'), 'cinematic');
        },
      );
    });
  });
}
