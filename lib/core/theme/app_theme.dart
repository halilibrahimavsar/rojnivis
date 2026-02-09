import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

enum AppThemePreset {
  defaultPreset,
  love,
  futuristic,
  glass,
  neomorphic,
  sunset,
  ocean,
  forest,
  spring,
  autumn,
}

extension AppThemePresetX on AppThemePreset {
  String get id {
    switch (this) {
      case AppThemePreset.defaultPreset:
        return ThemePresets.defaultPreset;
      case AppThemePreset.love:
        return ThemePresets.love;
      case AppThemePreset.futuristic:
        return ThemePresets.futuristic;
      case AppThemePreset.glass:
        return ThemePresets.glass;
      case AppThemePreset.neomorphic:
        return ThemePresets.neomorphic;
      case AppThemePreset.sunset:
        return ThemePresets.sunset;
      case AppThemePreset.ocean:
        return ThemePresets.ocean;
      case AppThemePreset.forest:
        return ThemePresets.forest;
      case AppThemePreset.spring:
        return ThemePresets.spring;
      case AppThemePreset.autumn:
        return ThemePresets.autumn;
    }
  }

  static AppThemePreset fromId(String id) {
    switch (id) {
      case ThemePresets.love:
        return AppThemePreset.love;
      case ThemePresets.futuristic:
        return AppThemePreset.futuristic;
      case ThemePresets.glass:
        return AppThemePreset.glass;
      case ThemePresets.neomorphic:
        return AppThemePreset.neomorphic;
      case ThemePresets.sunset:
        return AppThemePreset.sunset;
      case ThemePresets.ocean:
        return AppThemePreset.ocean;
      case ThemePresets.forest:
        return AppThemePreset.forest;
      case ThemePresets.spring:
        return AppThemePreset.spring;
      case ThemePresets.autumn:
        return AppThemePreset.autumn;
      case ThemePresets.defaultPreset:
      default:
        return AppThemePreset.defaultPreset;
    }
  }
}

class ThemePresetOption {
  const ThemePresetOption({
    required this.preset,
    required this.labelKey,
    required this.previewColor,
  });

  final AppThemePreset preset;
  final String labelKey;
  final Color previewColor;

  String get id => preset.id;
}

class AppTheme {
  static final Map<String, TextTheme> _textThemes = {
    'Poppins': GoogleFonts.poppinsTextTheme(),
    'Playfair Display': GoogleFonts.playfairDisplayTextTheme(),
    'Lora': GoogleFonts.loraTextTheme(),
    'Nunito': GoogleFonts.nunitoTextTheme(),
    'Roboto': GoogleFonts.robotoTextTheme(),
    'Caveat': GoogleFonts.caveatTextTheme(),
    'Patrick Hand': GoogleFonts.patrickHandTextTheme(),
  };

  static final List<String> supportedFonts = List.unmodifiable(
    _textThemes.keys,
  );

  static final List<ThemePresetOption> presets = List.unmodifiable([
    ThemePresetOption(
      preset: AppThemePreset.defaultPreset,
      labelKey: 'theme_default',
      previewColor: _paletteFor(AppThemePreset.defaultPreset).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.love,
      labelKey: 'theme_love',
      previewColor: _paletteFor(AppThemePreset.love).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.sunset,
      labelKey: 'theme_sunset',
      previewColor: _paletteFor(AppThemePreset.sunset).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.ocean,
      labelKey: 'theme_ocean',
      previewColor: _paletteFor(AppThemePreset.ocean).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.forest,
      labelKey: 'theme_forest',
      previewColor: _paletteFor(AppThemePreset.forest).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.spring,
      labelKey: 'theme_spring',
      previewColor: _paletteFor(AppThemePreset.spring).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.autumn,
      labelKey: 'theme_autumn',
      previewColor: _paletteFor(AppThemePreset.autumn).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.futuristic,
      labelKey: 'theme_futuristic',
      previewColor: _paletteFor(AppThemePreset.futuristic).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.glass,
      labelKey: 'theme_glass',
      previewColor: _paletteFor(AppThemePreset.glass).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.neomorphic,
      labelKey: 'theme_neomorphic',
      previewColor: _paletteFor(AppThemePreset.neomorphic).seed,
    ),
  ]);

  static TextTheme getTextTheme(String fontFamily) {
    return _textThemes[fontFamily] ?? GoogleFonts.poppinsTextTheme();
  }

  static ThemeData getLightTheme(
    String fontFamily, {
    String preset = ThemePresets.defaultPreset,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      fontFamily: fontFamily,
      presetId: preset,
    );
  }

  static ThemeData getDarkTheme(
    String fontFamily, {
    String preset = ThemePresets.defaultPreset,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      presetId: preset,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required String fontFamily,
    required String presetId,
  }) {
    final preset = AppThemePresetX.fromId(presetId);
    final palette = _paletteFor(preset);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    ).copyWith(secondary: palette.secondary, tertiary: palette.tertiary);

    final background =
        brightness == Brightness.light
            ? palette.backgroundLight
            : palette.backgroundDark;
    final surface =
        brightness == Brightness.light
            ? palette.surfaceLight
            : palette.surfaceDark;

    final colorScheme = baseScheme.copyWith(surface: surface);

    final baseTextTheme = getTextTheme(fontFamily);
    final textTheme = _tuneTextTheme(
      baseTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );

    final radius = BorderRadius.circular(AppBorderRadius.card);

    final isGlass = preset == AppThemePreset.glass;
    final isNeomorphic = preset == AppThemePreset.neomorphic;

    final cardColor =
        isGlass
            ? Color.alphaBlend(
              (brightness == Brightness.light ? Colors.white : Colors.black)
                  .withValues(alpha: 0.16),
              colorScheme.surface,
            )
            : colorScheme.surface;

    final cardTheme = CardTheme(
      elevation: isNeomorphic ? 0 : 2,
      shadowColor:
          brightness == Brightness.light
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.2),
      color: cardColor.withValues(alpha: 0.94), // Slightly translucent to see texture
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: brightness == Brightness.light 
              ? Colors.black.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.03),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );

    final inputFillColor =
        isGlass
            ? Color.alphaBlend(
              (brightness == Brightness.light ? Colors.white : Colors.black)
                  .withValues(alpha: 0.14),
              colorScheme.surface,
            )
            : cardColor;

    final outline =
        brightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      extensions: <ThemeExtension<dynamic>>[AppThemeStyle(preset: preset)],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: cardTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.md,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.fab),
        ),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.sm,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.snackbar),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogTheme(
        elevation: AppElevation.xl,
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.dialog),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static TextTheme _tuneTextTheme(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.55),
    );
  }

  static _ThemePalette _paletteFor(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.love:
        return const _ThemePalette(
          seed: Color(0xFFFD79A8),
          secondary: Color(0xFFFF7675),
          tertiary: Color(0xFFFDCB6E),
          backgroundLight: Color(0xFFFFF5F8),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF1C0F16),
          surfaceDark: Color(0xFF24111B),
        );
      case AppThemePreset.futuristic:
        return const _ThemePalette(
          seed: Color(0xFF00E5FF),
          secondary: Color(0xFFB388FF),
          tertiary: Color(0xFF00FF9D),
          backgroundLight: Color(0xFFF2FBFF),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF060B14),
          surfaceDark: Color(0xFF0B1220),
        );
      case AppThemePreset.glass:
        return const _ThemePalette(
          seed: Color(0xFF74B9FF),
          secondary: Color(0xFF00CEC9),
          tertiary: Color(0xFF6C5CE7),
          backgroundLight: Color(0xFFF4F9FF),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF09111F),
          surfaceDark: Color(0xFF0C172A),
        );
      case AppThemePreset.neomorphic:
        return const _ThemePalette(
          seed: Color(0xFFB2BEC3),
          secondary: Color(0xFF6C5CE7),
          tertiary: Color(0xFF00CEC9),
          backgroundLight: Color(0xFFE6EAEE),
          surfaceLight: Color(0xFFF2F4F6),
          backgroundDark: Color(0xFF121417),
          surfaceDark: Color(0xFF171A1F),
        );
      case AppThemePreset.sunset:
        return const _ThemePalette(
          seed: Color(0xFFFF7E67),
          secondary: Color(0xFFFFC857),
          tertiary: Color(0xFF8B5CF6),
          backgroundLight: Color(0xFFFFF6F1),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF20110A),
          surfaceDark: Color(0xFF2A160D),
        );
      case AppThemePreset.ocean:
        return const _ThemePalette(
          seed: Color(0xFF1E88E5),
          secondary: Color(0xFF26C6DA),
          tertiary: Color(0xFF80CBC4),
          backgroundLight: Color(0xFFF0F7FF),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF08131F),
          surfaceDark: Color(0xFF0C1B2A),
        );
      case AppThemePreset.forest:
        return const _ThemePalette(
          seed: Color(0xFF2E7D32),
          secondary: Color(0xFF81C784),
          tertiary: Color(0xFFB2FF59),
          backgroundLight: Color(0xFFF3FAF4),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF0E1A12),
          surfaceDark: Color(0xFF15251A),
        );
      case AppThemePreset.spring:
        return const _ThemePalette(
          seed: Color(0xFF8EE4AF),
          secondary: Color(0xFFFF8AD4),
          tertiary: Color(0xFFB5F2B8),
          backgroundLight: Color(0xFFF7FFF6),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF102017),
          surfaceDark: Color(0xFF182A1D),
        );
      case AppThemePreset.autumn:
        return const _ThemePalette(
          seed: Color(0xFFC75D2C),
          secondary: Color(0xFFFFB347),
          tertiary: Color(0xFFE07A5F),
          backgroundLight: Color(0xFFFFF8F0),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF20140C),
          surfaceDark: Color(0xFF2B1B11),
        );
      case AppThemePreset.defaultPreset:
        return const _ThemePalette(
          seed: Color(0xFF6C5CE7),
          secondary: Color(0xFF00CEC9),
          tertiary: Color(0xFFFD79A8),
          backgroundLight: Color(0xFFF8F9FA),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF1A1A2E),
          surfaceDark: Color(0xFF16213E),
        );
    }
  }
}

class _ThemePalette {
  const _ThemePalette({
    required this.seed,
    required this.secondary,
    required this.tertiary,
    required this.backgroundLight,
    required this.surfaceLight,
    required this.backgroundDark,
    required this.surfaceDark,
  });

  final Color seed;
  final Color secondary;
  final Color tertiary;
  final Color backgroundLight;
  final Color surfaceLight;
  final Color backgroundDark;
  final Color surfaceDark;
}

@immutable
class AppThemeStyle extends ThemeExtension<AppThemeStyle> {
  const AppThemeStyle({required this.preset});

  final AppThemePreset preset;

  bool get isGlass => preset == AppThemePreset.glass;
  bool get isNeomorphic => preset == AppThemePreset.neomorphic;

  @override
  AppThemeStyle copyWith({AppThemePreset? preset}) {
    return AppThemeStyle(preset: preset ?? this.preset);
  }

  @override
  ThemeExtension<AppThemeStyle> lerp(
    covariant ThemeExtension<AppThemeStyle>? other,
    double t,
  ) {
    if (other is! AppThemeStyle) return this;
    return t < 0.5 ? this : other;
  }
}
