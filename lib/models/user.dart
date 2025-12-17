/// 用户信息模型
/// 对应后端 UserInfo 数据结构
class User {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final int? gender;  // 0-未知, 1-男, 2-女
  final String? birthday;  // yyyy-MM-dd 格式
  final String? bio;
  final String? loginType;  // "phone" 或 "email"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    this.gender,
    this.birthday,
    this.bio,
    this.loginType,
    this.createdAt,
    this.updatedAt,
  });

  /// 获取性别文本
  String get genderText {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }

  /// 从后端 JSON 创建 User 对象
  /// 后端字段映射：
  /// - userId -> id
  /// - username -> name
  /// - avatar -> avatarUrl
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['userId'] ?? json['id'] ?? '').toString(),
      name: json['username'] as String? ?? json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar'] as String? ?? json['avatarUrl'] as String?,
      gender: json['gender'] as int?,
      birthday: json['birthday'] as String?,
      bio: json['bio'] as String?,
      loginType: json['loginType'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// 转换为 JSON（用于发送到后端）
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      if (name != null) 'username': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar': avatarUrl,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (bio != null) 'bio': bio,
      if (loginType != null) 'loginType': loginType,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    int? gender,
    String? birthday,
    String? bio,
    String? loginType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      bio: bio ?? this.bio,
      loginType: loginType ?? this.loginType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
