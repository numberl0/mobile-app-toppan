import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toppan_app/api/api_client.dart';
import '../config/api_config.dart';

class LoginModule {
  //Authentication
  Future<Map<String,dynamic>> validateLogin(Map<String, dynamic> data) async {
    print(ApiConfig.apiBaseUrl);
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

      Map<String, dynamic> responseDecode = {};
      if (response.body.isNotEmpty) {
        responseDecode = jsonDecode(response.body);
      }

      // ===== SUCCESS =====
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        final dataRes = responseDecode['data'] ?? {};
        return {
          'canLogin': true,
          'displayName': dataRes['displayName'],
          'accessToken': dataRes['accessToken'],
          'refreshToken': dataRes['refreshToken'],
        };
      }
      // ===== UNAUTHORIZED =====
      if (response.statusCode == 401) {
        return {
          'canLogin': false,
          'err': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'
        };
      }

      // ===== FORBIDDEN =====
      if (response.statusCode == 403) {
        return {
          'canLogin': false,
          'err': 'คุณไม่มีสิทธิ์เข้าใช้งานระบบนี้'
        };
      }

      // ===== OTHER SERVER ERROR =====
      return {
        'canLogin': false,
        'err': responseDecode['message'] ??
            responseDecode['error'] ??
            'เกิดข้อผิดพลาดจากระบบ กรุณาลองใหม่อีกครั้ง'
      };
    } on TimeoutException {
      return {
        'canLogin': false,
        'err': 'การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่'
      };
    } catch (e) {
      return {
        'canLogin': false,
        'err': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'
      };
    }
  }

   Future<void> updateFCMToken(String deviceId, Map<String, dynamic> data) async {
      await ApiClient.dio.patch(
        '/user/device-token/$deviceId',
        data: data,
      );
  }
  
}
