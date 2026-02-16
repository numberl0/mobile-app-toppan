import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppDateTime {
  static bool _initialized = false;
  static late tz.Location _location;
  
  static void initialize({String timeZone = 'Asia/Bangkok'}) {
    if (_initialized) return;
    tz.initializeTimeZones();
    _location = tz.getLocation(timeZone);
    _initialized = true;
  }

  static DateTime now() {
    if (!_initialized) {
      throw Exception('AppDateTime ยังไม่ถูก initialize! เรียก AppDateTime.initialize() ก่อนใช้.');
    }
    return tz.TZDateTime.now(_location);
  }

  static DateTime from(DateTime dt) {
    if (!_initialized) {
      throw Exception('AppDateTime ยังไม่ถูก initialize! เรียก AppDateTime.initialize() ก่อนใช้.');
    }
    return tz.TZDateTime.from(dt, _location);
  }
}
