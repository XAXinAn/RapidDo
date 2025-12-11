import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jisu_calendar/features/ai/models/chat_message.dart';
import 'package:jisu_calendar/features/ai/models/chat_session.dart';
import 'package:jisu_calendar/features/ai/widgets/ai_history_drawer.dart';
import 'package:uuid/uuid.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Uuid _uuid = const Uuid();
  final TextEditingController _textController = TextEditingController();

  // --- Mock Data for Multiple Sessions ---
  final List<ChatSession> _allSessions = [
    ChatSession(
      id: 'session_1',
      title: '关于极速日历',
      messages: [
        ChatMessage(text: '你好', sender: Sender.user),
        ChatMessage(text: '你好呀！很高兴能帮到你～是关于极速日历的开发有新问题，还是有其他想聊的呢？', sender: Sender.ai),
      ],
    ),
    ChatSession(
      id: 'session_2',
      title: '人物抠图合成',
      messages: [
        ChatMessage(text: '如何用AI实现人物抠图并合成到新背景？', sender: Sender.user),
        ChatMessage(text: '当然，这通常需要用到图像分割技术...', sender: Sender.ai),
      ],
    ),
  ];

  late ChatSession _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = _allSessions.first;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _switchToSession(String sessionId) {
    final session = _allSessions.firstWhere((s) => s.id == sessionId, orElse: () => _currentSession);
    setState(() {
      _currentSession = session;
    });
    Navigator.pop(context); // Close the drawer
  }

  void _startNewChat() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: '新对话',
      messages: [],
    );
    setState(() {
      _allSessions.insert(0, newSession);
      _currentSession = newSession;
    });
    Navigator.pop(context); // Close the drawer
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, sender: Sender.user);

    setState(() {
      _currentSession.messages.add(userMessage);
    });

    _textController.clear();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        final aiResponse = ChatMessage(text: '我收到了你的消息: “$text”', sender: Sender.ai);
        _currentSession.messages.add(aiResponse);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple[50]!,
            Colors.blue[50]!,
            Colors.white,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: _ChatAppBar(
          title: _currentSession.title,
          onHistoryPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width * 2 / 3,
          child: AiHistoryDrawer(
            sessions: _allSessions,
            onSessionSelected: _switchToSession,
            onNewChatPressed: _startNewChat,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _currentSession.messages.length,
                itemBuilder: (context, index) {
                  final message = _currentSession.messages[index];
                  return message.sender == Sender.user
                      ? _UserMessageBubble(message: message)
                      : _AiMessageBubble(message: message);
                },
              ),
            ),
            _AiChatInputBar(controller: _textController, onSendPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onHistoryPressed;

  const _ChatAppBar({required this.title, required this.onHistoryPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black54),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.yellow.shade100,
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: onHistoryPressed),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- Message Bubbles and Input Bar (no changes) ---

class _UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _AiMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8.0, right: 40.0, bottom: 8.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.black, fontSize: 16, height: 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              _ActionButton(icon: Icons.copy_outlined, onTap: () {}),
              _ActionButton(icon: Icons.volume_up_outlined, onTap: () {}),
              _ActionButton(icon: Icons.share_outlined, onTap: () {}),
            ],
          ),
        )
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.grey.shade600, size: 20),
      onPressed: onTap,
    );
  }
}

class _AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;

  const _AiChatInputBar({required this.controller, required this.onSendPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Hero(
                  tag: 'ai-chat-box',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64D8D8), Color(0xFF8A78F2)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28.5),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Icon(Icons.auto_awesome, color: Colors.grey, size: 20),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: '问一问极速精灵...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onSubmitted: (_) => onSendPressed(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.mic_none_outlined, color: Colors.grey),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: onSendPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
