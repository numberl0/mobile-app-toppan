import 'dart:async';
import 'package:toppan_app/api/api_client.dart';

class ApproveModel {

  Future<String> getFirstnameApprover(String username) async {
      final res = await ApiClient.dio.get(
        '/user/get-firstname',
        queryParameters: {
          'username': username,
        },
      );

      return res.data['first_name'] ?? '';
  }


  Future<Map<String, List<dynamic>>> getRequestForApproved(
    String username,
    List<String> buildingCard,
  ) async {
      final res = await ApiClient.dio.get(
        '/approval/requests',
        queryParameters: {
          'username': username,
          'building_card': buildingCard,
        },
      );

      final decoded = res.data;

      List<dynamic> getList(String key) {
        final value = decoded[key];
        return value is List ? value : [];
      }

      return {
        'visitor': getList('visitor'),
        'employee': getList('employee'),
        'permission': getList('permission'),
      };
  }

    Future<Map<String, dynamic>> approvedDocument(
    String tno,
    String type,
    String date,
    Map<String, dynamic> signInfo,
    String username,
  ) async {
      final res = await ApiClient.dio.patch(
        '/approval/document/$tno',
        data: {
          'type': type,
          'date': date,
          'sign_info': signInfo,
          'username': username,
        },
      );

      return _mapApproveResponse(res.data);
  }

  Future<Map<String, dynamic>> approvedList(
    String docType,
    List<Map<String, dynamic>> tnoListMap,
    Map<String, dynamic> signInfo,
    String username,
  ) async {
      final res = await ApiClient.dio.patch(
        '/approval/list_document',
        data: {
          'docType': docType,
          'tno_listMap': tnoListMap,
          'sign_info': signInfo,
          'username': username,
        },
      );

      return _mapApproveResponse(res.data);
  }

  /// -----------------------------
  /// Helper: map approve response
  /// -----------------------------
  Map<String, dynamic> _mapApproveResponse(Map<String, dynamic> json) {
    final String flag = json['flag'] ?? 'unknown';
    String message;

    switch (flag) {
      case 'approved':
        message = 'อนุมัติสำเร็จ';
        break;
      case 'no_signature':
        message = 'บัญชีนี้ยังไม่มีลายเซ็น';
        break;
      case 'already_approved':
        message = 'เอกสารนี้ถูกอนุมัติไปแล้ว';
        break;
      default:
        message = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
    }

    return {
      'success': json['success'] ?? false,
      'flag': flag,
      'message': message,
    };
  }
}