import 'package:flutter/material.dart';
import 'exceptions.dart';

/// Utility class for handling errors and converting them to user-friendly messages.
///
/// This class provides consistent error handling across the application,
/// converting various error types to user-friendly messages that can be
/// displayed in the UI.
class ErrorHandler {
  const ErrorHandler._();

  /// Converts any error to a user-friendly error message.
  ///
  /// [error] can be any type of error (Exception, Error, or other).
  /// [context] is optional and used for localization if provided.
  static String getErrorMessage(Object error, {BuildContext? context}) {
    // Handle known exception types
    if (error is AppException) {
      return error.message;
    }

    // Handle specific exception types
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }

    if (error is ArgumentError) {
      return 'Invalid argument provided. Please try again.';
    }

    if (error is StateError) {
      return 'An unexpected state error occurred. Please restart the app.';
    }

    if (error is UnsupportedError) {
      return 'This operation is not supported.';
    }

    if (error is UnimplementedError) {
      return 'This feature is not yet implemented.';
    }

    // Handle Flutter-specific errors
    if (error is FlutterError) {
      return 'A UI error occurred. Please try again.';
    }

    // Handle Hive/storage errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('hive') ||
        errorString.contains('box') ||
        errorString.contains('storage')) {
      return 'A storage error occurred. Please check your device storage.';
    }

    // Default error message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Converts an error to an appropriate [AppException].
  ///
  /// This is useful for standardizing error handling in repositories
  /// and data sources.
  static AppException toAppException(Object error, {String? operation}) {
    if (error is AppException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();
    final operationPrefix = operation != null ? '$operation: ' : '';

    // Storage-related errors
    if (errorString.contains('hive') ||
        errorString.contains('box') ||
        errorString.contains('storage') ||
        errorString.contains('database')) {
      return StorageException(
        message: '${operationPrefix}Failed to access storage.',
        originalError: error,
      );
    }

    // Not found errors
    if (errorString.contains('not found') ||
        errorString.contains('doesn\'t exist') ||
        errorString.contains('does not exist')) {
      return NotFoundException(
        message: '${operationPrefix}The requested item was not found.',
        originalError: error,
      );
    }

    // Validation errors
    if (errorString.contains('invalid') ||
        errorString.contains('validation') ||
        errorString.contains('format')) {
      return ValidationException(
        message: '${operationPrefix}Invalid data provided.',
        originalError: error,
      );
    }

    // Default to unknown exception
    return UnknownException(
      message: '${operationPrefix}An unexpected error occurred.',
      originalError: error,
    );
  }

  /// Logs an error for debugging purposes.
  ///
  /// In production, this should be replaced with a proper logging service
  /// like Firebase Crashlytics, Sentry, or similar.
  static void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    // In a real app, you would send this to a logging service
    // For now, we just print to console in debug mode
    assert(() {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('ERROR${context != null ? ' [$context]' : ''}:');
      debugPrint('$error');
      if (stackTrace != null) {
        debugPrint('\nSTACK TRACE:');
        debugPrint(stackTrace.toString().split('\n').take(10).join('\n'));
      }
      debugPrint('═══════════════════════════════════════════════════════════');
      return true;
    }());
  }

  /// Shows an error snackbar with the given message.
  ///
  /// This is a convenience method for displaying errors in the UI.
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a success snackbar with the given message.
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
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
}

/// Extension methods for easier error handling.
extension ErrorHandlingExtension on Object {
  /// Converts this error to a user-friendly message.
  String toErrorMessage({BuildContext? context}) =>
      ErrorHandler.getErrorMessage(this, context: context);

  /// Converts this error to an [AppException].
  AppException toAppException({String? operation}) =>
      ErrorHandler.toAppException(this, operation: operation);
}
