import 'package:dio/dio.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../dto/semester/semester_dto.dart';

class SemesterApi {
  final Dio _dio = DioClient().dio;

  Future<List<SemesterDto>> getSemesters() async {
    final response = await _dio.get(ApiConstants.semesters);
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data.map((json) => SemesterDto.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<SemesterDto> createSemester(SemesterCreateRequest request) async {
    final response = await _dio.post(
      ApiConstants.semesters,
      data: request.toJson(),
    );
    return SemesterDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<SemesterDto> getSemesterById(String semesterId) async {
    final response = await _dio.get('${ApiConstants.semesters}/$semesterId');
    return SemesterDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSemester(String semesterId) async {
    await _dio.delete('${ApiConstants.semesters}/$semesterId');
  }
}
