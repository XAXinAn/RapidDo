/// 消息发送者角色
enum Sender {
  user('user'),
  ai('assistant'),
  system('system');

  final String value;
  const Sender(this.value);

  static Sender fromString(String? value) {
    switch (value) {
      case 'user':
        return Sender.user;
      case 'assistant':
        return Sender.ai;
      case 'system':
        return Sender.system;
      default:
        return Sender.ai;
    }
  }
}

/// AI 聊天消息模型
/// 对应后端 chat_messages 表
class ChatMessage {
  final String? id;
  final String? sessionId;
  final String text;
  final Sender sender;
  final int? tokensUsed;
  final int? sequenceNum;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    this.sessionId,
    required this.text,
    required this.sender,
    this.tokensUsed,
    this.sequenceNum,
    this.createdAt,
  });

  /// 从后端 JSON 创建
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString(),
      sessionId: json['sessionId'] ?? json['session_id'] as String?,
      text: json['content'] ?? json['text'] ?? '',
      sender: Sender.fromString(json['role'] as String?),
      tokensUsed: json['tokensUsed'] ?? json['tokens_used'] as int?,
      sequenceNum: json['sequenceNum'] ?? json['sequence_num'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// 转换为后端 JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (sessionId != null) 'sessionId': sessionId,
      'content': text,
      'role': sender.value,
      if (tokensUsed != null) 'tokensUsed': tokensUsed,
      if (sequenceNum != null) 'sequenceNum': sequenceNum,
    };
  }

  /// 创建用户消息
  factory ChatMessage.user(String text) {
    return ChatMessage(text: text, sender: Sender.user);
  }

  /// 创建 AI 回复消息
  factory ChatMessage.assistant(String text) {
    return ChatMessage(text: text, sender: Sender.ai);
  }

  /// 是否是用户消息
  bool get isUser => sender == Sender.user;

  /// 是否是 AI 消息
  bool get isAi => sender == Sender.ai;
}
