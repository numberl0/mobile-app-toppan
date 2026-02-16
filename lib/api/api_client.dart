import 'package:dio/dio.dart';
import 'package:toppan_app/api/auth_interceptor.dart';
import 'package:toppan_app/config/api_config.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(AuthInterceptor());
}
