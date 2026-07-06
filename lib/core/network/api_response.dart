class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final dataJson = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: dataJson != null ? fromJsonT(dataJson) : null,
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}
