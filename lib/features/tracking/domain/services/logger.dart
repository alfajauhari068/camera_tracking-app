/// Logger abstraction for production tracing
/// Prevents scattered print statements and enables proper logging in production
abstract class Logger {
  /// Log general information
  void log(String message);

  /// Log error with context
  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// Log warning
  void warning(String message);
}