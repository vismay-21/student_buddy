import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'interceptors.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  // Configurable flag to enable/disable logging
  static bool enableLogging = kDebugMode;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // Add custom logging and error formatting interceptors
    dio.interceptors.add(AppInterceptors());
    
    // Log requests/responses to terminal for easy debugging in development
    if (enableLogging) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }
  }
}
