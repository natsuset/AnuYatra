/// Base exception for all application-level errors.
///
/// Provides a consistent contract for error handling across the app.
/// All domain exceptions extend this class.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => 'AppException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when a requested entity does not exist.
class NotFoundException extends AppException {
  final String entityType;
  final String id;

  const NotFoundException({
    required this.entityType,
    required this.id,
  }) : super('$entityType not found: $id');
}

/// Thrown when input fails validation rules.
class ValidationException extends AppException {
  final String field;

  const ValidationException({
    required this.field,
    required String message,
  }) : super(message);
}

/// Thrown when a storage operation (read/write) fails.
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

/// Thrown when authentication or authorization fails.
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

/// Thrown when a duplicate entity is detected.
class DuplicateException extends AppException {
  final String entityType;

  const DuplicateException({
    required this.entityType,
    required String message,
  }) : super(message);
}
