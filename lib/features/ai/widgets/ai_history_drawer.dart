import 'package:flutter/material.dart';
import 'package:jisu_calendar/providers/ai_chat_provider.dart';
import 'package:provider/provider.dart';

class AiHistoryDrawer extends StatelessWidget {
  final Function(String) onSessionSelected;
  final VoidCallback onNewChatPressed;

  const AiHistoryDrawer({
    super.key,
    required this.onSessionSelected,
    required this.onNewChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    final sessions = provider.sessions;
    final isLoading = provider.isLoading;

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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : sessions.isEmpty
                        ? Center(
                            child: Text(
                              '暂无对话记录',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final item = sessions[index];
                              final isSelected = provider.currentSession?.id == item.id;
                              return ListTile(
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: isSelected,
                                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
