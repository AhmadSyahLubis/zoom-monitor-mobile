class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    final rawData = json['data'];
    T? parsedData;

    if (rawData != null) {
      if (fromJsonT != null) {
        parsedData = fromJsonT(rawData);
      } else if (rawData is T) {
        parsedData = rawData;
      }
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorCode: json['error_code'] as String?,
      errors: json['errors'],
      data: parsedData,
    );
  }
}
