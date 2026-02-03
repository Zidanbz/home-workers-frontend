class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Map && value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseOptionalTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Map && value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Message(
      id: json['id'],
      text: json['text'] ?? '',
      senderId: json['senderId'],
      timestamp: parseTimestamp(json['timestamp']),
      readAt: parseOptionalTimestamp(json['readAt']),
    );
  }

  /// Convert message to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}
