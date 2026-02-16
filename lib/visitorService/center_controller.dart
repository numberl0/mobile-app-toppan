import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/center_model.dart';

class CenterController {

  CenterModel _model = CenterModel();

  UserEntity userEntity = UserEntity();

  //Activity Log
  Future<void> insertActvityLog(String action) async {
    try {
      DateTime now = AppDateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      Map<String, dynamic> data = {
          "log_date": formattedDate,
          "action": action,
          "device_id": await userEntity.getUserPerfer(userEntity.device_id),
          "username": await userEntity.getUserPerfer(userEntity.username),
      };
      await _model.insertActivityLog(data);

    } catch (err, stackTrace) {
      await logError(err.toString(), stackTrace.toString());
    }
  }

  //Error Log
  Future<void> logError(String message, String stackTrace) async {
    await _model.logError(message, stackTrace);
  }


  Future<void> updateActiveFCM() async {
    try {
      String? deviceId = await userEntity.getUserPerfer(userEntity.device_id);
      if(deviceId != null) {
        String formatDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(AppDateTime.now());
        await _model.activeToken(deviceId, formatDateTime);
      }
    } catch (err, stackTrace) {
      await logError(err.toString(), stackTrace.toString());
    }
  }

  Future<void> forceLogout(BuildContext context) async {
    try {
      final deviceId = await userEntity.getUserPerfer(userEntity.device_id);

      if (deviceId != null) {
        await _model.logout(deviceId);
      }
      await userEntity.ClearStorage();

      GoRouter.of(context).go('/login');
    } catch (err) {
      await userEntity.ClearStorage();
      GoRouter.of(context).go('/login');
    }
  }

    Future<bool> refreshSession() async {
      try {
        final refreshToken = await userEntity.getRefreshToken();
        final deviceId = await userEntity.getUserPerfer(userEntity.device_id);

        if (refreshToken == null || deviceId == null) {
          return false;
        }

        // ต่อ access token
        final response = await _model.refreshToken({
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        });

        if (response['success'] == true) {
          await userEntity.saveAccessToken(response['accessToken']);
          await userEntity.saveRefreshToken(response['refreshToken']);
          return true;
        }
      } catch (err, stackTrace) {
        await logError(err.toString(), stackTrace.toString());
      }
      return false;
    }

    Future<bool> ensureAuthenticated() async {
      final accessToken = await userEntity.getAccessToken();

      if (accessToken == null) return false;

      if (!JwtDecoder.isExpired(accessToken)) {
        return true;
      }

      return await refreshSession();
    }
}