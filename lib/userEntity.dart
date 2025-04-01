import 'package:shared_preferences/shared_preferences.dart';

// Like LocalStorage
class UserEntity {

  //Key
  String username = 'username';
  String token = 'token';
  String roles_visitorService = 'roles_visitorService'; // list<String> = []


  String device_id = "device_id";

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
      _prefs.remove(key);
      print('Remove UserEntity : $key');
    } catch (err) {
      print('Error retrieving preference for key $key: $err');
      return null;
    }
  }

  Future<void> clearUserPerfer() async {
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      _prefs.clear();
    } catch (err) {
      throw err;
    }
  }

}