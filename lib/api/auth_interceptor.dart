import 'dart:async';

import 'package:dio/dio.dart';
import 'package:toppan_app/api/api_client.dart';
import 'package:toppan_app/userEntity.dart';
import '../main.dart';

class AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;
  final List<Completer<Response>> _queue = [];
  UserEntity userEntity = UserEntity();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await userEntity.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    
    print('❌ ERROR STATUS: ${err.response?.statusCode}');
    print('❌ ERROR DATA: ${err.response?.data}');
    print('❌ ERROR PATH: ${err.requestOptions.path}');
    print('-----------------------------------');
    
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }
    
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // ถ้ามี refresh อยู่แล้ว → รอ
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _queue.add(completer);
        return handler.resolve(await completer.future);
      }

      _isRefreshing = true;

      final newToken = await _refreshToken();

      _isRefreshing = false;

      if (newToken != null) {

        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        final response = await ApiClient.dio.fetch(requestOptions);

        for (final c in _queue) {
          c.complete(response);
        }
        _queue.clear();

        return handler.resolve(response);
      }

      // refresh fail
      for (final c in _queue) {
        c.completeError(err);
      }
      _queue.clear();

      await userEntity.ClearStorage();

      appRouter.go('/login');
      return;
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await userEntity.getRefreshToken();
    final deviceId = await userEntity.getUserPerfer(userEntity.device_id);

    if (refreshToken == null || deviceId == null) return null;

    try {
      final response = await ApiClient.dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );

      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      await userEntity.saveAccessToken(newAccessToken);
      await userEntity.saveRefreshToken(newRefreshToken);

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}
