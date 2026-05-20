import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class Failure extends Equatable {
  /// Creates a failure with a human-readable message.
  const Failure({required this.message});

  /// The error message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Failure occurring during storage operations.
class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

/// Failure occurring during network operations.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Failure occurring when a resource is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

/// Failure occurring when validation fails.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Failure for authentication-related errors.
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Generic failure for unknown errors.
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
