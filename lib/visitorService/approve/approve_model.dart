import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/userEntity.dart';

class ApproveModel {

  UserEntity userEntity = UserEntity();

  Future<List<dynamic>> getRequestApproved(List<String> building_card) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getRequestApproved').replace(queryParameters: { 'building_card': building_card });
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
      if(response.statusCode == ApiConfig.http200) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null){
          data = responseDecode['data'];
        }
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    }catch (err) {
      throw err;
    }
    return data;
  }

  Future<String> getSignatureFilenameByUsername(String username) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getSignaturFilenameByUsername' + '?username=${Uri.encodeComponent(username)}');
    String token = await userEntity.getUserPerfer(userEntity.token);
    String data = '';
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
      if(response.statusCode == ApiConfig.http200) {
        var responseDecode = jsonDecode(response.body);
        if(responseDecode['data'] != null){
          data = responseDecode['data'][0]['sign_name'] ?? '';
        }
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    }catch (err) {
      throw err;
    }
    return data;
  }

  Future<bool> approvedDocument(String tno, String type, Map<String,dynamic> sign_info) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/approvedDocument');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode({
          'tno': tno,
          'type': type,
          'data': sign_info
          }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out."),
      );
      if(response.statusCode == ApiConfig.http200) {
        status = true;
        print('Update successful');
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    }catch (err) {
      throw err;
    }
    return status;
  }

  Future<bool> approvedAll(List<Map<String, dynamic>> tno_listMap, Map<String,dynamic> sign_info) async {
    bool status = false;
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/approvedAll');
    String token = await userEntity.getUserPerfer(userEntity.token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode({
          'tno_listMap': tno_listMap,
          'sign_info': sign_info
          }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException("Timed Out."),
      );
      if(response.statusCode == ApiConfig.http200) {
        status = true;
        print('Update successful');
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    }catch (err) {
      throw err;
    }
    return status;
  }
}