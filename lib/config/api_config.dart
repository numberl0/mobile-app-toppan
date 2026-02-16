import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get apiBaseUrl {
    if (kReleaseMode) {
      return 'https://visitor.toppan-edge.co.th';   // Production environment URL
    } else {
      return 'http://192.168.31.193:20509';    // Test environment URL (Local or Staging URL) 
    }
  }

  static const double fontSize = 13.0;
  static const double fsPhone = 13.0;
  static const double fsIpad = 18.0;
  static const String fontFamily = 'NotoSans';

  static bool getPhoneScale(BuildContext context) {
    return MediaQuery.of(context).size.width < 799;
  }

  static double getFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 799 ? fsIpad :fsPhone;
  }
}
// class ConfigApp

// class FontHelper {
//   static double getFontSize(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return screenWidth > 799 ? ApiConfig.fsIpad : ApiConfig.fsPhone;
//   }
// }
