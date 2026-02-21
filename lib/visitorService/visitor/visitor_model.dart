import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toppan_app/api/api_client.dart';
import 'package:path/path.dart' as path;

class VisitorModule {
  /// -----------------------------
  /// Agreement text
  Future<Map<String, dynamic>> getAgreementText() async {
      final res = await ApiClient.dio.get('/document/agreement');

      if (res.data['data'] != null && res.data['data'].isNotEmpty) {
        return res.data['data'][0];
      }
      return {};
  }

  /// -----------------------------
  /// Building list
  Future<List<dynamic>> getBuilding() async {
      final res = await ApiClient.dio.get('/document/building');
      return res.data['data'] ?? [];
  }

  /// -----------------------------
  /// Insert request form visitor
  Future<bool> insertRequestFormV(
    Map<String, dynamic> dataRequest,
    Map<String, dynamic> dataForm,
  ) async {
    try {
      await ApiClient.dio.post(
        '/document/request-form-v',
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
  /// Update request form visitor
  Future<bool> updateRequestFormV(
    String tnoPass,
    Map<String, dynamic> dataRequest,
    Map<String, dynamic> dataForm,
  ) async {
    try {
      await ApiClient.dio.put(
        '/document/request-form-v/$tnoPass',
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
  /// Upload image files
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
  /// Load image as bytes
  Future<Uint8List?> loadImageAsBytes(String imageUrl) async {
    try {
      final res = await ApiClient.dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? []);
    } catch (_) {
      return null;
    }
  }

  /// -----------------------------
  /// Load image to temp file
  Future<File?> loadImageToFile(String imageUrl) async {
      final res = await ApiClient.dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final directory = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(imageUrl).path);
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(res.data ?? []);
      return file;
  }

  /// -----------------------------
  /// Departments
  Future<List<String>> getDepartments() async {
      final res = await ApiClient.dio.get('/hris/departments');
      return List<String>.from(res.data['data'] ?? []);
  }

  /// -----------------------------
  /// Contact by department
  Future<List<String>> getContactByDept(String dept) async {
      final res = await ApiClient.dio.get(
        '/hris/emp-name',
        queryParameters: {'dept': dept},
      );
      return List<String>.from(res.data['data'] ?? []);
  }

  /// -----------------------------
  /// Active cards by type
  Future<List<Map<String, dynamic>>> getActiveCardByType(
    List<String> cardTypes,
  ) async {
      final res = await ApiClient.dio.get(
        '/card/active-by-type',
        queryParameters: {
          'cardType': cardTypes.join(','),
        },
      );
      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  /// -----------------------------
  /// Card info from document
  Future<List<Map<String, dynamic>>> getInfoCardFromDoc(
    List<String> cardTypes,
  ) async {
      final res = await ApiClient.dio.get(
        '/card/cards-from-doc',
        queryParameters: {
          'cardIds': cardTypes.join(','),
        },
      );
      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }


}