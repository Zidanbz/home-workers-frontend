import '../services/encryption_service.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isEncrypted;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.isEncrypted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final encryptionService = EncryptionService();
    final isEncrypted = json['isEncrypted'] ?? false;
    String messageText = json['text'] ?? '';

    // Decrypt message if it's encrypted
    if (isEncrypted && messageText.isNotEmpty) {
      try {
        messageText = encryptionService.decryptText(messageText);
      } catch (e) {
        print('❌ [Message] Failed to decrypt message: $e');
        messageText = '[Pesan tidak dapat didekripsi]';
      }
    }

    return Message(
      id: json['id'],
      text: messageText,
      senderId: json['senderId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp']['_seconds'] * 1000,
      ),
      isEncrypted: isEncrypted,
    );
  }

  /// Convert message to JSON for sending to backend
  Map<String, dynamic> toJson({bool encrypt = true}) {
    final encryptionService = EncryptionService();
    String messageText = text;

    // Encrypt message if requested
    if (encrypt && text.isNotEmpty) {
      try {
        messageText = encryptionService.encryptText(text);
      } catch (e) {
        print('❌ [Message] Failed to encrypt message: $e');
        // Send unencrypted if encryption fails
        encrypt = false;
      }
    }

    return {'text': messageText, 'isEncrypted': encrypt};
  }
}
