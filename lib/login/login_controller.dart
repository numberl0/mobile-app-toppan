import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:toppan_app/visitorService/center_model.dart';
import 'package:uuid/uuid.dart';
import '../component/CustomDIalog.dart';
import 'login_module.dart';

class LoginController {

  LoginModule loginModel = LoginModule();

  UserEntity userEntity = UserEntity();

  CenterController _centerController = CenterController();

 CenterModel _centerModel = CenterModel();

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final LoadingDialog _loadingDialog = LoadingDialog();


  Future<void> login(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      // App version
      final PackageInfo info = await PackageInfo.fromPlatform();

      // ===== DEVICE ID (create once, reuse forever) =====
      String? device_id = await userEntity.getUserPerfer(userEntity.device_id);
      device_id ??= const Uuid().v4();

      String username = usernameController.text;
      String password = passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        _showErrorLoginDialog(context, "กรุณากรอก username และ password");
        return;
      }

        Map<String, dynamic> loginReq = {
          'username': username,
          'password': password,
          'deviceId': device_id,
        };
        Map<String,dynamic> response = await loginModel.validateLogin(loginReq);

        if(response['canLogin'] == true){
          await userEntity.setUserPerfer(userEntity.app_version, info.version);
          await userEntity.setUserPerfer(userEntity.device_id, device_id);
          await userEntity.setUserPerfer(userEntity.username, username);
          await userEntity.setUserPerfer(userEntity.displayName, response['displayName']);
          await userEntity.saveAccessToken(response['accessToken']);
          await userEntity.saveRefreshToken(response['refreshToken']);

          await updateFCMToken();

          clearLoginInput();
          GoRouter.of(context).push('/home');
          await _centerController.insertActvityLog('User logged in');
        } else {
          _showErrorLoginDialog(context, response['err'] ?? 'เกิดข้อผิดพลาด');
        }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      _showErrorLoginDialog(context, 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ');
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

    //insert fcm_token
  Future<void> updateFCMToken() async {
    try {
      // Uuid
      String device_id = await userEntity.getUserPerfer(userEntity.device_id);

      String device_name = '';
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if(Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        device_name = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        device_name = iosInfo.utsname.machine;
      }

      // Username
      String username = await userEntity.getUserPerfer(userEntity.username);

      //roles
      List<dynamic> rolesRaw = await _centerModel.getRoleByUser(username);
      List<String> roleList = rolesRaw.cast<String>();
      await userEntity.setUserPerfer(userEntity.roles_visitorService, roleList);
      String roles = (await userEntity.getUserPerfer(userEntity.roles_visitorService)).join(",");

      //token
      String? fcm_token = await FirebaseMessaging.instance.getToken();

      Map<String, dynamic> data = {
        'device_name': device_name,
        'roles': roles,
        'fcm_token': fcm_token,
      };

      await loginModel.updateFCMToken(device_id, data);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await userEntity.clearUserPerfer();
      await _centerModel.logError(err.toString(), stack.toString());
    }
  }

  void _showErrorLoginDialog(BuildContext context, String errMsg) {
    CustomDialog.show(
                      context: context,
                      title: 'คำเตือน',
                      message: errMsg,
                      type: DialogType.error,
                      onConfirm: () {
                          Navigator.of(context).pop();
                      },
                      showCancelButton: false,
                    );
  }


  void clearLoginInput(){
    usernameController.clear();
    passwordController.clear();
  }

}
