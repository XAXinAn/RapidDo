import 'package:dio/dio.dart';
import 'package:jisu_calendar/common/constants/api_constants.dart';
import 'package:jisu_calendar/common/models/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 基础 API 服务类
/// 封装所有 HTTP 请求的通用逻辑
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// 设置拦截器
  void _setupInterceptors() {
    // 请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 添加认证 Token (使用 accessToken)
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }

          print('🚀 请求: ${options.method} ${options.uri}');
          print('📦 请求数据: ${options.data}');
          print('🔑 请求头: ${options.headers}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ 响应: ${response.statusCode} ${response.requestOptions.uri}');
          print('📨 响应数据: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ 错误: ${error.message}');
          print('📍 请求地址: ${error.requestOptions.uri}');
          print('📊 状态码: ${error.response?.statusCode}');
          print('📨 错误响应: ${error.response?.data}');

          // 处理 401 未授权错误 - 尝试刷新token
          if (error.response?.statusCode == 401) {
            try {
              // 尝试使用 refreshToken 刷新
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                // 重试原请求
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $_accessToken';
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } else {
                // 刷新失败，清除认证信息
                await clearAuth();
              }
            } catch (e) {
              await clearAuth();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// 获取 Dio 实例（用于特殊需求）
  Dio get dio => _dio;

  /// 设置双Token认证
  Future<void> setAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.accessTokenKey, accessToken);
    await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
  }

  /// 获取 AccessToken
  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(ApiConstants.accessTokenKey);
    return _accessToken;
  }

  /// 获取 RefreshToken
  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
    return _refreshToken;
  }

  /// 刷新 AccessToken
  /// 注意：后端刷新接口尚未实现，此方法预留
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
    }
    
    if (_refreshToken == null) return false;

    try {
      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        // 兼容后端返回 token 或 accessToken
        final newToken = response.data['token'] ?? response.data['accessToken'];
        if (newToken != null) {
          _accessToken = newToken;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(ApiConstants.accessTokenKey, _accessToken!);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('刷新token失败: $e');
      return false;
    }
  }

  /// 清除认证信息
  Future<void> clearAuth() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.accessTokenKey);
    await prefs.remove(ApiConstants.refreshTokenKey);
    await prefs.remove(ApiConstants.userIdKey);
    await prefs.remove(ApiConstants.userNameKey);
  }

  /// 通用 GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// 通用 POST 请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// 通用 PUT 请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// 通用 DELETE 请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// 上传文件
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return ApiResponse<T>.fromJson(
        response.data,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// 下载文件
  Future<bool> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      return true;
    } on DioException catch (e) {
      print('下载失败: ${e.message}');
      return false;
    }
  }

  /// 处理 Dio 错误
  ApiResponse<T> _handleDioError<T>(DioException error) {
    String message = '请求失败';
    int? statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout) {
      message = '连接超时';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = '接收超时';
    } else if (error.type == DioExceptionType.sendTimeout) {
      message = '发送超时';
    } else if (error.type == DioExceptionType.badResponse) {
      // 服务器返回错误
      if (error.response?.data != null) {
        if (error.response?.data is Map) {
          message = error.response?.data['message'] ?? '服务器错误';
        } else {
          message = '服务器返回异常数据';
        }
      } else {
        message = '服务器错误 ${statusCode ?? ""}';
      }
    } else if (error.type == DioExceptionType.cancel) {
      message = '请求已取消';
    } else if (error.type == DioExceptionType.connectionError) {
      message = '网络连接失败，请检查网络设置';
    } else {
      message = error.message ?? '未知错误';
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
