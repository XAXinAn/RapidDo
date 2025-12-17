import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jisu_calendar/features/ai/models/chat_message.dart';
import 'package:jisu_calendar/features/ai/widgets/ai_history_drawer.dart';
import 'package:jisu_calendar/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 加载会话列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiChatProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _switchToSession(String sessionId) {
    context.read<AiChatProvider>().switchSession(sessionId);
    Navigator.pop(context); // Close the drawer
  }

  void _startNewChat() {
    context.read<AiChatProvider>().createNewSession();
    Navigator.pop(context); // Close the drawer
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    
    final provider = context.read<AiChatProvider>();
    if (provider.currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建或选择一个对话')),
      );
      return;
    }

    provider.sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    final currentSession = provider.currentSession;
    final messages = provider.messages;
    final isStreaming = provider.isStreaming;

    // 显示错误信息
    if (provider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
        provider.clearError();
      });
    }

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
          title: currentSession?.title ?? '极速精灵',
          onHistoryPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width * 2 / 3,
          child: AiHistoryDrawer(
            onSessionSelected: _switchToSession,
            onNewChatPressed: _startNewChat,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: currentSession == null || messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            '开始与极速精灵对话',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isLastMessage = index == messages.length - 1;
                        final showStreamingIndicator = isLastMessage && isStreaming && message.sender == Sender.ai;
                        
                        return message.sender == Sender.user
                            ? _UserMessageBubble(message: message)
                            : _AiMessageBubble(
                                message: message,
                                isStreaming: showStreamingIndicator,
                              );
                      },
                    ),
            ),
            _AiChatInputBar(
              controller: _textController,
              onSendPressed: _sendMessage,
              isEnabled: !isStreaming,
            ),
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
  final bool isStreaming;
  const _AiMessageBubble({required this.message, this.isStreaming = false});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  message.text.isEmpty ? '思考中...' : message.text,
                  style: TextStyle(
                    color: message.text.isEmpty ? Colors.grey : Colors.black,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              if (isStreaming) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ],
          ),
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
  final bool isEnabled;

  const _AiChatInputBar({
    required this.controller,
    required this.onSendPressed,
    this.isEnabled = true,
  });

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
                                enabled: isEnabled,
                                decoration: const InputDecoration(
                                  hintText: '问一问极速精灵...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onSubmitted: isEnabled ? (_) => onSendPressed() : null,
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
                color: isEnabled 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey,
                onPressed: isEnabled ? onSendPressed : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
