/// 隐私设置模型
/// 对应后端 PrivacySetting 数据结构
class PrivacySetting {
  final String fieldName;       // 字段名: phone, email, birthday, gender, bio
  final String displayName;     // 显示名称
  final VisibilityLevel visibilityLevel;  // 可见性级别

  PrivacySetting({
    required this.fieldName,
    required this.displayName,
    required this.visibilityLevel,
  });

  factory PrivacySetting.fromJson(Map<String, dynamic> json) {
    return PrivacySetting(
      fieldName: json['fieldName'] as String,
      displayName: json['displayName'] as String,
      visibilityLevel: VisibilityLevel.fromString(json['visibilityLevel'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'visibilityLevel': visibilityLevel.value,
    };
  }

  PrivacySetting copyWith({
    String? fieldName,
    String? displayName,
    VisibilityLevel? visibilityLevel,
  }) {
    return PrivacySetting(
      fieldName: fieldName ?? this.fieldName,
      displayName: displayName ?? this.displayName,
      visibilityLevel: visibilityLevel ?? this.visibilityLevel,
    );
  }
}

/// 可见性级别枚举
enum VisibilityLevel {
  public('PUBLIC', '公开'),
  friendsOnly('FRIENDS_ONLY', '仅好友'),
  private_('PRIVATE', '私密');

  final String value;
  final String displayName;

  const VisibilityLevel(this.value, this.displayName);

  static VisibilityLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PUBLIC':
        return VisibilityLevel.public;
      case 'FRIENDS_ONLY':
        return VisibilityLevel.friendsOnly;
      case 'PRIVATE':
        return VisibilityLevel.private_;
      default:
        return VisibilityLevel.public;
    }
  }
}
