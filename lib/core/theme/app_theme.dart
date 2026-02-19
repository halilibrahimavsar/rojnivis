import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import 'page_studio_models.dart';

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
  nightmare,
  nightblue,
  sunrise,
  nature,
  darkNature,
  aurora,
  storm,
  nebula,
  raining,
  snowing,
  sunny,
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
      case AppThemePreset.nightmare:
        return ThemePresets.nightmare;
      case AppThemePreset.nightblue:
        return ThemePresets.nightblue;
      case AppThemePreset.sunrise:
        return ThemePresets.sunrise;
      case AppThemePreset.nature:
        return ThemePresets.nature;
      case AppThemePreset.darkNature:
        return ThemePresets.darkNature;
      case AppThemePreset.aurora:
        return ThemePresets.aurora;
      case AppThemePreset.storm:
        return ThemePresets.storm;
      case AppThemePreset.nebula:
        return ThemePresets.nebula;
      case AppThemePreset.raining:
        return ThemePresets.raining;
      case AppThemePreset.snowing:
        return ThemePresets.snowing;
      case AppThemePreset.sunny:
        return ThemePresets.sunny;
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
      case ThemePresets.nightmare:
        return AppThemePreset.nightmare;
      case ThemePresets.nightblue:
        return AppThemePreset.nightblue;
      case ThemePresets.sunrise:
        return AppThemePreset.sunrise;
      case ThemePresets.nature:
        return AppThemePreset.nature;
      case ThemePresets.darkNature:
        return AppThemePreset.darkNature;
      case ThemePresets.aurora:
        return AppThemePreset.aurora;
      case ThemePresets.storm:
        return AppThemePreset.storm;
      case ThemePresets.nebula:
        return AppThemePreset.nebula;
      case ThemePresets.raining:
        return AppThemePreset.raining;
      case ThemePresets.snowing:
        return AppThemePreset.snowing;
      case ThemePresets.sunny:
        return AppThemePreset.sunny;
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
    ThemePresetOption(
      preset: AppThemePreset.nightmare,
      labelKey: 'theme_nightmare',
      previewColor: _paletteFor(AppThemePreset.nightmare).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.nightblue,
      labelKey: 'theme_nightblue',
      previewColor: _paletteFor(AppThemePreset.nightblue).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.sunrise,
      labelKey: 'theme_sunrise',
      previewColor: _paletteFor(AppThemePreset.sunrise).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.nature,
      labelKey: 'theme_nature',
      previewColor: _paletteFor(AppThemePreset.nature).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.darkNature,
      labelKey: 'theme_dark_nature',
      previewColor: _paletteFor(AppThemePreset.darkNature).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.aurora,
      labelKey: 'theme_aurora',
      previewColor: _paletteFor(AppThemePreset.aurora).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.storm,
      labelKey: 'theme_storm',
      previewColor: _paletteFor(AppThemePreset.storm).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.nebula,
      labelKey: 'theme_nebula',
      previewColor: _paletteFor(AppThemePreset.nebula).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.raining,
      labelKey: 'theme_raining',
      previewColor: _paletteFor(AppThemePreset.raining).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.snowing,
      labelKey: 'theme_snowing',
      previewColor: _paletteFor(AppThemePreset.snowing).seed,
    ),
    ThemePresetOption(
      preset: AppThemePreset.sunny,
      labelKey: 'theme_sunny',
      previewColor: _paletteFor(AppThemePreset.sunny).seed,
    ),
  ]);

  static TextTheme getTextTheme(String fontFamily) {
    return _textThemes[fontFamily] ?? GoogleFonts.poppinsTextTheme();
  }

  static ThemeData getLightTheme(
    String fontFamily, {
    String preset = ThemePresets.defaultPreset,
    PageVisualFamily pageVisualFamily = PageVisualFamily.classic,
    VintagePaperVariant vintagePaperVariant = VintagePaperVariant.parchment,
    AnimationIntensity animationIntensity = AnimationIntensity.subtle,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      fontFamily: fontFamily,
      presetId: preset,
      pageVisualFamily: pageVisualFamily,
      vintagePaperVariant: vintagePaperVariant,
      animationIntensity: animationIntensity,
    );
  }

  static ThemeData getDarkTheme(
    String fontFamily, {
    String preset = ThemePresets.defaultPreset,
    PageVisualFamily pageVisualFamily = PageVisualFamily.classic,
    VintagePaperVariant vintagePaperVariant = VintagePaperVariant.parchment,
    AnimationIntensity animationIntensity = AnimationIntensity.subtle,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      presetId: preset,
      pageVisualFamily: pageVisualFamily,
      vintagePaperVariant: vintagePaperVariant,
      animationIntensity: animationIntensity,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required String fontFamily,
    required String presetId,
    required PageVisualFamily pageVisualFamily,
    required VintagePaperVariant vintagePaperVariant,
    required AnimationIntensity animationIntensity,
  }) {
    final preset = AppThemePresetX.fromId(presetId);
    final palette = _paletteFor(preset);
    final realismTint = _realismTintFor(preset, brightness);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    ).copyWith(secondary: palette.secondary, tertiary: palette.tertiary);

    var background =
        brightness == Brightness.light
            ? palette.backgroundLight
            : palette.backgroundDark;
    var surface =
        brightness == Brightness.light
            ? palette.surfaceLight
            : palette.surfaceDark;

    background = Color.alphaBlend(
      realismTint.withValues(
        alpha: brightness == Brightness.light ? 0.08 : 0.12,
      ),
      background,
    );
    surface = Color.alphaBlend(
      realismTint.withValues(
        alpha: brightness == Brightness.light ? 0.05 : 0.09,
      ),
      surface,
    );

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
            : Color.alphaBlend(
              realismTint.withValues(
                alpha: brightness == Brightness.light ? 0.06 : 0.08,
              ),
              colorScheme.surface,
            );

    final cardTheme = CardTheme(
      elevation: isNeomorphic ? 0 : 2,
      shadowColor:
          brightness == Brightness.light
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.2),
      color: cardColor.withValues(
        alpha: 0.94,
      ), // Slightly translucent to see texture
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color:
              brightness == Brightness.light
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
      extensions: <ThemeExtension<dynamic>>[
        AppThemeStyle(
          preset: preset,
          pageVisualFamily: pageVisualFamily,
          vintagePaperVariant: vintagePaperVariant,
          animationIntensity: animationIntensity,
        ),
      ],
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
      case AppThemePreset.nightmare:
        return const _ThemePalette(
          seed: Color(0xFF8B0000), // Dark Red
          secondary: Color(0xFF4B0082), // Indigo
          tertiary: Color(0xFFFF4500), // Orange Red
          backgroundLight: Color(0xFFF0F0F0), // Light Grey (Unlikely used)
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF0F0505), // Very Dark Red/Black
          surfaceDark: Color(0xFF1A0A0A),
        );
      case AppThemePreset.nightblue:
        return const _ThemePalette(
          seed: Color(0xFF191970), // Midnight Blue
          secondary: Color(0xFF4169E1), // Royal Blue
          tertiary: Color(0xFFE6E6FA), // Lavender
          backgroundLight: Color(0xFFF0F8FF),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF02040A), // Almost Black Blue
          surfaceDark: Color(0xFF0A1020),
        );
      case AppThemePreset.sunrise:
        return const _ThemePalette(
          seed: Color(0xFFFF9A8B), // Soft Pink/Orange
          secondary: Color(0xFFFFD700), // Gold
          tertiary: Color(0xFFFF6B6B), // Coral
          backgroundLight: Color(0xFFFFF9F5),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF2D1B1E), // Dark Warm Brown
          surfaceDark: Color(0xFF3B2529),
        );
      case AppThemePreset.nature:
        return const _ThemePalette(
          seed: Color(0xFF558B2F), // Light Olive Green
          secondary: Color(0xFF8BC34A), // Light Green
          tertiary: Color(0xFFFFEB3B), // Yellow
          backgroundLight: Color(0xFFF9FFF6),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF1B261D),
          surfaceDark: Color(0xFF243026),
        );
      case AppThemePreset.darkNature:
        return const _ThemePalette(
          seed: Color(0xFF004D40), // Teal Green
          secondary: Color(0xFF00695C),
          tertiary: Color(0xFF1DE9B6), // Accent Teal
          backgroundLight: Color(0xFFE0F2F1),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF001512), // Very Dark Teal
          surfaceDark: Color(0xFF00221E),
        );
      case AppThemePreset.aurora:
        return const _ThemePalette(
          seed: Color(0xFF00E676), // Bright Green
          secondary: Color(0xFF651FFF), // Deep Purple
          tertiary: Color(0xFF00B0FF), // Light Blue
          backgroundLight: Color(0xFFF0FDF4),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF061A14), // Dark Green/Black
          surfaceDark: Color(0xFF0A201A),
        );
      case AppThemePreset.storm:
        return const _ThemePalette(
          seed: Color(0xFF455A64), // Blue Grey
          secondary: Color(0xFFCFD8DC), // Light Grey
          tertiary: Color(0xFFFFD600), // Lightning Yellow
          backgroundLight: Color(0xFFF5F5F5),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF101416), // Dark Grey
          surfaceDark: Color(0xFF1C2226),
        );
      case AppThemePreset.nebula:
        return const _ThemePalette(
          seed: Color(0xFF9C27B0), // Purple
          secondary: Color(0xFFFF4081), // Pink
          tertiary: Color(0xFF7C4DFF), // Deep Purple
          backgroundLight: Color(0xFFFDF0F6),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF120316), // Dark Purple/Black
          surfaceDark: Color(0xFF200A26),
        );
      case AppThemePreset.raining:
        return const _ThemePalette(
          seed: Color(0xFF546E7A), // Blue Grey
          secondary: Color(0xFF78909C),
          tertiary: Color(0xFFB0BEC5),
          backgroundLight: Color(0xFFECEFF1),
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF263238), // Dark Blue Grey
          surfaceDark: Color(0xFF37474F),
        );
      case AppThemePreset.snowing:
        return const _ThemePalette(
          seed: Color(0xFFB3E5FC), // Light Blue
          secondary: Color(0xFF81D4FA),
          tertiary: Color(0xFFE1F5FE),
          backgroundLight: Color(0xFFF9FDFF), // Almost white blue
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF1E2F38), // Dark Winter Blue
          surfaceDark: Color(0xFF263D47),
        );
      case AppThemePreset.sunny:
        return const _ThemePalette(
          seed: Color(0xFFFFC107), // Amber
          secondary: Color(0xFFFF9800), // Orange
          tertiary: Color(0xFF29B6F6), // Sky Blue
          backgroundLight: Color(0xFFFFFDE7), // Light Yellow
          surfaceLight: Color(0xFFFFFFFF),
          backgroundDark: Color(0xFF3E2723), // Warm Dark Brown
          surfaceDark: Color(0xFF4E342E),
        );
    }
  }

  static Color _realismTintFor(AppThemePreset preset, Brightness brightness) {
    if (brightness == Brightness.dark) {
      switch (preset) {
        case AppThemePreset.love:
          return const Color(0xFF2A171A);
        case AppThemePreset.ocean:
          return const Color(0xFF122334);
        case AppThemePreset.forest:
          return const Color(0xFF132115);
        case AppThemePreset.sunset:
          return const Color(0xFF2B1A13);
        case AppThemePreset.spring:
          return const Color(0xFF1A2319);
        case AppThemePreset.autumn:
          return const Color(0xFF2A1D13);
        case AppThemePreset.futuristic:
          return const Color(0xFF0F1A27);
        case AppThemePreset.glass:
          return const Color(0xFF142234);
        case AppThemePreset.neomorphic:
          return const Color(0xFF1A1C1F);
        case AppThemePreset.defaultPreset:
          return const Color(0xFF1B1D2C);
        case AppThemePreset.nightmare:
          return const Color(0xFF250E0E);
        case AppThemePreset.nightblue:
          return const Color(0xFF050A19);
        case AppThemePreset.sunrise:
          return const Color(0xFF331E18);
        case AppThemePreset.nature:
          return const Color(0xFF142116);
        case AppThemePreset.darkNature:
          return const Color(0xFF021412);
        case AppThemePreset.aurora:
          return const Color(0xFF0A1F18);
        case AppThemePreset.storm:
          return const Color(0xFF181C1E);
        case AppThemePreset.nebula:
          return const Color(0xFF180A20);
        case AppThemePreset.raining:
          return const Color(0xFF151B1E);
        case AppThemePreset.snowing:
          return const Color(0xFF0F171C);
        case AppThemePreset.sunny:
          return const Color(0xFF261917);
      }
    }

    switch (preset) {
      case AppThemePreset.love:
        return const Color(0xFFE9D6D8);
      case AppThemePreset.ocean:
        return const Color(0xFFD6E6F0);
      case AppThemePreset.forest:
        return const Color(0xFFDCE8D8);
      case AppThemePreset.sunset:
        return const Color(0xFFEEDCCF);
      case AppThemePreset.spring:
        return const Color(0xFFDEEBDD);
      case AppThemePreset.autumn:
        return const Color(0xFFE9DDCF);
      case AppThemePreset.futuristic:
        return const Color(0xFFD8E0EA);
      case AppThemePreset.glass:
        return const Color(0xFFDCE5F2);
      case AppThemePreset.neomorphic:
        return const Color(0xFFE3E5E8);
      case AppThemePreset.defaultPreset:
        return const Color(0xFFDFE1E8);
      case AppThemePreset.nightmare:
        return const Color(0xFF362B2B); // Darkish Red tint
      case AppThemePreset.nightblue:
        return const Color(0xFF1A233A);
      case AppThemePreset.sunrise:
        return const Color(0xFFFFE8D6);
      case AppThemePreset.nature:
        return const Color(0xFFE8F5E9);
      case AppThemePreset.darkNature:
        return const Color(0xFF00251F); // Dark Green tint
      case AppThemePreset.aurora:
        return const Color(0xFFE0F2F1);
      case AppThemePreset.storm:
        return const Color(0xFFECEFF1);
      case AppThemePreset.nebula:
        return const Color(0xFFF3E5F5);
      case AppThemePreset.raining:
        return const Color(0xFFE0E0E0);
      case AppThemePreset.snowing:
        return const Color(0xFFE1F5FE);
      case AppThemePreset.sunny:
        return const Color(0xFFFFF9C4);
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
  const AppThemeStyle({
    required this.preset,
    required this.pageVisualFamily,
    required this.vintagePaperVariant,
    required this.animationIntensity,
  });

  final AppThemePreset preset;
  final PageVisualFamily pageVisualFamily;
  final VintagePaperVariant vintagePaperVariant;
  final AnimationIntensity animationIntensity;

  bool get isGlass => preset == AppThemePreset.glass;
  bool get isNeomorphic => preset == AppThemePreset.neomorphic;
  bool get isVintage => pageVisualFamily == PageVisualFamily.vintage;

  @override
  AppThemeStyle copyWith({
    AppThemePreset? preset,
    PageVisualFamily? pageVisualFamily,
    VintagePaperVariant? vintagePaperVariant,
    AnimationIntensity? animationIntensity,
  }) {
    return AppThemeStyle(
      preset: preset ?? this.preset,
      pageVisualFamily: pageVisualFamily ?? this.pageVisualFamily,
      vintagePaperVariant: vintagePaperVariant ?? this.vintagePaperVariant,
      animationIntensity: animationIntensity ?? this.animationIntensity,
    );
  }

  @override
  ThemeExtension<AppThemeStyle> lerp(
    covariant ThemeExtension<AppThemeStyle>? other,
    double t,
  ) {
    if (other is! AppThemeStyle) return this;
    return AppThemeStyle(
      preset: t < 0.5 ? preset : other.preset,
      pageVisualFamily: t < 0.5 ? pageVisualFamily : other.pageVisualFamily,
      vintagePaperVariant:
          t < 0.5 ? vintagePaperVariant : other.vintagePaperVariant,
      animationIntensity:
          t < 0.5 ? animationIntensity : other.animationIntensity,
    );
  }
}
