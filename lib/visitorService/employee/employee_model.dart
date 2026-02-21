import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:toppan_app/api/api_client.dart';

class EmployeeModel {
  /// -----------------------------
  /// Building
  /// -----------------------------
  Future<List<dynamic>> getBuilding() async {
      final res = await ApiClient.dio.get('/document/building');
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

      Future<void> addFiles(String key, List<File?>? files) async {
        if (files == null) return;
        for (final file in files) {
          if (file != null) {
            formData.files.add(
              MapEntry(
                key,
                await MultipartFile.fromFile(file.path),
              ),
            );
          }
        }
      }

      await addFiles('people[]', data['people']);
      await addFiles('item_in[]', data['item_in']);
      await addFiles('item_out[]', data['item_out']);
      await addFiles('sign[]', data['approver']);

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
  /// Insert Request Form (Employee)
  /// -----------------------------
  Future<bool> insertRequestFormE(
    Map<String, dynamic> dataRequest,
    Map<String, dynamic> dataForm,
  ) async {
    try {
      await ApiClient.dio.post(
        '/document/request-form-e',
        data: {
          'requestRawData': dataRequest,
          'formRawData': dataForm,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// -----------------------------
  /// Update Request Form (Employee)
  /// -----------------------------
  Future<bool> updateRequestFormE(
    String tnoPass,
    Map<String, dynamic> dataRequest,
    Map<String, dynamic> dataForm,
  ) async {
    try {
      await ApiClient.dio.put(
        '/document/request-form-e/$tnoPass',
        data: {
          'requestRawData': dataRequest,
          'formRawData': dataForm,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// -----------------------------
  /// Load image → bytes (NO AUTH)
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
  /// Load image → File
  /// -----------------------------
  Future<File?> loadImageToFile(String imageUrl) async {
      final res = await ApiClient.dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(imageUrl).path);
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(res.data!);
      return file;
  }

  /// -----------------------------
  /// Departments
  /// -----------------------------
  Future<List<String>> getDepartments() async {
      final res = await ApiClient.dio.get('/hris/getDepartments');
      return (res.data['data'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
  }

  /// -----------------------------
  /// Contact by Dept
  /// -----------------------------
  Future<List<String>> getContactByDept(String dept) async {
      final res = await ApiClient.dio.get(
        '/hris/emp-name',
        queryParameters: {'dept': dept},
      );

      return (res.data['data'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
  }

  /// -----------------------------
  /// HRIS Emp Info
  /// -----------------------------
  Future<Map<String, String>> getInfoByEmpId(String empId) async {
      final res = await ApiClient.dio.get(
        '/hris/emp_info',
        queryParameters: {'empId': empId},
      );

      final data = res.data['data'];
      if (data is Map) {
        return data.map<String, String>(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        );
      }
      return {};
  }


}