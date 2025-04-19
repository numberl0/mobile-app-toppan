

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_model.dart';
import 'package:uuid/uuid.dart';

class VisitorServiceCenterController {

  VisitorServiceCenterModel _model = VisitorServiceCenterModel();

  UserEntity userEntity = UserEntity();

  //Insert Activity Log
  Future<void> insertActvityLog(String action) async {
    try {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      Map<String, dynamic> data = {
          "log_date": formattedDate,
          "action": action,
          "username": await userEntity.getUserPerfer(userEntity.username),
      };
      await _model.insertActivityLog(data);

    } catch (err, stackTrace) {
      await logError(err.toString(), stackTrace.toString());
    }
  }

  //LogError
  Future<void> logError(String message, String stackTrace) async {
    await _model.logError(message, stackTrace);
  }

  //insert fcm_token
  Future<bool> insertFCMToken() async {
    bool status = false;
    try {

      //uuid
      String devie_id = Uuid().v4();
      userEntity.setUserPerfer(userEntity.device_id, devie_id);

      // Username
      String username = await userEntity.getUserPerfer(userEntity.username);

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

      //roles
      List<dynamic> rolesRaw = await _model.getRoleByUser(username);
      List<String> roleList = rolesRaw.cast<String>();
      await userEntity.setUserPerfer(userEntity.roles_visitorService, roleList);
      String roles = (await userEntity.getUserPerfer(userEntity.roles_visitorService)).join(",");

      // Created_at
      String datetime_now =  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      Map<String, dynamic> data = {
        'device_id': devie_id,
        'device_name': device_name,
        'username': username,
        'roles': roles,
        'fcm_token': fcm_token,
        'created_at': datetime_now,
      };
      await _model.insertFCMToken(data);
      status = true;
    } catch (err, stackTrace) {
      print(err);
      userEntity.clearUserPerfer();
      await logError(err.toString(), stackTrace.toString());
    }
    return status;
  }

}