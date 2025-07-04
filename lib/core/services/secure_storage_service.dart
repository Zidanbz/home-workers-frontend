// lib/core/services/secure_storage_service.dart - VERSI LENGKAP & BENAR

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Buat instance dari storage
  final _storage = const FlutterSecureStorage();

  // Kunci yang akan kita gunakan untuk menyimpan data
  static const _keyAuthToken = 'authToken';
  static const _keyUserRole = 'userRole';

  /// Menyimpan token dan role secara bersamaan.
  Future<void> saveTokenAndRole({
    required String token,
    required String role,
  }) async {
    await _storage.write(key: _keyAuthToken, value: token);
    await _storage.write(key: _keyUserRole, value: role);
  }

  /// Membaca token yang tersimpan.
  Future<String?> readToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Membaca role yang tersimpan.
  Future<String?> readRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  /// Menghapus semua data otentikasi (untuk logout).
  Future<void> deleteAll() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyUserRole);
  }
}
