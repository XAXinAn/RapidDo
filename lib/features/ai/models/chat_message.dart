enum Sender {
  user,
  ai,
}

class ChatMessage {
  final String text;
  final Sender sender;

  ChatMessage({required this.text, required this.sender});
}
