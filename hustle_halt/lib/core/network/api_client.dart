import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'https://gigarmor.onrender.com'; // Target FastAPI Backend
  
  static final Dio instance = _init();

  static Dio _init() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for basic logging
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('🌐 DIO REQ: [${options.method}] ${options.uri}');
            debugPrint('🌐 DIO DATA: ${options.data}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('✅ DIO RES: [${response.statusCode}] ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugPrint('❌ DIO ERR: [${e.response?.statusCode}] ${e.requestOptions.uri}');
            debugPrint('❌ DIO ERR DATA: ${e.response?.data}');
            return handler.next(e);
          },
        ),
      );
    }

    return dio;
  }
}
