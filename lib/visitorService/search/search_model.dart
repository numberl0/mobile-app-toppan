import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';

class SearchModule {
  /// -----------------------------
  /// Get all request forms by date
  Future<Map<String, List<dynamic>>> getAllRequestForm(
    String dateToDay,
  ) async {
    try {
      final res = await ApiClient.dio.get(
        '/document/requests',
        queryParameters: {
          'dateToDay': dateToDay,
        },
      );

      List<dynamic> getList(String key) {
        final value = res.data[key];
        return value is List ? value : [];
      }

      return {
        'visitor': getList('visitor'),
        'employee': getList('employee'),
        'permission': getList('permission'),
        'temporary': getList('temporary'),
      };
    } on DioException catch (e) {
      print('[getAllRequestForm] ${e.message}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// -----------------------------
  /// Update temporary field
  Future<bool> updateTemporaryField(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await ApiClient.dio.patch(
        '/document/temporary/$id',
        data: data,
      );
      return true;
    } on DioException catch (e) {
      print('[updateTemporaryField] ${e.message}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// -----------------------------
  /// Upload image files (Multipart)
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
        for (final File? file in data['approver']) {
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
    } on DioException catch (e) {
      print('[uploadImageFiles] ${e.message}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

}