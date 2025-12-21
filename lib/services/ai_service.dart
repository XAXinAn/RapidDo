import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:jisu_calendar/common/constants/api_constants.dart';
import 'package:jisu_calendar/common/models/api_response.dart';
import 'package:jisu_calendar/features/ai/models/chat_message.dart';
import 'package:jisu_calendar/features/ai/models/chat_session.dart';
import 'package:jisu_calendar/services/api_service.dart';

/// AI 聊天服务
/// 
/// ## API 接口说明
/// 
/// ### 1. 获取会话列表
/// - **请求**: `GET /ai/sessions`
/// - **请求头**: `Authorization: Bearer {accessToken}`
/// - **响应**:
/// ```json
/// {
///   "code": 200,
///   "message": "获取成功",
///   "data": [
///     {
///       "sessionId": "session-uuid-1",
///       "title": "今天的天气如何",
///       "status": 1,
///       "messageCount": 5,
///       "createdAt": "2025-12-17T10:00:00",
///       "lastMessageAt": "2025-12-17T10:30:00"
///     }
///   ]
/// }
/// ```
/// 
/// ### 2. 创建新会话
/// - **请求**: `POST /ai/sessions`
/// - **请求头**: `Authorization: Bearer {accessToken}`
/// - **请求体**: (空)
/// - **响应**:
/// ```json
/// {
///   "code": 200,
///   "message": "创建成功",
///   "data": {
///     "sessionId": "new-session-uuid",
///     "title": "新对话",
///     "status": 1,
///     "messageCount": 0,
///     "createdAt": "2025-12-17T12:00:00"
///   }
/// }
/// ```
/// 
/// ### 3. 发送消息 (SSE 流式响应)
/// - **请求**: `POST /ai/sessions/{sessionId}/messages`
/// - **请求头**: 
///   - `Authorization: Bearer {accessToken}`
///   - `Accept: text/event-stream`
/// - **请求体**:
/// ```json
/// {
///   "content": "用户消息内容"
/// }
/// ```
/// - **响应**: SSE 流式数据
/// ```
/// data: {"content": "你", "done": false}
/// data: {"content": "好", "done": false}
/// data: {"content": "！", "done": false}
/// data: {"content": "", "done": true, "messageId": "msg-uuid", "tokensUsed": 150}
/// ```
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  final ApiService _apiService = ApiService();

  AiService._internal();

  /// 获取会话列表
  /// 
  /// **请求参数**: 无
  /// 
  /// **返回**: `ApiResponse<List<ChatSession>>`
  /// - `success`: 是否成功
  /// - `message`: 提示信息
  /// - `data`: 会话列表
  Future<ApiResponse<List<ChatSession>>> getSessions() async {
    try {
      final response = await _apiService.get<List<ChatSession>>(
        ApiConstants.aiSessions,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<List<ChatSession>>(
        success: false,
        message: '获取会话列表失败: $e',
      );
    }
  }

  /// 创建新会话
  /// 
  /// **请求参数**: 无
  /// 
  /// **返回**: `ApiResponse<ChatSession>`
  /// - `success`: 是否成功
  /// - `message`: 提示信息
  /// - `data`: 新创建的会话
  Future<ApiResponse<ChatSession>> createSession() async {
    try {
      final response = await _apiService.post<ChatSession>(
        ApiConstants.aiSessions,
        fromJson: (data) => ChatSession.fromJson(data as Map<String, dynamic>),
      );
      return response;
    } catch (e) {
      return ApiResponse<ChatSession>(
        success: false,
        message: '创建会话失败: $e',
      );
    }
  }

  /// 发送消息并流式接收 AI 回复
  /// 
  /// **请求参数**:
  /// - `sessionId`: 会话 ID
  /// - `message`: 用户消息内容
  /// - `title`: 会话标题（可选，用于新会话时设置标题）
  /// 
  /// **返回**: `Stream<AiStreamEvent>`
  /// - `AiStreamEvent.content`: 流式返回的文本片段
  /// - `AiStreamEvent.done`: 完成事件，包含 messageId 和 tokensUsed
  /// - `AiStreamEvent.error`: 错误事件
  Stream<AiStreamEvent> sendMessage({
    required String sessionId,
    required String message,
    String? title,
  }) async* {
    try {
      final tSendStart = DateTime.now().millisecondsSinceEpoch;
      final dio = _apiService.dio;
      final accessToken = await _apiService.getAccessToken();

      // 构建请求体
      final requestData = <String, dynamic>{'content': message};
      if (title != null && title.isNotEmpty) {
        requestData['title'] = title;
      }

      final response = await dio.post<ResponseBody>(
        ApiConstants.aiSessionMessages(sessionId),
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
          // SSE 流式请求需要更长的超时时间
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final tConnected = DateTime.now().millisecondsSinceEpoch;
      print('ai_timing: connected=${tConnected - tSendStart}ms');

      final stream = response.data?.stream;
      if (stream == null) {
        yield AiStreamEvent.error('响应流为空');
        return;
      }

      // 解析 SSE 流
      var firstTokenLogged = false;
      String buffer = '';
      await for (final chunk in stream) {
        final decoded = utf8.decode(chunk);
        buffer += decoded;
        
        // 按行分割，处理完整的 SSE 事件
        final lines = buffer.split('\n');
        buffer = lines.last; // 保留未完成的行
        
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data:')) {
            // 兼容 "data: " 和 "data:" 两种格式
            final jsonStr = line.startsWith('data: ') 
                ? line.substring(6) 
                : line.substring(5);
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
            
            try {
              final data = json.decode(jsonStr) as Map<String, dynamic>;
              final content = data['content'] as String? ?? '';
              final done = data['done'] as bool? ?? false;
              
              if (done) {
                final now = DateTime.now().millisecondsSinceEpoch;
                print('ai_timing: done=${now - tSendStart}ms');
                yield AiStreamEvent.done(
                  sessionId: data['sessionId'] as String?,
                  messageId: data['messageId'] as String?,
                  tokensUsed: data['tokensUsed'] as int?,
                );
              } else if (content.isNotEmpty) {
                if (!firstTokenLogged) {
                  firstTokenLogged = true;
                  final now = DateTime.now().millisecondsSinceEpoch;
                  print('ai_timing: first_token=${now - tSendStart}ms');
                }
                yield AiStreamEvent.content(content);
              }
            } catch (e) {
              // JSON 解析错误，跳过该行
            }
          }
        }
      }
      
      // 处理缓冲区中剩余的数据
      if (buffer.trim().startsWith('data: ')) {
        final jsonStr = buffer.trim().substring(6);
        if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
          try {
            final data = json.decode(jsonStr) as Map<String, dynamic>;
            final content = data['content'] as String? ?? '';
            final done = data['done'] as bool? ?? false;
            
            if (done) {
              yield AiStreamEvent.done(
                sessionId: data['sessionId'] as String?,
                messageId: data['messageId'] as String?,
                tokensUsed: data['tokensUsed'] as int?,
              );
            } else if (content.isNotEmpty) {
              yield AiStreamEvent.content(content);
            }
          } catch (e) {
            print('SSE 最终解析错误: $e');
          }
        }
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?.toString() ?? e.message ?? '网络错误';
      yield AiStreamEvent.error(errorMsg);
    } catch (e) {
      yield AiStreamEvent.error('发送消息失败: $e');
    }
  }

  /// 获取会话历史消息
  /// 
  /// **请求**: `GET /ai/sessions/{sessionId}/messages`
  /// 
  /// **返回**: `ApiResponse<List<ChatMessage>>`
  Future<ApiResponse<List<ChatMessage>>> getSessionMessages(String sessionId) async {
    try {
      final response = await _apiService.get<List<ChatMessage>>(
        ApiConstants.aiSessionMessages(sessionId),
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // 兼容 {messages: [...]} 格式
          if (data is Map && data['messages'] != null) {
            return (data['messages'] as List)
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<List<ChatMessage>>(
        success: false,
        message: '获取消息历史失败: $e',
      );
    }
  }
}

/// AI 流式响应事件
sealed class AiStreamEvent {
  const AiStreamEvent();

  /// 内容片段事件
  factory AiStreamEvent.content(String text) = AiContentEvent;

  /// 完成事件
  factory AiStreamEvent.done({String? sessionId, String? messageId, int? tokensUsed}) = AiDoneEvent;

  /// 错误事件
  factory AiStreamEvent.error(String message) = AiErrorEvent;
}

/// AI 内容片段事件
class AiContentEvent extends AiStreamEvent {
  final String text;
  const AiContentEvent(this.text);
}

/// AI 完成事件
class AiDoneEvent extends AiStreamEvent {
  final String? sessionId;
  final String? messageId;
  final int? tokensUsed;
  const AiDoneEvent({this.sessionId, this.messageId, this.tokensUsed});
}

/// AI 错误事件
class AiErrorEvent extends AiStreamEvent {
  final String message;
  const AiErrorEvent(this.message);
}
