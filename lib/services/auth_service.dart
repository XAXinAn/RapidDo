import 'package:jisu_calendar/common/constants/api_constants.dart';
import 'package:jisu_calendar/common/models/api_response.dart';
import 'package:jisu_calendar/models/user.dart';
import 'package:jisu_calendar/models/privacy_setting.dart';
import 'package:jisu_calendar/services/api_service.dart';
import 'package:jisu_calendar/services/token_storage.dart';

/// 认证服务
/// 基于后端接口文档 SpeedCalendar-Server 实现
class AuthService {
  final ApiService _apiService = ApiService();
  final TokenStorage _tokenStorage = TokenStorage();

  // ==================== 认证模块 API ====================

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await _apiService.get(ApiConstants.authHealth);
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 发送验证码
  /// POST /api/auth/code
  /// [phone] 手机号 (格式: 1[3-9]开头的11位数字)
  Future<ApiResponse<void>> sendVerificationCode(String phone) async {
    try {
      final response = await _apiService.post(
        ApiConstants.authCode,
        data: {'phone': phone},
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message ?? (response.success ? '验证码已发送' : '发送失败'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '发送验证码失败: $e',
      );
    }
  }

  /// 手机号验证码登录
  /// POST /api/auth/login/phone
  /// 首次登录自动注册
  /// [phone] 手机号
  /// [code] 6位验证码
  Future<ApiResponse<User>> loginWithPhone({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.authLoginPhone,
        data: {
          'phone': phone,
          'code': code,
        },
      );

      print('登录响应: success=${response.success}, statusCode=${response.statusCode}');

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // 后端返回格式:
        // userId, token, refreshToken, expiresIn, userInfo
        final String? userId = data['userId'] as String?;
        final String? accessToken = data['token'] as String?;
        final String? refreshToken = data['refreshToken'] as String?;
        final Map<String, dynamic>? userInfo = data['userInfo'] as Map<String, dynamic>?;
        
        print('解析登录响应: userId=$userId, hasToken=${accessToken != null}, hasRefreshToken=${refreshToken != null}');
        
        // 保存双 token
        if (accessToken != null && refreshToken != null) {
          await _apiService.setAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          await _tokenStorage.saveToken(accessToken);
        }

        // 解析并保存用户信息
        if (userInfo != null) {
          final user = User.fromJson(userInfo);
          
          await _tokenStorage.saveUserId(user.id);
          if (user.name != null) {
            await _tokenStorage.saveUserName(user.name!);
          }

          print('登录成功，用户: ${user.name} (${user.id})');
          return ApiResponse<User>(
            success: true,
            message: response.message ?? '登录成功',
            data: user,
            statusCode: response.statusCode,
          );
        } else if (userId != null && accessToken != null) {
          // 兼容：即使没有完整 userInfo，也算登录成功
          await _tokenStorage.saveUserId(userId);
          print('登录成功，用户ID: $userId (无详细信息)');
          return ApiResponse<User>(
            success: true,
            message: response.message ?? '登录成功',
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse<User>(
        success: false,
        message: response.message ?? '登录失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('登录异常: $e');
      return ApiResponse<User>(
        success: false,
        message: '登录失败: $e',
      );
    }
  }

  /// 获取用户信息
  /// GET /api/auth/user/{userId}?requesterId={requesterId}
  /// [userId] 目标用户ID
  /// [requesterId] 请求者ID，用于隐私过滤 (可选)
  Future<ApiResponse<User>> getUserInfo(String userId, {String? requesterId}) async {
    try {
      final response = await _apiService.get(
        ApiConstants.authUser(userId, requesterId: requesterId),
      );

      if (response.success && response.data != null) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<User>(
          success: true,
          message: response.message,
          data: user,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<User>(
        success: false,
        message: response.message ?? '获取用户信息失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: '获取用户信息失败: $e',
      );
    }
  }

  /// 更新用户信息
  /// PUT /api/auth/user/{userId}
  /// [userId] 用户ID
  /// [username] 新昵称 (最大20字符)
  /// [avatar] 新头像URL
  Future<ApiResponse<User>> updateUserInfo(
    String userId, {
    String? username,
    String? avatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (avatar != null) data['avatar'] = avatar;

      if (data.isEmpty) {
        return ApiResponse<User>(
          success: false,
          message: '至少需要提供一个更新字段',
        );
      }

      final response = await _apiService.put(
        ApiConstants.authUserUpdate(userId),
        data: data,
      );

      if (response.success && response.data != null) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        
        // 更新本地存储的用户名
        if (user.name != null) {
          await _tokenStorage.saveUserName(user.name!);
        }
        
        return ApiResponse<User>(
          success: true,
          message: response.message ?? '更新成功',
          data: user,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<User>(
        success: false,
        message: response.message ?? '更新失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: '更新用户信息失败: $e',
      );
    }
  }

  // ==================== 隐私设置 API ====================

  /// 获取隐私设置
  /// GET /api/privacy/settings/{userId}
  Future<ApiResponse<List<PrivacySetting>>> getPrivacySettings(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.privacySettings(userId),
      );

      if (response.success && response.data != null) {
        final List<dynamic> settingsJson = response.data as List<dynamic>;
        final settings = settingsJson
            .map((json) => PrivacySetting.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse<List<PrivacySetting>>(
          success: true,
          message: response.message,
          data: settings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<PrivacySetting>>(
        success: false,
        message: response.message ?? '获取隐私设置失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<PrivacySetting>>(
        success: false,
        message: '获取隐私设置失败: $e',
      );
    }
  }

  /// 批量更新隐私设置
  /// PUT /api/privacy/settings/{userId}
  Future<ApiResponse<void>> updatePrivacySettings(
    String userId,
    List<PrivacySetting> settings,
  ) async {
    try {
      final response = await _apiService.put(
        ApiConstants.privacySettingsUpdate(userId),
        data: {
          'settings': settings.map((s) => s.toJson()).toList(),
        },
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message ?? (response.success ? '更新成功' : '更新失败'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '更新隐私设置失败: $e',
      );
    }
  }

  // ==================== 会话管理 ====================

  /// 退出登录
  Future<void> logout() async {
    await _apiService.clearAuth();
    await _tokenStorage.clearAll();
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final accessToken = await _apiService.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// 获取当前用户ID
  Future<String?> getCurrentUserId() async {
    return await _tokenStorage.getUserId();
  }

  /// 获取当前用户名
  Future<String?> getCurrentUserName() async {
    return await _tokenStorage.getUserName();
  }
}
