import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Generate a secure key from app secret
  static const String _appSecret = 'HomeWorkersApp2024SecureKey!@#';

  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;

  void initialize() {
    // Generate key from app secret
    final keyBytes = sha256.convert(utf8.encode(_appSecret)).bytes;
    _key = Key(Uint8List.fromList(keyBytes));

    // Generate IV from a portion of the key for consistency
    final ivBytes = keyBytes.sublist(0, 16);
    _iv = IV(Uint8List.fromList(ivBytes));

    _encrypter = Encrypter(AES(_key));
  }

  /// Encrypt sensitive text data (like chat messages)
  String encryptText(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ [EncryptionService] Failed to encrypt text: $e');
      rethrow;
    }
  }

  /// Decrypt sensitive text data
  String decryptText(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('❌ [EncryptionService] Failed to decrypt text: $e');
      rethrow;
    }
  }

  /// Encrypt file data (like KTP images)
  Uint8List encryptFileData(Uint8List fileData) {
    try {
      // For large files, we'll use a simple XOR encryption with key rotation
      final keyBytes = _key.bytes;
      final encryptedData = Uint8List(fileData.length);

      for (int i = 0; i < fileData.length; i++) {
        final keyIndex = i % keyBytes.length;
        encryptedData[i] = fileData[i] ^ keyBytes[keyIndex];
      }

      return encryptedData;
    } catch (e) {
      print('❌ [EncryptionService] Failed to encrypt file data: $e');
      rethrow;
    }
  }

  /// Decrypt file data
  Uint8List decryptFileData(Uint8List encryptedData) {
    try {
      // XOR decryption (same as encryption for XOR)
      return encryptFileData(encryptedData);
    } catch (e) {
      print('❌ [EncryptionService] Failed to decrypt file data: $e');
      rethrow;
    }
  }

  /// Generate secure filename for encrypted files
  String generateSecureFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    final hash = sha256.convert(
      utf8.encode('$originalFilename$timestamp$random'),
    );
    final extension = originalFilename.split('.').last;
    return '${hash.toString().substring(0, 16)}_encrypted.$extension';
  }

  /// Hash sensitive data for comparison (like document numbers)
  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data + _appSecret);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
