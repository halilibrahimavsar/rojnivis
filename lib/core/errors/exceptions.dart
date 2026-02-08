/// Base exception class for all application-specific exceptions.
///
/// All custom exceptions should extend this class to ensure consistent
/// error handling throughout the application.
abstract class AppException implements Exception {
  /// Creates an application exception.
  const AppException({required this.message, this.code, this.originalError});

  /// Human-readable error message.
  final String message;

  /// Optional error code for categorization.
  final String? code;

  /// Original error that caused this exception, if any.
  final Object? originalError;

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when data cannot be found.
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

/// Exception thrown when validation fails.
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    this.field,
  });

  /// The field that failed validation, if applicable.
  final String? field;
}

/// Exception thrown when storage operations fail.
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
  });
}

/// Exception thrown when network operations fail.
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
    this.isRetryable = false,
  });

  /// Whether the operation can be retried.
  final bool isRetryable;
}

/// Exception thrown when authentication fails or user is unauthorized.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.code = 'UNAUTHORIZED',
    super.originalError,
  });
}

/// Exception thrown when a conflict occurs (e.g., duplicate entry).
class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.originalError,
  });
}

/// Exception thrown when an unknown error occurs.
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
  });
}
