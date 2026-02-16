import 'dart:async';
import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';
import 'package:toppan_app/userEntity.dart';

class HomeModel {

  UserEntity userEntity = UserEntity();

  Future<List<dynamic>> getRoleByUser(String username) async {
    try {
      final response = await ApiClient.dio.get('/user/role-by-user',queryParameters: {'username': username,},);
      print(response.data['data']);
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  Future<bool> hasNotification(String username, List<String> roles) async {
    try {
      final response = await ApiClient.dio.get(
        '/approval/notify-request', 
        queryParameters: {
          'username': username,
          'roles': roles,
        },
      );

      return response.data['hasNotification'] == true;
    } on DioException catch (_) {
      return false;
    }
  }

}