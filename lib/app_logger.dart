import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🐛 DEBUG: $message');
    }
  }

  static void error(String message) {
     if (kDebugMode) {
      debugPrint('🔥 ERROR: $message');
    }
  }
}