import 'failures.dart';

/// Result wrapper untuk controlled error flow (bukan exception-based)
/// Ini is foundation untuk state management di STEP 2
sealed class Result<T> {
  const Result();

  /// Success result dengan data
  factory Result.success(T data) => Success(data);

  /// Failure result dengan error
  factory Result.failure(Failure error) => FailureResult<T>(error);

  /// Pattern matching untuk handle kedua case
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is FailureResult<T>) {
      return failure((this as FailureResult<T>).error);
    }
    throw StateError('Unknown Result type');
  }

  /// Get data atau null jika failure
  T? getOrNull() {
    return when(
      success: (data) => data,
      failure: (_) => null,
    );
  }

  /// Get error atau null jika success
  Failure? getErrorOrNull() {
    return when(
      success: (_) => null,
      failure: (error) => error,
    );
  }

  /// Check if success
  bool get isSuccess => this is Success<T>;

  /// Check if failure
  bool get isFailure => this is FailureResult<T>;
}

/// Success result implementation
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

/// Failure result implementation
final class FailureResult<T> extends Result<T> {
  final Failure error;

  const FailureResult(this.error);
}
