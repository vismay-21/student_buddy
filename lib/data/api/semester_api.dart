import 'package:student_buddy/core/network/base_api.dart';
import '../../core/network/api_constants.dart';
import '../dto/semester/semester_dto.dart';

class SemesterApi extends BaseApi {
  Future<List<SemesterDto>> getSemesters() async {
    final response = await get<List<SemesterDto>>(
      ApiConstants.semesters,
      parser: (json) => (json as List)
          .map((item) => SemesterDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<SemesterDto> createSemester(SemesterCreateRequest request) async {
    final response = await post<SemesterDto>(
      ApiConstants.semesters,
      data: request.toJson(),
      parser: (json) => SemesterDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SemesterDto> getSemesterById(String semesterId) async {
    final response = await get<SemesterDto>(
      '${ApiConstants.semesters}/$semesterId',
      parser: (json) => SemesterDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> deleteSemester(String semesterId) async {
    await delete('${ApiConstants.semesters}/$semesterId');
  }

  Future<SemesterDto> updateSemester(String semesterId, SemesterUpdateRequest request) async {
    final response = await put<SemesterDto>(
      '${ApiConstants.semesters}/$semesterId',
      data: request.toJson(),
      parser: (json) => SemesterDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}

