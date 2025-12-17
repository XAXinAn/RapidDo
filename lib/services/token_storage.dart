import 'package:shared_preferences/shared_preferences.dart';
import 'package:jisu_calendar/common/constants/api_constants.dart';

/// Token 和用户信息存储服务
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存 Token
  Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(ApiConstants.accessTokenKey, token);
  }

  /// 获取 Token
  Future<String?> getToken() async {
    await init();
    return _prefs!.getString(ApiConstants.accessTokenKey);
  }

  /// 删除 Token
  Future<bool> removeToken() async {
    await init();
    return await _prefs!.remove(ApiConstants.accessTokenKey);
  }

  /// 保存用户 ID
  Future<bool> saveUserId(String userId) async {
    await init();
    return await _prefs!.setString(ApiConstants.userIdKey, userId);
  }

  /// 获取用户 ID
  Future<String?> getUserId() async {
    await init();
    return _prefs!.getString(ApiConstants.userIdKey);
  }

  /// 保存用户名称
  Future<bool> saveUserName(String userName) async {
    await init();
    return await _prefs!.setString(ApiConstants.userNameKey, userName);
  }

  /// 获取用户名称
  Future<String?> getUserName() async {
    await init();
    return _prefs!.getString(ApiConstants.userNameKey);
  }

  /// 清除所有存储数据
  Future<bool> clearAll() async {
    await init();
    return await _prefs!.clear();
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
