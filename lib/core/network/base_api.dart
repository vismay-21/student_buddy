import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'api_response.dart';

abstract class BaseApi {
  final Dio dio = DioClient().dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
  }) async {
    final response = await dio.get(path, queryParameters: queryParameters);
    return ApiResponse<T>.fromJson(response.data as Map<String, dynamic>, parser);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
  }) async {
    final response = await dio.post(path, data: data, queryParameters: queryParameters);
    return ApiResponse<T>.fromJson(response.data as Map<String, dynamic>, parser);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) parser,
  }) async {
    final response = await dio.put(path, data: data, queryParameters: queryParameters);
    return ApiResponse<T>.fromJson(response.data as Map<String, dynamic>, parser);
  }

  Future<ApiResponse<void>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await dio.delete(path, data: data, queryParameters: queryParameters);
    return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => null);
  }
}
