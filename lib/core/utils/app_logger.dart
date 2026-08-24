import 'dart:developer' as developer;

/// Thin wrapper around `dart:developer`'s `log()` so every service call
/// and exception across the app logs consistently — visible directly in
/// the `flutter run` console (and DevTools' Logging view), filterable by
/// [tag].
///
/// Log lines carry a marker tag so specific kinds of activity — an AI
/// prompt going out, the raw response coming back, a Firebase read/write —
/// are easy to spot (or grep for) in a console full of general info logs:
/// [PROMPT] / [RESPONSE] / [FIREBASE] / [ERROR].
class AppLogger {
  static void info(String tag, String message) {
    developer.log(message, name: tag);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '[ERROR] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000, // SEVERE — makes real errors stand out from info logs
    );
  }

  /// The exact prompt/payload sent to a cloud or on-device AI model.
  static void prompt(String tag, String message) {
    developer.log('[PROMPT] $message', name: tag);
  }

  /// The raw, unparsed response text/body received back from an AI model.
  static void response(String tag, String message) {
    developer.log('[RESPONSE] $message', name: tag);
  }

  /// A Firebase (Auth/Firestore) read, write, or sign-in call.
  static void firebase(String tag, String message) {
    developer.log('[FIREBASE] $message', name: tag);
  }
}
