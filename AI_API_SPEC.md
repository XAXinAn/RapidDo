# AI 聊天功能接口规范

> 文档版本: 1.0.0  
> 更新日期: 2025-12-17

---

## 目录

1. [接口概览](#接口概览)
2. [获取会话列表](#1-获取会话列表)
3. [创建新会话](#2-创建新会话)
4. [发送消息（SSE流式）](#3-发送消息sse流式)
5. [获取会话历史消息](#4-获取会话历史消息)
6. [数据模型](#数据模型)
7. [错误码说明](#错误码说明)

---

## 接口概览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 获取会话列表 | GET | `/ai/sessions` | 获取当前用户的所有聊天会话 |
| 创建新会话 | POST | `/ai/sessions` | 创建一个空白的聊天会话 |
| 发送消息 | POST | `/ai/sessions/{sessionId}/messages` | 发送消息并流式返回 AI 回复 |
| 获取历史消息 | GET | `/ai/sessions/{sessionId}/messages` | 获取指定会话的历史消息 |

**Base URL**: `http://10.0.2.2:8080/api`

**通用请求头**:
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

---

## 1. 获取会话列表

### 请求

```http
GET /ai/sessions
Authorization: Bearer {accessToken}
```

### 请求参数

无

### 响应

```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "sessionId": "550e8400-e29b-41d4-a716-446655440000",
      "userId": "user-uuid-123",
      "title": "今天的天气如何",
      "status": 1,
      "messageCount": 5,
      "createdAt": "2025-12-17T10:00:00",
      "updatedAt": "2025-12-17T10:30:00",
      "lastMessageAt": "2025-12-17T10:30:00"
    },
    {
      "sessionId": "550e8400-e29b-41d4-a716-446655440001",
      "userId": "user-uuid-123",
      "title": "帮我写一首诗",
      "status": 1,
      "messageCount": 3,
      "createdAt": "2025-12-16T15:00:00",
      "updatedAt": "2025-12-16T15:20:00",
      "lastMessageAt": "2025-12-16T15:20:00"
    }
  ]
}
```

### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| sessionId | string | 会话唯一标识 (UUID) |
| userId | string | 用户ID |
| title | string | 会话标题（通常为首条消息摘要） |
| status | int | 会话状态：0-已关闭，1-活跃 |
| messageCount | int | 消息总数 |
| createdAt | string | 创建时间 (ISO 8601) |
| updatedAt | string | 更新时间 (ISO 8601) |
| lastMessageAt | string | 最后消息时间 (ISO 8601) |

---

## 2. 创建新会话

### 请求

```http
POST /ai/sessions
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求体

空（无需请求体）

### 响应

```json
{
  "code": 200,
  "message": "创建成功",
  "data": {
    "sessionId": "550e8400-e29b-41d4-a716-446655440002",
    "userId": "user-uuid-123",
    "title": "新对话",
    "status": 1,
    "messageCount": 0,
    "createdAt": "2025-12-17T12:00:00",
    "updatedAt": "2025-12-17T12:00:00",
    "lastMessageAt": null
  }
}
```

---

## 3. 发送消息（SSE流式）

### 请求

```http
POST /ai/sessions/{sessionId}/messages
Authorization: Bearer {accessToken}
Accept: text/event-stream
Content-Type: application/json
```

### 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| sessionId | string | 是 | 会话ID |

### 请求体

```json
{
  "content": "你好，请介绍一下你自己"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| content | string | 是 | 用户消息内容 |

### 响应（SSE 流式）

响应类型为 `text/event-stream`，逐字返回 AI 回复：

```
data: {"content": "你", "done": false}

data: {"content": "好", "done": false}

data: {"content": "！", "done": false}

data: {"content": "我", "done": false}

data: {"content": "是", "done": false}

data: {"content": "极", "done": false}

data: {"content": "速", "done": false}

data: {"content": "精", "done": false}

data: {"content": "灵", "done": false}

data: {"content": "，", "done": false}

data: {"content": "一", "done": false}

data: {"content": "个", "done": false}

data: {"content": "AI", "done": false}

data: {"content": "助", "done": false}

data: {"content": "手", "done": false}

data: {"content": "。", "done": false}

data: {"content": "", "done": true, "sessionId": "550e8400-e29b-41d4-a716-446655440000", "messageId": "msg-uuid-001", "tokensUsed": 150}

```

### SSE 事件字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| content | string | 本次返回的文本片段 |
| done | boolean | 是否完成：false-继续接收，true-完成 |
| sessionId | string | 实际使用的会话ID（仅 done=true 时），当会话不存在时后端会自动创建新会话 |
| messageId | string | 完成时返回的消息ID（仅 done=true 时） |
| tokensUsed | int | 本次对话消耗的 token 数量（仅 done=true 时） |

> **注意**: 当请求的 `sessionId` 不存在时，后端会自动创建新会话，并在完成事件中返回实际的 `sessionId`。前端应使用返回的 `sessionId` 更新本地会话状态。

### 前端处理示例 (Dart)

```dart
Stream<AiStreamEvent> sendMessage({
  required String sessionId,
  required String message,
}) async* {
  final response = await dio.post<ResponseBody>(
    '/ai/sessions/$sessionId/messages',
    data: {'content': message},
    options: Options(
      headers: {'Accept': 'text/event-stream'},
      responseType: ResponseType.stream,
    ),
  );

  String buffer = '';
  await for (final chunk in response.data!.stream) {
    buffer += utf8.decode(chunk);
    
    final lines = buffer.split('\n');
    buffer = lines.last;
    
    for (final line in lines.take(lines.length - 1)) {
      if (line.startsWith('data: ')) {
        final json = jsonDecode(line.substring(6));
        if (json['done'] == true) {
          yield AiStreamEvent.done(
            messageId: json['messageId'],
            tokensUsed: json['tokensUsed'],
          );
        } else {
          yield AiStreamEvent.content(json['content']);
        }
      }
    }
  }
}
```

---

## 4. 获取会话历史消息

### 请求

```http
GET /ai/sessions/{sessionId}/messages
Authorization: Bearer {accessToken}
```

### 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| sessionId | string | 是 | 会话ID |

### 响应

```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "messages": [
      {
        "id": "msg-001",
        "sessionId": "550e8400-e29b-41d4-a716-446655440000",
        "content": "你好，请介绍一下你自己",
        "role": "user",
        "tokensUsed": 10,
        "sequenceNum": 1,
        "createdAt": "2025-12-17T10:00:00"
      },
      {
        "id": "msg-002",
        "sessionId": "550e8400-e29b-41d4-a716-446655440000",
        "content": "你好！我是极速精灵，一个AI助手。我可以帮助你回答问题、提供建议、协助写作等。有什么可以帮助你的吗？",
        "role": "assistant",
        "tokensUsed": 45,
        "sequenceNum": 2,
        "createdAt": "2025-12-17T10:00:05"
      },
      {
        "id": "msg-003",
        "sessionId": "550e8400-e29b-41d4-a716-446655440000",
        "content": "今天天气怎么样？",
        "role": "user",
        "tokensUsed": 8,
        "sequenceNum": 3,
        "createdAt": "2025-12-17T10:01:00"
      },
      {
        "id": "msg-004",
        "sessionId": "550e8400-e29b-41d4-a716-446655440000",
        "content": "抱歉，我目前无法获取实时天气信息。建议你查看天气应用或网站获取最新天气预报。",
        "role": "assistant",
        "tokensUsed": 35,
        "sequenceNum": 4,
        "createdAt": "2025-12-17T10:01:10"
      }
    ]
  }
}
```

### 消息字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 消息唯一标识 |
| sessionId | string | 所属会话ID |
| content | string | 消息内容 |
| role | string | 角色：`user`/`assistant`/`system` |
| tokensUsed | int | 消耗的 token 数量 |
| sequenceNum | int | 消息序号（会话内递增） |
| createdAt | string | 创建时间 (ISO 8601) |

---

## 数据模型

### ChatSession（聊天会话）

```typescript
interface ChatSession {
  sessionId: string;      // 会话唯一ID (UUID)
  userId: string;         // 用户ID
  title: string;          // 会话标题
  status: number;         // 0-已关闭，1-活跃
  messageCount: number;   // 消息总数
  createdAt: string;      // 创建时间
  updatedAt: string;      // 更新时间
  lastMessageAt: string;  // 最后消息时间
}
```

### ChatMessage（聊天消息）

```typescript
interface ChatMessage {
  id: string;             // 消息唯一ID
  sessionId: string;      // 会话ID
  content: string;        // 消息内容
  role: 'user' | 'assistant' | 'system';  // 角色
  tokensUsed: number;     // Token消耗
  sequenceNum: number;    // 消息序号
  createdAt: string;      // 创建时间
}
```

### SSE 流式事件

```typescript
// 内容片段事件
interface ContentEvent {
  content: string;
  done: false;
}

// 完成事件
interface DoneEvent {
  content: '';
  done: true;
  messageId: string;
  tokensUsed: number;
}
```

---

## 错误码说明

| HTTP 状态码 | code | message | 说明 |
|-------------|------|---------|------|
| 200 | 200 | 成功 | 请求成功 |
| 400 | 400 | 参数错误 | 请求参数不合法 |
| 401 | 401 | 未授权 | Token 无效或过期 |
| 403 | 403 | 禁止访问 | 无权访问该资源 |
| 404 | 404 | 会话不存在 | 指定的 sessionId 不存在 |
| 429 | 429 | 请求过于频繁 | 触发速率限制 |
| 500 | 500 | 服务器错误 | 服务端内部错误 |
| 503 | 503 | AI 服务不可用 | AI 服务暂时不可用 |

### 错误响应示例

```json
{
  "code": 401,
  "message": "Token已过期，请重新登录",
  "data": null
}
```

---

## 数据库表结构参考

### chat_sessions 表

```sql
CREATE TABLE chat_sessions (
    session_id VARCHAR(64) PRIMARY KEY COMMENT '会话唯一ID',
    user_id VARCHAR(64) NOT NULL COMMENT '用户ID',
    title VARCHAR(200) DEFAULT '新对话' COMMENT '会话标题',
    status TINYINT DEFAULT 1 COMMENT '0-已关闭，1-活跃',
    message_count INT DEFAULT 0 COMMENT '消息总数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_message_at DATETIME COMMENT '最后消息时间',
    is_deleted TINYINT DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_user_id (user_id),
    INDEX idx_last_message (last_message_at DESC)
);
```

### chat_messages 表

```sql
CREATE TABLE chat_messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(64) NOT NULL COMMENT '会话ID',
    user_id VARCHAR(64) NOT NULL COMMENT '用户ID',
    role ENUM('user', 'assistant', 'system') NOT NULL COMMENT '角色',
    content TEXT NOT NULL COMMENT '消息内容',
    tokens_used INT DEFAULT 0 COMMENT 'Token消耗',
    sequence_num INT NOT NULL COMMENT '消息序号',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_session_id (session_id),
    INDEX idx_sequence (session_id, sequence_num)
);
```

---

## 前端实现文件

| 文件 | 说明 |
|------|------|
| `lib/services/ai_service.dart` | AI 服务类，封装 API 调用 |
| `lib/providers/ai_chat_provider.dart` | 状态管理，管理会话和消息 |
| `lib/features/ai/screens/ai_chat_screen.dart` | 聊天主界面 |
| `lib/features/ai/widgets/ai_history_drawer.dart` | 历史会话侧边栏 |
| `lib/features/ai/models/chat_session.dart` | 会话模型 |
| `lib/features/ai/models/chat_message.dart` | 消息模型 |
