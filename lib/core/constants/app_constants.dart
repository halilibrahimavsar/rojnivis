/// Core application constants used throughout the app.
///
/// This file centralizes all magic numbers, strings, and other constants
/// to ensure consistency and make maintenance easier.
library;

/// Animation and timing constants
class AppDurations {
  const AppDurations._();

  /// Standard animation duration
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  /// Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration snackbarDisplay = Duration(seconds: 3);

  /// Splash and loading
  static const Duration splashDisplay = Duration(seconds: 2);
  static const Duration loadingTimeout = Duration(seconds: 30);
}

/// Layout and spacing constants
class AppSpacing {
  const AppSpacing._();

  /// Base spacing unit (4.0)
  static const double unit = 4.0;

  /// Common spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Screen padding
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
}

/// Border radius constants
class AppBorderRadius {
  const AppBorderRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  /// Card border radius
  static const double card = 20.0;
  static const double input = 16.0;
  static const double button = 16.0;
  static const double fab = 16.0;
  static const double dialog = 24.0;
  static const double chip = 12.0;
  static const double snackbar = 16.0;
}

/// Elevation constants
class AppElevation {
  const AppElevation._();

  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

/// Opacity and alpha constants
class AppAlpha {
  const AppAlpha._();

  static const double fullyTransparent = 0.0;
  static const double veryLight = 0.08;
  static const double light = 0.10;
  static const double medium = 0.12;
  static const double high = 0.14;
  static const double veryHigh = 0.16;
  static const double semiTransparent = 0.5;
  static const double fullyOpaque = 1.0;
}

/// Max line and length constants
class AppLimits {
  const AppLimits._();

  /// Text limits
  static const int maxTitleLength = 100;
  static const int maxContentLength = 10000;
  static const int maxTagLength = 30;
  static const int maxTagsCount = 10;
  static const int maxCategoryNameLength = 50;

  /// Display limits
  static const int maxTitleLines = 2;
  static const int maxContentLines = 3;
  static const int maxSearchHistory = 10;

  /// File limits
  static const int maxAttachmentSizeMB = 50;
  static const int maxAttachmentsCount = 10;
  static const int maxAudioDurationMinutes = 30;
}

/// Default values
class AppDefaults {
  const AppDefaults._();

  /// Font
  static const String defaultFontFamily = 'Poppins';
  static const String defaultThemePreset = ThemePresets.defaultPreset;
  static const String defaultLocale = 'tr';
  static const String defaultCountryCode = 'TR';
  static const bool defaultAttachmentBackdrop = true;
  static const int defaultNotebookCoverColor = 0xFF2C3E50;
  static const String defaultNotebookCoverTexture = 'leather';

  /// Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'id': 'general', 'name': 'Genel', 'color': 0xFF6C5CE7, 'iconPath': ''},
    {'id': 'love', 'name': 'Aşk', 'color': 0xFFFD79A8, 'iconPath': ''},
    {'id': 'ideas', 'name': 'Fikirler', 'color': 0xFF00CEC9, 'iconPath': ''},
    {'id': 'work', 'name': 'İş', 'color': 0xFF0984E3, 'iconPath': ''},
    {'id': 'travel', 'name': 'Seyahat', 'color': 0xFFFDCB6E, 'iconPath': ''},
  ];
}

/// Storage keys
class StorageKeys {
  const StorageKeys._();

  /// Hive box names
  static const String journalEntriesBox = 'journal_entries';
  static const String categoriesBox = 'categories';

  /// SharedPreferences keys
  static const String themeMode = 'theme_mode';
  static const String themePreset = 'theme_preset';
  static const String fontFamily = 'font_family';
  static const String locale = 'locale';
  static const String attachmentBackdrop = 'attachment_backdrop';
  static const String notebookCoverColor = 'notebook_cover_color';
  static const String notebookCoverTexture = 'notebook_cover_texture';
}

/// Route paths
class RoutePaths {
  const RoutePaths._();

  static const String home = '/';
  static const String addEntry = 'add-entry';
  static const String entryDetail = 'entry/:entryId';
  static const String categories = 'categories';
  static const String settings = 'settings';

  /// Query parameters
  static const String entryIdParam = 'entryId';
}

/// Theme preset IDs
class ThemePresets {
  const ThemePresets._();

  static const String defaultPreset = 'default';
  static const String love = 'love';
  static const String futuristic = 'futuristic';
  static const String glass = 'glass';
  static const String neomorphic = 'neomorphic';
  static const String sunset = 'sunset';
  static const String ocean = 'ocean';
  static const String forest = 'forest';
  static const String spring = 'spring';
  static const String autumn = 'autumn';
}

/// Hive type IDs for adapters
class HiveTypeIds {
  const HiveTypeIds._();

  static const int journalEntry = 1;
  static const int category = 2;
}
