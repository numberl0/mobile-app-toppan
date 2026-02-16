
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';

class PartTimeModel {
  /// -----------------------------
  /// Get active cards by types
  Future<List<Map<String, dynamic>>> getActiveCardByType(
    List<String> cardTypes,
  ) async {
    try {
      final res = await ApiClient.dio.get(
        '/card/active-by-type',
        queryParameters: {
          'cardType': cardTypes.join(','),
        },
      );

      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } on DioException catch (e) {
      print('[getActiveCardByType] ${e.message}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// -----------------------------
  /// Get temporary pass since yesterday
  Future<List<Map<String, dynamic>>> getTemporarySinceYesterday() async {
    try {
      final res = await ApiClient.dio.get(
        '/document/temporary-since-yesterday',
      );

      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } on DioException catch (e) {
      print('[getTemporarySinceYesterday] ${e.message}');
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

  /// -----------------------------
  /// Insert temporary pass
  Future<bool> insertTemporaryPass(
    Map<String, dynamic> dataRequest,
  ) async {
    try {
      await ApiClient.dio.post(
        '/document/temporary',
        data: {
          'requestData': dataRequest,
        },
      );
      return true;
    } on DioException catch (e) {
      print('[insertTemporaryPass] ${e.message}');
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
}