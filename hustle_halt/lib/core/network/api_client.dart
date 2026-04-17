import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'https://gigarmor.onrender.com'; // Target FastAPI Backend (Deployed)
  
  static String? accessToken; // Stored JWT token

  static final Dio instance = _init();

  static Dio _init() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor to inject JWT token and log
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          if (kDebugMode) {
            debugPrint('🌐 DIO REQ: [${options.method}] ${options.uri}');
            debugPrint('🌐 DIO DATA: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ DIO RES: [${response.statusCode}] ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ DIO ERR: [${e.response?.statusCode}] ${e.requestOptions.uri}');
            debugPrint('❌ DIO ERR DATA: ${e.response?.data}');
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}
