# 极速日历 - API 接口文档

**版本:** 1.0.0
**Base URL:** `https://your-api-domain.com/api/v1`

**认证:** 所有需要授权的接口，都需要在请求头（Header）中附带 `Authorization: Bearer <JWT_TOKEN>`。

---

## 1. 认证模块 (Authentication)

### 1.1 请求短信验证码

- **Endpoint:** `POST /auth/sms/request`
- **描述:** 向指定手机号发送一个用于登录或注册的短信验证码。
- **请求体 (Request Body):**
  ```json
  {
    "phoneNumber": "18012345678"
  }
  ```
- **成功响应 (200 OK):**
  ```json
  {
    "success": true,
    "message": "验证码已发送"
  }
  ```
- **失败响应 (400 Bad Request):**
  ```json
  {
    "success": false,
    "message": "无效的手机号码"
  }
  ```

### 1.2 手机号与验证码登录

- **Endpoint:** `POST /auth/sms/login`
- **描述:** 使用手机号和验证码进行登录。如果用户不存在，则自动创建新用户。
- **请求体 (Request Body):**
  ```json
  {
    "phoneNumber": "18012345678",
    "code": "123456"
  }
  ```
- **成功响应 (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "token": "your_jwt_token_here",
      "user": {
        "id": "user_id_abc123",
        "name": "九号线",
        "avatarUrl": "https://example.com/avatar.png"
      }
    }
  }
  ```
- **失败响应 (401 Unauthorized):**
  ```json
  {
    "success": false,
    "message": "验证码错误或已失效"
  }
  ```

---

## 2. 用户模块 (User)

### 2.1 获取用户个人资料

- **Endpoint:** `GET /user/profile`
- **认证:** 需要 Token
- **描述:** 获取当前登录用户的详细个人信息。
- **成功响应 (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "name": "九号线",
      "gender": "男",
      "region": "浙江 台州",
      "phoneNumber": "180****0006",
      "email": "user@example.com",
      "wechatId": "NEWYORK20050304",
      "avatarUrl": "https://example.com/avatar.png",
      "qrCodeUrl": "https://example.com/my_qrcode.png"
    }
  }
  ```

### 2.2 更新用户个人资料

- **Endpoint:** `PUT /user/profile`
- **认证:** 需要 Token
- **描述:** 更新当前登录用户的部分或全部个人信息。
- **请求体 (Request Body):** (只需包含需要更新的字段)
  ```json
  {
    "name": "新名字",
    "region": "上海"
  }
  ```
- **成功响应 (200 OK):** 返回更新后的完整个人信息。
  ```json
  {
    "success": true,
    "data": {
      "name": "新名字",
      "gender": "男",
      "region": "上海",
      // ... 其他字段
    }
  }
  ```

---

## 3. 日程模块 (Schedule)

### 3.1 获取指定日期的日程列表

- **Endpoint:** `GET /schedules?date=YYYY-MM-DD`
- **认证:** 需要 Token
- **描述:** 获取某一天或某个时间范围内的所有日程。
- **查询参数 (Query Parameters):**
  - `date` (必填): `YYYY-MM-DD` 格式的日期。
- **成功响应 (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "schedule_id_1",
        "title": "团队会议",
        "description": "讨论Q3季度规划",
        "startTime": "2024-07-25T10:00:00Z",
        "endTime": "2024-07-25T11:00:00Z",
        "isAllDay": false
      }
    ]
  }
  ```

### 3.2 创建新日程

- **Endpoint:** `POST /schedules`
- **认证:** 需要 Token
- **描述:** 为当前用户创建一个新的日程。
- **请求体 (Request Body):**
  ```json
  {
    "title": "和客户见面",
    "description": "",
    "startTime": "2024-07-25T14:00:00Z",
    "endTime": "2024-07-25T15:00:00Z",
    "isAllDay": false
  }
  ```
- **成功响应 (201 CREATED):** 返回创建成功后的日程信息。

---

## 4. AI 聊天模块 (AI Chat)

### 4.1 获取聊天会话历史

- **Endpoint:** `GET /ai/sessions`
- **认证:** 需要 Token
- **描述:** 获取当前用户的所有聊天会话列表（仅含标题和ID）。
- **成功响应 (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "session_1",
        "title": "关于极速日历"
      },
      {
        "id": "session_2",
        "title": "人物抠图合成"
      }
    ]
  }
  ```

### 4.2 发送消息（并获取回复）

- **Endpoint:** `POST /ai/sessions/{sessionId}/messages`
- **认证:** 需要 Token
- **描述:** 在指定的会话中发送一条新消息，并流式（stream）返回 AI 的回复。
- **路径参数 (Path Parameters):**
  - `sessionId`: 对话的唯一 ID。
- **请求体 (Request Body):**
  ```json
  {
    "text": "你好"
  }
  ```
- **成功响应 (200 OK with Stream):** 服务端应该以流的形式，一块一块地返回 AI 的回复文本。

### 4.3 创建新会话

- **Endpoint:** `POST /ai/sessions`
- **认证:** 需要 Token
- **描述:** 创建一个全新的、空白的聊天会话。
- **成功响应 (201 CREATED):**
  ```json
  {
    "success": true,
    "data": {
      "id": "session_new_abc456",
      "title": "新对话",
      "messages": []
    }
  }
  ```
