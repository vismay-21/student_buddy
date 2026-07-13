import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../data/local/database_helper.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? validationErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors,
  });

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return '$message: ${validationErrors!.join(', ')}';
    }
    return message;
  }
}

class AppInterceptors extends Interceptor {
  /// Optional navigator key — set by MaterialApp to enable auth redirects.
  static GlobalKey<NavigatorState>? navigatorKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    // Inject JWT Bearer token from the active Supabase session.
    final token = AuthService.instance.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401: sign the user out and navigate to login.
    if (err.response?.statusCode == 401) {
      AuthService.instance.signOut().then((_) {
        DatabaseHelper.instance.closeDatabase().then((_) {
          final nav = navigatorKey?.currentState;
          if (nav != null) {
            nav.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      });
    }

    String errorMessage = 'An unexpected error occurred';
    List<String>? validationErrors;

    if (err.response != null) {
      final data = err.response!.data;
      if (data is Map<String, dynamic>) {
        // Match the FastAPI ApiResponse wrapper schema: { success: false, message: "...", errors: [...] }
        errorMessage = data['message'] ?? errorMessage;

        final rawErrors = data['errors'];
        if (rawErrors is List) {
          validationErrors = rawErrors.map((e) => e.toString()).toList();
        }
      } else {
        errorMessage = 'Server error: ${err.response!.statusMessage}';
      }
    } else {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout with the server';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Send timeout in connection with the server';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Receive timeout in connection with the server';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Cannot connect to server. Check your network or if backend is running locally.';
          break;
        default:
          errorMessage = 'Network connection failed';
          break;
      }
    }

    final apiException = ApiException(
      message: errorMessage,
      statusCode: err.response?.statusCode,
      validationErrors: validationErrors,
    );

    // Resolve the error by throwing our structured ApiException
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }
}

