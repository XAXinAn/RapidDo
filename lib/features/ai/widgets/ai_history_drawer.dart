import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/ai/models/chat_session.dart';

class AiHistoryDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final Function(String) onSessionSelected;
  final VoidCallback onNewChatPressed;

  const AiHistoryDrawer({
    super.key,
    required this.sessions,
    required this.onSessionSelected,
    required this.onNewChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Start New Chat" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.refresh, color: Colors.grey.shade700),
                  label: const Text('开启新对话', style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
                  onPressed: onNewChatPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size.fromHeight(48), // Make button taller
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // "History" Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '历史记录',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              // History List
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final item = sessions[index];
                    return ListTile(
                      title: Text(
                        item.title,
                        style: const TextStyle(color: Colors.black87, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSessionSelected(item.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
