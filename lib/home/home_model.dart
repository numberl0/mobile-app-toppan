import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:toppan_app/userEntity.dart';

import '../config/api_config.dart';

class HomeModel {

  UserEntity userEntity = UserEntity();

  Future<Map<String, bool>> checkConnectionAllService() async {
    Map<String, bool> responseConnection = {
      'auth': false,
      'visitor': false,
    };

    //authService
    try {
      final responseAuth = await http.get(
      Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.authPipe),
      headers: {'Content-Type': 'application/json'},
      ).timeout(
          Duration(seconds: 10),
          onTimeout: () => throw TimeoutException("Service Auth Timed Out."),
        );
      responseConnection['auth'] = true;
    } catch (err) {
      responseConnection['auth'] = false;
    }

    //visitorService
    try {
      final responseVisitor = await http.get(
      Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe),
      headers: {'Content-Type': 'application/json'},
      ).timeout(
          Duration(seconds: 10),
          onTimeout: () => throw TimeoutException("Service Visitor Timed Out."),
        );
      responseConnection['visitor'] = true;
    } catch (err) {
      responseConnection['visitor'] = false;
    }

    return responseConnection;

    //Other API
  }

  Future<List<dynamic>> getRoleByUser(String? username) async {
    final url = Uri.parse(ApiConfig.apiBaseUrl + '/' + ApiConfig.visitorPipe + '/getRoleByUser' + '?username=${Uri.encodeComponent(username!)}');
    List<dynamic> data = [];
    String token = await userEntity.getUserPerfer(userEntity.token);
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
        data = responseDecode['data'];
      }else{
        throw HttpException("Request failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (err) {
      throw err;
    }
    return data;
  }

}