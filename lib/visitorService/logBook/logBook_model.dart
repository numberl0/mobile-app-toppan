import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/userEntity.dart';

import 'package:http/http.dart' as http;

class LogBookModel {
  
  UserEntity userEntity = UserEntity();

  Future<List<dynamic>> getLogBook(String startDate, String endDate) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getLogBook' + '?start_date=${Uri.encodeComponent(startDate)}&end_date=${Uri.encodeComponent(endDate)}');
    String token = await userEntity.getUserPerfer(userEntity.token);
    List<dynamic> data = [];
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out in url : ${url}"),
      );
      if(response.statusCode >= 200 && response.statusCode <= 299) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null){
          data = responseDecode['data'];
        }
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }
}