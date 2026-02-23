import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toppan_app/app_logger.dart';

// Like LocalStorage
class UserEntity {

  static const _secureStorage = FlutterSecureStorage();

  //Key
  String username = 'username';
  String displayName = 'displayName';
  String roles_visitorService = 'roles_visitorService'; // list<String> = []
  String device_id = "device_id";
  String device_name = "device_name";

  // ---------- Secure Storage (Token) ----------

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: 'accessToken', value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refreshToken', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refreshToken');
  }

  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

   // ---------- Shared Preferences (General Data) ----------

  //Setter
  Future<void> setUserPerfer(String key, dynamic value) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();

      if (value == null) {
        AppLogger.debug('Value cannot be null');
        return;
      }

    bool isSaved = false;

    //value = int
    if (value is int) {
      await _prefs.setInt(key, value);
      isSaved = true;

    //value = double
    } else if (value is double) {
      await _prefs.setDouble(key, value);
      isSaved = true;

    //value = bool
    } else if (value is bool) {
      await _prefs.setBool(key, value);
      isSaved = true;

    //value = String
    } else if (value is String) {
      await _prefs.setString(key, value);
      isSaved = true;

    //value = List<String>
    } else if (value is List<String>) { 
      await _prefs.setStringList(key, value);
      isSaved = true;
      
    } else {
      AppLogger.debug('Error: Unsupported type for SharedPreferences.');
    }
    if (isSaved) {
      AppLogger.debug('Successfully saved $key: '+value.toString());
    }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
    }
  }

  //Getter
  Future<dynamic> getUserPerfer(String key) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      if (!_prefs.containsKey(key)) return null;
      return _prefs.get(key);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      return null;
    }
  }

  Future<void> removeUserPerfer(String key) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.remove(key);
      AppLogger.debug('Remove UserEntity : $key');
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      return null;
    }
  }

  Future<void> clearUserPerfer() async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.clear();
      AppLogger.debug("Clear All SharedPreferences");
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      rethrow;
    }
  }

  Future<void> printAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = await prefs.getKeys();

    AppLogger.debug('SharedPreferences contents:');
    for (String key in keys) {
      AppLogger.debug('$key: ${prefs.get(key)}');
    }
  }


  Future<bool> isKeysEmpty() async {
    bool status = false;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Set<String> keys = prefs.getKeys();

      // Exclude keys related to Device Preview settings
      Set<String> excludedKeys = {'device_preview.settings'};

      // Filter out the device_preview related keys
      keys.removeWhere((key) => excludedKeys.contains(key));
      await printAllSharedPreferences();
      if (keys.isEmpty) {
        status = true;
      } else {
        status = false;
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      rethrow;
    }
    return status;
  }

  // ---------- Clear All Storage ----------

  Future<void> ClearStorage() async {
    await deleteTokens();
    await clearUserPerfer();
  }

}