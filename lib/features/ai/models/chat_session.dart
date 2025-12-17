import 'package:jisu_calendar/features/ai/models/chat_message.dart';

/// AI 聊天会话模型
/// 对应后端 chat_sessions 表
class ChatSession {
  final String id;
  final String? userId;
  final String title;
  final int status; // 0-已关闭，1-活跃
  final int messageCount;
  final List<ChatMessage> messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  ChatSession({
    required this.id,
    this.userId,
    required this.title,
    this.status = 1,
    this.messageCount = 0,
    required this.messages,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  /// 从后端 JSON 创建
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    List<ChatMessage> messages = [];
    if (json['messages'] != null) {
      messages = (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ChatSession(
      id: json['sessionId'] ?? json['session_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] as String?,
      title: json['title'] as String? ?? '新对话',
      status: json['status'] as int? ?? 1,
      messageCount: json['messageCount'] ?? json['message_count'] ?? messages.length,
      messages: messages,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastMessageAt: json['lastMessageAt'] != null || json['last_message_at'] != null
          ? DateTime.tryParse((json['lastMessageAt'] ?? json['last_message_at']).toString())
          : null,
    );
  }

  /// 转换为后端 JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': id,
      if (userId != null) 'userId': userId,
      'title': title,
      'status': status,
      'messageCount': messageCount,
      if (messages.isNotEmpty) 'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  /// 会话是否活跃
  bool get isActive => status == 1;

  /// 添加消息（返回新的会话对象）
  ChatSession addMessage(ChatMessage message) {
    return ChatSession(
      id: id,
      userId: userId,
      title: title,
      status: status,
      messageCount: messageCount + 1,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
  }

  /// 更新标题
  ChatSession withTitle(String newTitle) {
    return ChatSession(
      id: id,
      userId: userId,
      title: newTitle,
      status: status,
      messageCount: messageCount,
      messages: messages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
    );
  }

  /// 创建空会话
  factory ChatSession.empty({String? userId}) {
    return ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: '新对话',
      messages: [],
      createdAt: DateTime.now(),
    );
  }
}
