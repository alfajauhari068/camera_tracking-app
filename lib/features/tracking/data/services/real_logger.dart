import 'dart:developer' as developer;

import '../../domain/services/logger.dart';

/// Real logger using dart:developer (works in production)
class RealLogger implements Logger {
  final String tag;

  const RealLogger([this.tag = 'TrackingApp']);

  @override
  void log(String message) {
    developer.log('[$tag] $message', level: 0);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '[$tag] ERROR: $message',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void warning(String message) {
    developer.log('[$tag] WARNING: $message', level: 900);
  }
}