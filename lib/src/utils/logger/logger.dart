import 'io.dart' if (dart.library.html) 'web.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static bool debugEnabled = false;
  static LogLevel minLevel = LogLevel.debug;

  static final Map<LogLevel, String> _levelLabels = {
    LogLevel.debug: 'DEBUG',
    LogLevel.info: 'INFO',
    LogLevel.warning: 'WARN',
    LogLevel.error: 'ERROR',
  };

  static final Map<LogLevel, String> _levelColors = {
    LogLevel.debug: '\x1B[36m', // Cyan
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
  };

  static final String _resetColor = '\x1B[0m';

  static void log(String message,
      {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    if (!_shouldLog(level)) return;
    final now = DateTime.now();
    final timestamp = now
        .toIso8601String()
        .replaceFirst('T', ' ')
        .substring(0, 23); // yyyy-MM-dd HH:mm:ss.SSS
    final label = _levelLabels[level] ?? 'LOG';
    final color = _levelColors[level] ?? '';
    final output = StringBuffer();
    output.write('$color[$timestamp][$label] $message$_resetColor');
    if (error != null) {
      output.write(' | Error: $error');
    }
    if (stackTrace != null) {
      output.write('\n$stackTrace');
    }
    dPrint(output.toString());
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warn(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);

  static bool _shouldLog(LogLevel level) {
    if (!debugEnabled) return false;
    return level.index >= minLevel.index;
  }

  static void setDebug(bool enabled) {
    debugEnabled = enabled;
  }

  static void setMinLevel(LogLevel level) {
    minLevel = level;
  }
}
