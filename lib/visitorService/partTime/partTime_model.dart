
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
      final res = await ApiClient.dio.get(
        '/card/active-by-type',
        queryParameters: {
          'cardType': cardTypes.join(','),
        },
      );

      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  /// -----------------------------
  /// Get temporary pass since yesterday
  Future<List<Map<String, dynamic>>> getTemporarySinceYesterday() async {
      final res = await ApiClient.dio.get(
        '/document/temporary-since-yesterday',
      );

      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
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
    } catch (_) {
      return false;
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
    } catch (_) {
      return false;
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
    } catch (_) {
      return false;
    }
  }
}