/// A type-safe wrapper for operations that can succeed or fail.
///
/// Use instead of throwing exceptions for expected failure cases.
/// Provides exhaustive pattern matching via Dart's sealed class system.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the value if [Success], otherwise returns [fallback].
  T getOrElse(T fallback) => switch (this) {
        Success(:final value) => value,
        Failure() => fallback,
      };

  /// Returns the value if [Success], otherwise calls [orElse].
  T getOrElseMap(T Function(Object error) orElse) => switch (this) {
        Success(:final value) => value,
        Failure(:final error) => orElse(error),
      };

  /// Transforms the success value, passing failures through unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
      };

  /// Transforms the success value with a function that itself returns Result.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success(:final value) => transform(value),
        Failure(:final error, :final stackTrace) => Failure(error, stackTrace),
      };
}

/// The operation succeeded with [value].
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

/// The operation failed with [error].
class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;
  const Failure(this.error, [this.stackTrace]);

  @override
  String toString() => 'Failure($error)';
}
