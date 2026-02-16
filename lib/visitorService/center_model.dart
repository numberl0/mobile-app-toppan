import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:toppan_app/api/api_client.dart';
import 'package:toppan_app/component/AppDateTime.dart';

class CenterModel {

  Future<void> insertActivityLog(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post(
        '/log/activity-log',
        data: data,
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  Future<void> logError(String message, String stackTrace) async {
    try {
      await ApiClient.dio.post(
        '/log/log-error',
        data: {
          'message': message,
          'stack': stackTrace,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(AppDateTime.now()),
        },
      );
    } catch (_) {
      // ❗ ห้าม throw ต่อ
      // logging fail ต้องเงียบ
    }
  }

  Future<List<dynamic>> getRoleByUser(String username) async {
    try {
      final res = await ApiClient.dio.get(
        '/user/role-by-user',
        queryParameters: {'username': username},
      );
      return res.data['data'] ?? [];
    } on DioException {
      rethrow;
    }
  }

  Future<void> activeToken(String deviceId, String dateTimeNow) async {
    try {
      await ApiClient.dio.patch(
      '/user/active-token/$deviceId',
      data: {'last_active': dateTimeNow},
    );
    } on DioException {
      rethrow;
    }
  }

  Future<bool> checkRecordFCM(String deviceId) async {
    try{
      final res = await ApiClient.dio.get(
        '/user/check-token',
        queryParameters: {'device_id': deviceId},
      );
      return res.data['data'] == true;
    } on DioException {
      rethrow;
    }
  }

  Future<String?> getConfigValue(String key) async {
    try {
      final res = await ApiClient.dio.get(
        '/other/config-value',
        queryParameters: {'key': key},
      );
      return res.data['value'];
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> data) async {
    try{
      final res = await ApiClient.dio.post(
        '/auth/refresh',
        data: data,
      );
    return res.data;
    } catch (_){
      rethrow;
    }
  }

  Future<void> logout(String deviceId) async {
    try{
      await ApiClient.dio.post(
        '/auth/logout',
        data: { 'deviceId': deviceId },
      );
    } on DioException {
      rethrow;
    }
  }
}