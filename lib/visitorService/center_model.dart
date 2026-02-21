import 'dart:async';
import 'package:intl/intl.dart';
import 'package:toppan_app/api/api_client.dart';
import 'package:toppan_app/component/AppDateTime.dart';

class CenterModel {

  Future<void> insertActivityLog(Map<String, dynamic> data) async {
      await ApiClient.dio.post(
        '/log/activity-log',
        data: data,
      );
  }

  Future<void> logError(String message, String stackTrace) async {
      await ApiClient.dio.post(
        '/log/log-error',
        data: {
          'message': message,
          'stack': stackTrace,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(AppDateTime.now()),
        },
      );
  }

  Future<List<dynamic>> getRoleByUser(String username) async {
      final res = await ApiClient.dio.get(
        '/user/role-by-user',
        queryParameters: {'username': username},
      );
      return res.data['data'] ?? [];
  }


  Future<bool> checkRecordFCM(String deviceId) async {
      final res = await ApiClient.dio.get(
        '/user/check-token',
        queryParameters: {'device_id': deviceId},
      );
      return res.data['data'] == true;
  }

  Future<String?> getConfigValue(String key) async {
      final res = await ApiClient.dio.get(
        '/other/config-value',
        queryParameters: {'key': key},
      );
      return res.data['value'];
  }

  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> data) async {
      final res = await ApiClient.dio.post(
        '/auth/refresh',
        data: data,
      );
    return res.data;
  }

  Future<void> logout(String deviceId) async {
      await ApiClient.dio.post(
        '/auth/logout',
        data: { 'deviceId': deviceId },
      );
  }
}