import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension methods for [DateTime].
extension DateTimeExtension on DateTime {
  /// Formats the date in a human-readable format using the given locale.
  ///
  /// Example: 'January 1, 2024' or '1 Ocak 2024' for Turkish locale.
  String formatDate(String locale) {
    return DateFormat.yMMMMd(locale).format(this);
  }

  /// Formats the date and time in a human-readable format using the given locale.
  ///
  /// Example: 'January 1, 2024 14:30' or '1 Ocak 2024 14:30' for Turkish locale.
  String formatDateTime(String locale) {
    return DateFormat.yMMMMd(locale).add_Hm().format(this);
  }

  /// Formats only the time.
  ///
  /// Example: '14:30'.
  String formatTime() {
    return DateFormat.Hm().format(this);
  }

  /// Formats as relative time (e.g., "Today", "Yesterday", "2 days ago").
  String formatRelative(String locale) {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes < 1) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return formatDate(locale);
    }
  }

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns a new DateTime with only the date part (time set to 00:00:00).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns the start of the day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0);

  /// Returns the end of the day (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

/// Extension methods for [String].
extension StringExtension on String {
  /// Truncates the string to the given length with an optional suffix.
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Returns true if the string is null or empty.
  bool get isNullOrEmpty => isEmpty;

  /// Returns true if the string is not null and not empty.
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Capitalizes the first letter of the string.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts the string to title case.
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Removes all extra whitespace from the string.
  String trimExtraWhitespace() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Returns true if the string is a valid email.
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Returns true if the string contains only digits.
  bool get isNumeric => double.tryParse(this) != null;
}

/// Extension methods for [BuildContext].
extension BuildContextExtension on BuildContext {
  /// Returns the current theme.
  ThemeData get theme => Theme.of(this);

  /// Returns the current color scheme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the current text theme.
  TextTheme get textTheme => theme.textTheme;

  /// Returns the current media query.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the screen size.
  Size get screenSize => mediaQuery.size;

  /// Returns true if the screen is in portrait orientation.
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Returns true if the screen is in landscape orientation.
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Returns true if the device is a tablet (based on screen width).
  bool get isTablet => screenSize.shortestSide >= 600;

  /// Returns true if the device is a phone.
  bool get isPhone => !isTablet;

  /// Returns the current view insets (keyboard height, etc.).
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Returns the current padding (status bar, notch, etc.).
  EdgeInsets get padding => mediaQuery.padding;

  /// Shows a snackbar with the given message.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Hides the current snackbar.
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  /// Shows a success snackbar.
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(this);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
    );
  }

  /// Shows an error snackbar.
  void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.errorContainer,
      ),
    );
  }

  /// Unfocuses the current focus node (hides keyboard).
  void unfocus() {
    FocusScope.of(this).unfocus();
  }
}

/// Extension methods for [List].
extension ListExtension<T> on List<T> {
  /// Returns the list separated by the given separator.
  ///
  /// Example: `[1, 2, 3].separatedBy(0)` returns `[1, 0, 2, 0, 3]`.
  List<T> separatedBy(T separator) {
    if (length <= 1) return this;
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  /// Returns true if the list has elements.
  bool get hasElements => isNotEmpty;

  /// Returns true if the list is null or empty.
  bool get isNullOrEmpty => isEmpty;

  /// Returns the first element or null if the list is empty.
  T? get firstOrNull => isEmpty ? null : first;

  /// Returns the last element or null if the list is empty.
  T? get lastOrNull => isEmpty ? null : last;
}

/// Extension methods for [Widget].
extension WidgetExtension on Widget {
  /// Wraps the widget in a SliverToBoxAdapter.
  Widget get sliver => SliverToBoxAdapter(child: this);

  /// Wraps the widget in a SliverPadding with the given padding.
  Widget sliverPadding(EdgeInsetsGeometry padding) =>
      SliverPadding(padding: padding, sliver: sliver);

  /// Adds padding to the widget.
  Widget padding(EdgeInsetsGeometry padding) =>
      Padding(padding: padding, child: this);

  /// Adds symmetric padding to the widget.
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  /// Adds all-side padding to the widget.
  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  /// Centers the widget.
  Widget get centered => Center(child: this);

  /// Makes the widget expand to fill available space.
  Widget get expanded => Expanded(child: this);

  /// Makes the widget flexible with the given flex factor.
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  /// Adds a tap handler to the widget.
  Widget onTap(VoidCallback? onTap) =>
      GestureDetector(onTap: onTap, child: this);

  /// Adds a tap handler with ripple effect to the widget.
  Widget onTapRipple(VoidCallback? onTap, {BorderRadius? borderRadius}) =>
      InkWell(onTap: onTap, borderRadius: borderRadius, child: this);
}
