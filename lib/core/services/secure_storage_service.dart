// lib/core/services/secure_storage_service.dart - VERSI LENGKAP & BENAR

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // Buat instance dari storage
  final _storage = const FlutterSecureStorage();

  // Kunci yang akan kita gunakan untuk menyimpan data
  static const _keyAuthToken = 'authToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyTokenExpiry = 'tokenExpiry'; // epoch ms
  static const _keyUserRole = 'userRole';
  static const _keyAuthMethod = 'authMethod';
  static const _keyLogoutPending = 'authLogoutPending';

  /// Menyimpan token dan role secara bersamaan.
  Future<void> saveTokenAndRole({
    required String token,
    String? role,
    String? refreshToken,
    DateTime? expiresAt,
    String? authMethod,
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
    if (authMethod != null) {
      await _storage.write(key: _keyAuthMethod, value: authMethod);
    }

    // Sesi baru sudah tersimpan lengkap. Marker ini hanya boleh dibersihkan
    // setelah semua data sesi berhasil ditulis.
    await clearLogoutPending();
  }

  Future<void> saveFirebaseSession({
    required String token,
    required String role,
    required DateTime expiresAt,
  }) async {
    await _storage.delete(key: _keyRefreshToken);
    await saveTokenAndRole(
      token: token,
      role: role,
      expiresAt: expiresAt,
      authMethod: 'google',
    );
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

  Future<String?> readAuthMethod() async {
    return await _storage.read(key: _keyAuthMethod);
  }

  /// Menandai bahwa user sudah memilih logout.
  ///
  /// Marker non-sensitif ini sengaja disimpan di luar secure storage. Jika
  /// Android Keystore macet saat penghapusan token, startup berikutnya tetap
  /// tidak boleh memulihkan sesi lama.
  Future<void> markLogoutPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogoutPending, true);
  }

  Future<bool> isLogoutPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLogoutPending) ?? false;
  }

  Future<void> clearLogoutPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLogoutPending);
  }

  /// Menghapus semua data otentikasi (untuk logout).
  Future<void> deleteAll() async {
    // Hanya SecureStorageService yang memakai FlutterSecureStorage pada app
    // ini. Satu operasi native lebih aman daripada lima operasi berurutan yang
    // dapat meninggalkan sesi terhapus sebagian atau menggantung di tengah.
    await _storage.deleteAll();
    await clearLogoutPending();
  }
}
