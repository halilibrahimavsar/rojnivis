import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rojnivis/features/settings/domain/entities/user_settings.dart';
import 'package:rojnivis/features/settings/domain/usecases/get_settings.dart';
import 'package:rojnivis/features/settings/domain/usecases/update_settings.dart';
import 'package:rojnivis/features/settings/presentation/bloc/settings_bloc.dart';

class MockGetSettings extends Mock implements GetSettings {}

class MockUpdateSettings extends Mock implements UpdateSettings {}

void main() {
  late GetSettings mockGetSettings;
  late UpdateSettings mockUpdateSettings;

  final tSettings = UserSettings(
    themeMode: ThemeMode.system,
    locale: const Locale('en', 'US'),
    fontFamily: 'Poppins',
    themePreset: 'default',
    showAttachmentBackdrop: true,
    notebookCoverColor: 0xFF2C3E50,
    notebookCoverTexture: 'leather',
    pageVisualFamily: 'classic',
    vintagePaperVariant: 'parchment',
    animationIntensity: 'subtle',
  );

  setUpAll(() {
    registerFallbackValue(tSettings);
  });

  setUp(() {
    mockGetSettings = MockGetSettings();
    mockUpdateSettings = MockUpdateSettings();
  });

  SettingsBloc buildBloc() => SettingsBloc(mockGetSettings, mockUpdateSettings);

  group('SettingsBloc', () {
    test('initial state is SettingsInitial', () {
      expect(buildBloc().state, const SettingsInitial());
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] when LoadSettings is added',
        setUp: () {
          when(
            () => mockGetSettings(),
          ).thenAnswer((_) async => (null, tSettings));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [SettingsLoaded(settings: tSettings)],
        verify: (_) {
          verify(() => mockGetSettings()).called(1);
        },
      );
    });

    group('UpdateThemeMode', () {
      final newSettings = tSettings.copyWith(themeMode: ThemeMode.dark);

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with new theme mode when update is successful',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdateThemeMode(ThemeMode.dark)),
        expect: () => [SettingsLoaded(settings: newSettings)],
        verify: (_) {
          verify(() => mockUpdateSettings(newSettings)).called(1);
        },
      );
    });

    group('UpdateFontFamily', () {
      final newSettings = tSettings.copyWith(fontFamily: 'Inter');

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with new font family',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdateFontFamily('Inter')),
        expect: () => [SettingsLoaded(settings: newSettings)],
      );
    });

    group('UpdateThemePreset', () {
      final newSettings = tSettings.copyWith(themePreset: 'sunset');

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with new theme preset',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdateThemePreset('sunset')),
        expect: () => [SettingsLoaded(settings: newSettings)],
      );
    });

    group('UpdateLocale', () {
      final newLocale = const Locale('tr', 'TR');
      final newSettings = tSettings.copyWith(locale: newLocale);

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoaded] with new locale',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(UpdateLocale(newLocale)),
        expect: () => [SettingsLoaded(settings: newSettings)],
      );
    });

    group('PageStudioSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates page visual family',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdatePageVisualFamily('vintage')),
        expect:
            () => [
              SettingsLoaded(
                settings: tSettings.copyWith(pageVisualFamily: 'vintage'),
              ),
            ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'updates vintage paper variant',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdateVintagePaperVariant('sepia_diary')),
        expect:
            () => [
              SettingsLoaded(
                settings: tSettings.copyWith(
                  vintagePaperVariant: 'sepia_diary',
                ),
              ),
            ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'updates animation intensity',
        setUp: () {
          when(
            () => mockUpdateSettings(any()),
          ).thenAnswer((_) async => (null, null));
        },
        build: buildBloc,
        seed: () => SettingsLoaded(settings: tSettings),
        act: (bloc) => bloc.add(const UpdateAnimationIntensity('cinematic')),
        expect:
            () => [
              SettingsLoaded(
                settings: tSettings.copyWith(animationIntensity: 'cinematic'),
              ),
            ],
      );
    });
  });
}
