// lib/core/services/secure_storage_service.dart - VERSI LENGKAP & BENAR

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Buat instance dari storage
  final _storage = const FlutterSecureStorage();

  // Kunci yang akan kita gunakan untuk menyimpan data
  static const _keyAuthToken = 'authToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyTokenExpiry = 'tokenExpiry'; // epoch ms
  static const _keyUserRole = 'userRole';

  /// Menyimpan token dan role secara bersamaan.
  Future<void> saveTokenAndRole({
    required String token,
    String? role,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _keyAuthToken, value: token);
    if (role != null) {
      await _storage.write(key: _keyUserRole, value: role);
    }
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(
        key: _keyTokenExpiry,
        value: expiresAt.millisecondsSinceEpoch.toString(),
      );
    }
  }

  /// Membaca token yang tersimpan.
  Future<String?> readToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Membaca refresh token yang tersimpan.
  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Membaca waktu kadaluarsa token (epoch ms).
  Future<DateTime?> readTokenExpiry() async {
    final raw = await _storage.read(key: _keyTokenExpiry);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Membaca role yang tersimpan.
  Future<String?> readRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  /// Menghapus semua data otentikasi (untuk logout).
  Future<void> deleteAll() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiry);
    await _storage.delete(key: _keyUserRole);
  }
}
