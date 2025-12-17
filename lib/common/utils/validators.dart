/// 表单验证工具类
class Validators {
  /// 验证手机号格式（中国大陆）
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    // 中国大陆手机号：1开头，第二位是3-9，总共11位
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 获取手机号验证错误消息
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '请输入手机号';
    }
    if (!isValidPhone(phone)) {
      return '请输入正确的手机号格式';
    }
    return null;
  }

  /// 验证邮箱格式
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 获取邮箱验证错误消息
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return '请输入邮箱';
    }
    if (!isValidEmail(email)) {
      return '请输入正确的邮箱格式';
    }
    return null;
  }

  /// 验证验证码格式（6位数字）
  static bool isValidVerificationCode(String code) {
    if (code.isEmpty) return false;
    final codeRegex = RegExp(r'^\d{6}$');
    return codeRegex.hasMatch(code);
  }

  /// 获取验证码验证错误消息
  static String? validateVerificationCode(String? code) {
    if (code == null || code.isEmpty) {
      return '请输入验证码';
    }
    if (!isValidVerificationCode(code)) {
      return '请输入6位数字验证码';
    }
    return null;
  }

  /// 验证密码强度（可选，用于未来密码登录）
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    // 至少8位，包含字母和数字
    return password.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }

  /// 获取密码验证错误消息
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return '请输入密码';
    }
    if (password.length < 8) {
      return '密码长度至少8位';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return '密码必须包含字母';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return '密码必须包含数字';
    }
    return null;
  }
}
