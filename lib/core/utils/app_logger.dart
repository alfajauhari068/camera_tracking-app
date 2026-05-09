import 'package:flutter/foundation.dart';

/// Logging utility for the app.
///
/// For now it uses [debugPrint] underneath so it can be easily swapped
/// later to a dedicated logger package.
class AppLogger {
  const AppLogger({String? tag}) : _tag = tag;

  final String? _tag;

  void info(Object? message) {
    _log('INFO', message);
  }

  void warning(Object? message) {
    _log('WARN', message);
  }

  void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    final merged = error != null ? '$message | error=$error' : message;
    _log('ERROR', merged);
    if (stackTrace != null) {
      // debugPrint has limited width, so printing stacktrace separately.
      debugPrint(stackTrace.toString());
    }
  }

  void _log(String level, Object? message) {
    final prefix = _tag == null ? '' : '[$_tag] ';
    debugPrint('$prefix$level: ${message ?? ''}');
  }
}

