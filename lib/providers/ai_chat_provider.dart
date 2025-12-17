import 'package:flutter/foundation.dart';
import 'package:jisu_calendar/features/ai/models/chat_message.dart';
import 'package:jisu_calendar/features/ai/models/chat_session.dart';
import 'package:jisu_calendar/services/ai_service.dart';
import 'package:uuid/uuid.dart';

/// AI 聊天状态管理
/// 
/// ## 状态说明
/// - `sessions`: 所有会话列表
/// - `currentSession`: 当前活跃会话
/// - `isLoading`: 是否正在加载会话列表
/// - `isStreaming`: 是否正在流式接收 AI 回复
/// - `error`: 错误信息
/// 
/// ## 使用方式
/// ```dart
/// // 在 Widget 中监听状态
/// final provider = context.watch<AiChatProvider>();
/// 
/// // 加载会话列表
/// provider.loadSessions();
/// 
/// // 创建新会话
/// provider.createNewSession();
/// 
/// // 切换会话
/// provider.switchSession(sessionId);
/// 
/// // 发送消息
/// provider.sendMessage('你好');
/// ```
class AiChatProvider with ChangeNotifier {
  final AiService _aiService = AiService();
  final Uuid _uuid = const Uuid();

  /// 所有会话列表
  List<ChatSession> _sessions = [];
  List<ChatSession> get sessions => _sessions;

  /// 当前活跃会话
  ChatSession? _currentSession;
  ChatSession? get currentSession => _currentSession;

  /// 是否正在加载会话列表
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 是否正在流式接收 AI 回复
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  /// 错误信息
  String? _error;
  String? get error => _error;

  /// 当前消息列表（当前会话的消息）
  List<ChatMessage> get messages => _currentSession?.messages ?? [];

  /// 加载会话列表
  /// 
  /// **API**: `GET /ai/sessions`
  /// 
  /// **响应处理**:
  /// - 成功: 更新 `sessions` 列表
  /// - 失败: 静默处理，不影响用户使用
  /// - 如果没有会话，自动创建一个默认会话
  Future<void> loadSessions() async {
    // 先创建本地会话，让用户能立即使用
    if (_currentSession == null) {
      _createLocalSession();
      notifyListeners();
    }

    // 后台异步加载会话列表，不阻塞用户操作
    try {
      final response = await _aiService.getSessions();

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        _sessions = response.data!;
        // 如果当前会话是临时创建的（还没有消息），切换到服务器上的第一个会话
        if (_currentSession != null && _currentSession!.messages.isEmpty) {
          _currentSession = _sessions.first;
          // 加载当前会话的消息
          await _loadCurrentSessionMessages();
        } else if (_currentSession != null) {
          // 确保当前会话在列表中
          final exists = _sessions.any((s) => s.id == _currentSession!.id);
          if (!exists) {
            _sessions.insert(0, _currentSession!);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      // 网络错误时静默处理，用户可以继续使用本地会话
      print('加载会话列表失败（静默处理）: $e');
    }
  }

  /// 创建新会话
  /// 
  /// **API**: `POST /ai/sessions`
  /// 
  /// **响应处理**:
  /// - 成功: 创建新会话并设为当前会话
  /// - 失败: 本地创建临时会话
  Future<void> createNewSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _aiService.createSession();

      if (response.success && response.data != null) {
        final newSession = response.data!;
        _sessions.insert(0, newSession);
        _currentSession = newSession;
        _error = null;
      } else {
        // API 失败时本地创建临时会话
        _createLocalSession();
      }
    } catch (e) {
      // 网络错误时本地创建临时会话
      _createLocalSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 本地创建临时会话
  void _createLocalSession() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: '新对话',
      messages: [],
    );
    _sessions.insert(0, newSession);
    _currentSession = newSession;
  }

  /// 切换会话
  /// 
  /// **参数**:
  /// - `sessionId`: 目标会话 ID
  /// 
  /// **行为**: 
  /// - 切换到指定会话
  /// - 加载该会话的历史消息
  Future<void> switchSession(String sessionId) async {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _sessions.isNotEmpty 
          ? _sessions.first 
          : ChatSession(id: '', title: '', messages: []),
    );
    
    if (session.id.isEmpty) return;

    _currentSession = session;
    notifyListeners();

    // 如果消息列表为空，尝试从服务器加载
    if (session.messages.isEmpty) {
      await _loadCurrentSessionMessages();
    }
  }

  /// 加载当前会话的历史消息
  Future<void> _loadCurrentSessionMessages() async {
    if (_currentSession == null || _currentSession!.id.isEmpty) return;

    try {
      final response = await _aiService.getSessionMessages(_currentSession!.id);
      
      if (response.success && response.data != null) {
        // 更新当前会话的消息列表
        final updatedSession = ChatSession(
          id: _currentSession!.id,
          userId: _currentSession!.userId,
          title: _currentSession!.title,
          status: _currentSession!.status,
          messageCount: response.data!.length,
          messages: response.data!,
          createdAt: _currentSession!.createdAt,
          updatedAt: _currentSession!.updatedAt,
          lastMessageAt: _currentSession!.lastMessageAt,
        );
        
        // 更新 sessions 列表中的会话
        final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
        if (index >= 0) {
          _sessions[index] = updatedSession;
        }
        _currentSession = updatedSession;
        notifyListeners();
      }
    } catch (e) {
      print('加载会话消息失败: $e');
    }
  }

  /// 发送消息
  /// 
  /// **参数**:
  /// - `text`: 用户消息内容
  /// 
  /// **API**: `POST /ai/sessions/{sessionId}/messages`
  /// 
  /// **请求体**:
  /// ```json
  /// {
  ///   "content": "用户消息内容"
  /// }
  /// ```
  /// 
  /// **SSE 响应处理**:
  /// - `content` 事件: 追加到 AI 回复消息
  /// - `done` 事件: 标记流式接收完成
  /// - `error` 事件: 设置错误信息
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_currentSession == null) {
      _error = '请先创建或选择一个对话';
      notifyListeners();
      return;
    }

    // 判断是否是新会话的第一条消息（在添加消息之前判断）
    final isFirstMessage = _currentSession!.messages.isEmpty && _currentSession!.title == '新对话';

    // 添加用户消息到当前会话
    final userMessage = ChatMessage.user(text);
    _addMessageToCurrentSession(userMessage);

    // 创建空的 AI 回复消息（用于流式更新）
    final aiMessage = ChatMessage.assistant('');
    _addMessageToCurrentSession(aiMessage);

    _isStreaming = true;
    _error = null;
    notifyListeners();

    try {
      String fullContent = '';
      
      // 如果是新会话的第一条消息，生成标题传给后端
      String? title;
      if (isFirstMessage) {
        // 使用 runes 安全截取前8个字符作为标题
        final runes = text.runes.toList();
        title = runes.length > 8
            ? '${String.fromCharCodes(runes.take(8))}...'
            : text;
        print('🏷️ 发送标题: $title');
      }
      
      await for (final event in _aiService.sendMessage(
        sessionId: _currentSession!.id,
        message: text,
        title: title,
      )) {
        switch (event) {
          case AiContentEvent(:final text):
            // 追加内容到 AI 回复
            fullContent += text;
            _updateLastAiMessage(fullContent);
            
          case AiDoneEvent(:final sessionId):
            // 流式接收完成
            // 如果后端返回了新的 sessionId，更新当前会话
            if (sessionId != null && sessionId != _currentSession!.id) {
              _updateCurrentSessionId(sessionId);
            }
            _isStreaming = false;
            notifyListeners();
            
          case AiErrorEvent(:final message):
            // 处理错误
            _error = message;
            _isStreaming = false;
            // 移除空的 AI 回复消息
            if (fullContent.isEmpty) {
              _removeLastMessage();
            }
            notifyListeners();
        }
      }
      
      // 更新会话标题（如果是第一条消息）
      if (_currentSession!.messageCount <= 2 && _currentSession!.title == '新对话') {
        _updateSessionTitle(text);
      }
    } catch (e) {
      _error = '发送消息失败: $e';
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// 添加消息到当前会话
  void _addMessageToCurrentSession(ChatMessage message) {
    if (_currentSession == null) return;

    final updatedMessages = [..._currentSession!.messages, message];
    _currentSession = ChatSession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      title: _currentSession!.title,
      status: _currentSession!.status,
      messageCount: updatedMessages.length,
      messages: updatedMessages,
      createdAt: _currentSession!.createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    // 更新 sessions 列表
    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index >= 0) {
      _sessions[index] = _currentSession!;
    }

    notifyListeners();
  }

  /// 更新最后一条 AI 消息的内容（用于流式更新）
  void _updateLastAiMessage(String content) {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    final lastIndex = messages.length - 1;
    
    if (messages[lastIndex].sender == Sender.ai) {
      messages[lastIndex] = ChatMessage(
        id: messages[lastIndex].id,
        sessionId: messages[lastIndex].sessionId,
        text: content,
        sender: Sender.ai,
        tokensUsed: messages[lastIndex].tokensUsed,
        sequenceNum: messages[lastIndex].sequenceNum,
        createdAt: messages[lastIndex].createdAt,
      );

      _currentSession = ChatSession(
        id: _currentSession!.id,
        userId: _currentSession!.userId,
        title: _currentSession!.title,
        status: _currentSession!.status,
        messageCount: messages.length,
        messages: messages,
        createdAt: _currentSession!.createdAt,
        updatedAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      // 更新 sessions 列表
      final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (index >= 0) {
        _sessions[index] = _currentSession!;
      }

      notifyListeners();
    }
  }

  /// 移除最后一条消息
  void _removeLastMessage() {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages.removeLast();

    _currentSession = ChatSession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      title: _currentSession!.title,
      status: _currentSession!.status,
      messageCount: messages.length,
      messages: messages,
      createdAt: _currentSession!.createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    notifyListeners();
  }

  /// 更新会话标题（使用用户第一条消息的前8个字符）
  void _updateSessionTitle(String firstMessage) {
    if (_currentSession == null) return;

    // 使用 runes 安全截取，避免截断 emoji 等特殊字符
    final runes = firstMessage.runes.toList();
    final newTitle = runes.length > 8
        ? '${String.fromCharCodes(runes.take(8))}...'
        : firstMessage;

    _currentSession = _currentSession!.withTitle(newTitle);

    // 更新 sessions 列表
    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index >= 0) {
      _sessions[index] = _currentSession!;
    }

    notifyListeners();
  }

  /// 更新当前会话的 ID（当后端自动创建新会话时）
  void _updateCurrentSessionId(String newSessionId) {
    if (_currentSession == null) return;

    final oldId = _currentSession!.id;
    
    // 创建新的会话对象，使用新的 ID
    _currentSession = ChatSession(
      id: newSessionId,
      userId: _currentSession!.userId,
      title: _currentSession!.title,
      status: _currentSession!.status,
      messageCount: _currentSession!.messageCount,
      messages: _currentSession!.messages,
      createdAt: _currentSession!.createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    // 更新 sessions 列表中的会话
    final index = _sessions.indexWhere((s) => s.id == oldId);
    if (index >= 0) {
      _sessions[index] = _currentSession!;
    } else {
      // 如果不在列表中，添加到列表开头
      _sessions.insert(0, _currentSession!);
    }
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _sessions = [];
    _currentSession = null;
    _isLoading = false;
    _isStreaming = false;
    _error = null;
    notifyListeners();
  }
}
