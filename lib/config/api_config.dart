import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get apiBaseUrl {
    if (kReleaseMode) {
      // Production environment URL
      return 'https://visitor.toppan-edge.co.th';
    } else {
      // Test environment URL (Local or Staging URL)
      return 'http://192.168.31.228:5000';
    }
  }

  static const String authPipe  = 'auth';
  static const String visitorPipe = 'visitor';
  static const double fontSize = 16.0;
}