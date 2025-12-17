/// 通用 API 响应模型
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    // 兼容后端返回格式：使用 code 字段判断成功
    final int? code = json['code'] as int?;
    final bool success = json['success'] ?? (code != null && code >= 200 && code < 300);
    
    return ApiResponse<T>(
      success: success,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      statusCode: code ?? json['statusCode'] as int?,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T)? toJsonT) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null && toJsonT != null) 'data': toJsonT(data as T),
      if (statusCode != null) 'statusCode': statusCode,
    };
  }

  bool get isSuccess => success && statusCode != null && statusCode! >= 200 && statusCode! < 300;
}

/// API 错误响应
class ApiError {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiError({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? '未知错误',
      statusCode: json['statusCode'] as int?,
      errorCode: json['errorCode'] as String?,
    );
  }
}
