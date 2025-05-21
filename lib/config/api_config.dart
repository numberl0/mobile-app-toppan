import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get apiBaseUrl {
    if (kReleaseMode) {
      return 'https://visitor.toppan-edge.co.th';   // Production environment URL
    } else {
      return 'http://192.168.31.193:5000';    // Test environment URL (Local or Staging URL) 
    }
  }

  static const String authPipe  = 'auth';
  static const String visitorPipe = 'visitor';
  static const double fontSize = 16.0;    // standard gobal font size
}