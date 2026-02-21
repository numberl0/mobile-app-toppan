import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';

class PermisModel {
  /// -----------------------------
  /// Active Card by Type
  /// -----------------------------
  Future<List<Map<String, dynamic>>> getActiveCardByType(String cardType) async {
      final res = await ApiClient.dio.get(
        '/card/active-by-type',
        queryParameters: {
          'cardType': cardType,
        },
      );

      final list = res.data['data'];
      if (list is List) {
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
  }

  /// -----------------------------
  /// HRIS Emp Info
  /// -----------------------------
  Future<Map<String, String>> getInfoByEmpId(String empId) async {
      final res = await ApiClient.dio.get(
        '/hris/emp_info',
        queryParameters: {
          'empId': empId,
        },
      );

      final data = res.data['data'];
      if (data is Map) {
        return data.map<String, String>(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        );
      }
      return {};
  }

  /// -----------------------------
  /// Manager Role
  /// -----------------------------
  Future<List<dynamic>> getManagerRole() async {
      final res = await ApiClient.dio.get('/user/manager-role');
      return res.data['data'] ?? [];
  }

  /// -----------------------------
  /// Upload Image Files
  /// -----------------------------
  Future<bool> uploadImageFiles(
    String tno,
    String folderNameForm,
    Map<String, dynamic> data,
    String date,
  ) async {
    try {
      final formData = FormData.fromMap({
        'tno': tno,
        'date': date,
        'typeForm': folderNameForm,
      });

      if (data['approver'] != null) {
        final List files = data['approver'];
        for (final file in files) {
          if (file != null) {
            formData.files.add(
              MapEntry(
                'sign[]',
                await MultipartFile.fromFile(file.path),
              ),
            );
          }
        }
      }

      await ApiClient.dio.post(
        '/upload/image-files',
        data: formData,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// -----------------------------
  /// Insert Form
  /// -----------------------------
  Future<bool> insertForm(Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.post(
        '/document/request-form-p',
        data: {
          'docData': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// -----------------------------
  /// Update Form
  /// -----------------------------
  Future<bool> updateForm(String tnoPass, Map<String, dynamic> data) async {
    try {
      await ApiClient.dio.put(
        '/document/pass-req-p/$tnoPass',
        data: data,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// -----------------------------
  /// Load Image as Bytes (NO AUTH)
  /// -----------------------------
  Future<Uint8List?> loadImageAsBytes(String imageUrl) async {
    try {
      final res = await ApiClient.dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data!);
    } catch (_) {
      return null;
    }
  }

  /// -----------------------------
  /// Card Action
  /// -----------------------------
  Future<void> cardAction({
    required String actionType,
    required List<String> cardIds,
  }) async {
      await ApiClient.dio.post(
        '/card/card-action',
        data: {
          'action_type': actionType,
          'list_card': cardIds.map((id) => {'card_id': id}).toList(),
        },
      );

  }

}