import 'package:dio/dio.dart';

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
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add default headers here if needed (e.g. Content-Type)
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    
    // Future expansion point: Adding Authorization Bearer tokens in Sprint 13.
    // In Sprint 12 (MVP Mode), endpoints are public.
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
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
