import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/userEntity.dart';

import 'package:http/http.dart' as http;

class VisitorServiceCenterModel {

  UserEntity userEntity = UserEntity();

  Future<void> insertActivityLog(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/insertActivityLog');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print("[SUCCESS] Activity Log Inserted");
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
  }

  Future<void> logError(String message, String stackTrace) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/logError');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: 
        {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'message': message,
          'stack': stackTrace,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        print("[LOG ERROR] Write error logged in file successfully!");
      } else {
         throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    }catch (err) {
      throw err;
    }
  }

  Future<List<dynamic>> getRoleByUser(String? username) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getRoleByUser' + '?username=${Uri.encodeComponent(username!)}');
    List<dynamic> data = [];
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.get(
        url,
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}'
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        data = responseDecode['data'];
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }

  Future<void> insertFCMToken(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/insertFCMToken');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: 
        {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        print("[SUCCESS] Insert FCM Token Successfully");
      } else {
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      print("[ERROR] Failed to insert FCM Token: $err");
      throw err;
    }
   }

   Future<void> activeFCM_TOKEN(String deviceId, String dateTimeNow) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/updateActiveFCMToken');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: 
        {
          'Authorization': 'Bearer ${token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'device_id': deviceId,
          'last_active': dateTimeNow
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        print("[SUCCESS] Update Active FCM Token Successfully");
      } else {
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      print("[ERROR] Failed to Update Active FCM Token: $err");
      throw err;
    }
   }

   Future<void> deleteFCMToken(String device_id) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/deleteFCMToken');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try{
      final response = await http.delete(
        url,
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}',
        },
         body: jsonEncode({ 
        "device_id": device_id,
      }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        print("[SUCCESS] FCM Token deleted successfully");
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
  }

  Future<bool> checkRecordFCM(String device_id) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/checkRecordFCM' + '?device_id=${Uri.encodeComponent(device_id)}');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try{
      final response = await http.get(
        url,
        headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}',
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        final data = jsonDecode(response.body);
        status = data['data'];
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return status;
  }
}