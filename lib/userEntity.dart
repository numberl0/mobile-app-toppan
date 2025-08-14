import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Like LocalStorage
class UserEntity {

  //Key
  String app_version = 'app_version';

  String username = 'username';
  String displayName = 'displayName';
  String token = 'token';
  String roles_visitorService = 'roles_visitorService'; // list<String> = []

  String device_id = "device_id";
  String device_name = "device_name";
  String fcm_token = "fcm_token";
  String created_token_at = "created_token_at";

  //Setter
  Future<void> setUserPerfer(String key, dynamic value) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();

      if (value == null) {
        print('Value cannot be null');
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
      print('Error: Unsupported type for SharedPreferences.');
    }
    if (isSaved) {
      print('Successfully saved $key: '+value.toString());
    }
    } catch (err) {
      print('Error saving preference for key $key: $err');
    }
  }

  //Getter
  Future<dynamic> getUserPerfer(String key) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      if (!_prefs.containsKey(key)) return null;
      return _prefs.get(key);
    } catch (err) {
      print('Error retrieving preference for key $key: $err');
      return null;
    }
  }

  Future<void> removeUserPerfer(String key) async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.remove(key);
      print('Remove UserEntity : $key');
    } catch (err) {
      print('Error retrieving preference for key $key: $err');
      return null;
    }
  }

  Future<void> clearUserPerfer() async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      await _prefs.clear();
      print("Clear All SharedPreferences");
    } catch (err) {
      throw err;
    }
  }

  Future<void> generateInfoDeviceToken() async {
    try{
      //uuid
      String devie_id = Uuid().v4();

      // Device Name
      String device_name = '';
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if(Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        device_name = androidInfo.name;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        device_name = iosInfo.utsname.machine;
      }

      //token
      String? fcm_token = await FirebaseMessaging.instance.getToken();

      // Created_at
      String datetime_now =  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await setUserPerfer(this.device_id, devie_id);
      await setUserPerfer(this.device_name, device_name);
      await setUserPerfer(this.fcm_token, fcm_token);
      await setUserPerfer(this.created_token_at, datetime_now);

    } catch (err) {
      throw err;
    }
  }

  Future<void> printAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = await prefs.getKeys();

    print('SharedPreferences contents:');
    for (String key in keys) {
      print('$key: ${prefs.get(key)}');
    }
  }

  Future<void> checkAndClearPrefsByVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();

      String currentVersion = info.version;
      String savedVersion = await getUserPerfer(this.app_version);

      if (savedVersion != currentVersion) {
        await clearUserPerfer();
        await setUserPerfer(this.app_version, currentVersion);
      }
    } catch (err) {
      throw err;
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
    } catch (err) {
      throw err;
    }
    return status;
  }

}