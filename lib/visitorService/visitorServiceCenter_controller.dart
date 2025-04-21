

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
      // Uuid
      String device_id = await userEntity.getUserPerfer(userEntity.device_id);

      // Device name
      String device_name = await userEntity.getUserPerfer(userEntity.device_name);

      // Username
      String username = await userEntity.getUserPerfer(userEntity.username);

      //roles
      List<dynamic> rolesRaw = await _model.getRoleByUser(username);
      List<String> roleList = rolesRaw.cast<String>();
      await userEntity.setUserPerfer(userEntity.roles_visitorService, roleList);
      String roles = (await userEntity.getUserPerfer(userEntity.roles_visitorService)).join(",");

      // FCM Token
      String fcm_token = await userEntity.getUserPerfer(userEntity.fcm_token);

      // Created_at
      String createdAt = await userEntity.getUserPerfer(userEntity.created_token_at);

      Map<String, dynamic> data = {
        'device_id': device_id,
        'device_name': device_name,
        'username': username,
        'roles': roles,
        'fcm_token': fcm_token,
        'last_active': createdAt,
      };
      await _model.insertFCMToken(data);
      await insertActvityLog('User ${username} login and insert token FCM');  // add log
      status = true;
    } catch (err, stackTrace) {
      userEntity.clearUserPerfer();
      await logError(err.toString(), stackTrace.toString());
    }
    return status;
  }

}