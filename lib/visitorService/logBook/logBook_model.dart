import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';

class LogBookModel {
  
  Future<Uint8List?> getLogBook(
    String type,
    String startDate,
    String endDate,
  ) async {
      final res = await ApiClient.dio.get(
        '/pdf/preview',
        queryParameters: {
          'docType': type,
          'sDate': startDate,
          'eDate': endDate,
        },
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      final String base64pdf = res.data['pdfBase64'];
      return base64Decode(base64pdf);
  }
}