import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toppan_app/api/api_client.dart';
import '../config/api_config.dart';

class LoginModule {
  //Authentication
  Future<Map<String,dynamic>> validateLogin(Map<String, dynamic> data) async {
    Map<String,dynamic> responseMapping = {};
    final url = Uri.parse(ApiConfig.apiBaseUrl + "/auth/authentication");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : $url"),
      );

      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        var dataRes = responseDecode['data'];
        responseMapping = {
          'canLogin': true,
          'displayName': dataRes['displayName'],
          'accessToken': dataRes['accessToken'],
          'refreshToken': dataRes['refreshToken']
        };
      } else {
        var responseDecode = jsonDecode(response.body);
        responseMapping = {
          'canLogin': false,
          'err': responseDecode['error'] ?? 'เกิดข้อผิดพลาด',
        };
      }
    } catch (err) {
      rethrow;
    }
    return responseMapping;
  }

   Future<void> updateFCMToken(String deviceId, Map<String, dynamic> data) async {
      await ApiClient.dio.patch(
        '/user/device-token/$deviceId',
        data: data,
      );
  }
  
}
