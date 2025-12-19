/// API 常量配置
/// 基于后端接口文档 SpeedCalendar-Server
class ApiConstants {
  // Base URL - 真机调试经 adb reverse 走本机服务
  static const String baseUrl = 'http://127.0.0.1:8080/api';
  
  // 超时时间配置
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // ========== 认证模块 /api/auth ==========
  /// 健康检查 GET
  static const String authHealth = '/auth/health';
  /// 发送验证码 POST
  static const String authCode = '/auth/code';
  /// 手机号登录 POST
  static const String authLoginPhone = '/auth/login/phone';
  /// Token刷新 POST (待后端实现)
  static const String authRefresh = '/auth/refresh';
  /// 获取用户信息 GET /auth/user/{userId}?requesterId={requesterId}
  static String authUser(String userId, {String? requesterId}) {
    if (requesterId != null) {
      return '/auth/user/$userId?requesterId=$requesterId';
    }
    return '/auth/user/$userId';
  }
  /// 更新用户信息 PUT /auth/user/{userId}
  static String authUserUpdate(String userId) => '/auth/user/$userId';
  
  // ========== 头像管理 /api/avatar ==========
  /// 上传头像 POST (multipart/form-data)
  static const String avatarUpload = '/avatar/upload';
  /// 删除头像 DELETE /avatar/{userId}
  static String avatarDelete(String userId) => '/avatar/$userId';
  
  // ========== 隐私设置 /api/privacy ==========
  /// 获取隐私设置 GET /privacy/settings/{userId}
  static String privacySettings(String userId) => '/privacy/settings/$userId';
  /// 批量更新隐私设置 PUT /privacy/settings/{userId}
  static String privacySettingsUpdate(String userId) => '/privacy/settings/$userId';
  /// 清除隐私设置缓存 DELETE /privacy/cache/{userId}
  static String privacyCacheClear(String userId) => '/privacy/cache/$userId';
  
  // ========== 文件访问 /api/files ==========
  /// 访问头像文件 GET /files/avatars/{filename}
  static String filesAvatars(String filename) => '/files/avatars/$filename';
  
  // ========== 日程相关 /api/schedules ==========
  /// 日程列表基础路径
  static const String schedules = '/schedules';
  
  /// 获取日程列表 GET /schedules?year={year}&month={month}&userId={userId}
  static String schedulesQuery({required int year, required int month, String? userId}) {
    final params = ['year=$year', 'month=$month'];
    if (userId != null) params.add('userId=$userId');
    return '/schedules?${params.join('&')}';
  }
  
  /// 按日期范围获取日程 GET /schedules?startDate={}&endDate={}&userId={}
  static String schedulesDateRange({
    required String startDate,
    required String endDate,
    String? userId,
  }) {
    final params = ['startDate=$startDate', 'endDate=$endDate'];
    if (userId != null) params.add('userId=$userId');
    return '/schedules?${params.join('&')}';
  }
  
  /// 获取/更新/删除单个日程 /schedules/{scheduleId}
  static String scheduleById(String scheduleId) => '/schedules/$scheduleId';
  
  // ========== AI 聊天相关 ==========
  static const String aiSessions = '/ai/sessions';
  static String aiSessionMessages(String sessionId) => '/ai/sessions/$sessionId/messages';
  
  // ========== 存储键名 ==========
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userInfoKey = 'user_info';
}
