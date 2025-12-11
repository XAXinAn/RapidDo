import 'package:jisu_calendar/features/ai/models/chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}
