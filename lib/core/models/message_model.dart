class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'] ?? '',
      senderId: json['senderId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp']['_seconds'] * 1000,
      ),
    );
  }

  /// Convert message to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}
