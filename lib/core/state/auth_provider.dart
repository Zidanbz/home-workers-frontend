import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // opsional: untuk debug/snackbar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_service.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import '../services/realtime_notification_service.dart';
import '../../shared_widgets/hint_system.dart';

/// Layar auth apa yang ingin ditampilkan root widget.
enum AuthScreen { welcome, login, register }

/// Hasil login: dipakai UI untuk memutuskan arah navigasi.
class AuthLoginResult {
  final bool success;
  final bool requireEmailVerification;
  final User user;
  final String idToken; // Bearer ke backend
  final String customToken; // Untuk Firebase sign-in

  AuthLoginResult({
    required this.success,
    required this.requireEmailVerification,
    required this.user,
    required this.idToken,
    required this.customToken,
  });
}

class AuthProvider with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  final ApiService _apiService = ApiService();
  final SecureStorageService _storageService = SecureStorageService();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  User? _user;
  String?
  _token; // idToken dari backend (Firebase ID token). Dipakai untuk API bearer.
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  AuthScreen _authScreen = AuthScreen.welcome;

  // flag internal: apakah login terakhir butuh verifikasi email
  bool _lastLoginRequiresEmailVerification = false;

  AuthProvider() {
    initializeApp();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  AuthScreen get authScreen => _authScreen;
  bool get lastLoginRequiresEmailVerification =>
      _lastLoginRequiresEmailVerification;

  // ---------------------------------------------------------------------------
  // Init / Auto Login
  // ---------------------------------------------------------------------------
  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    final storedToken = await _storageService.readToken();
    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      try {
        final userProfile = await _apiService.getMyProfile(storedToken);
        print(userProfile);
        _user = userProfile;
        _token = storedToken;

        // Fetch avatar after getting user profile
        await getAvatar();
      } catch (_) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final storedToken = await _storageService.readToken();

    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      try {
        final userProfile = await _apiService.getMyProfile(storedToken);
        _user = userProfile;
        _token = storedToken;

        // Fetch avatar after getting user profile
        await getAvatar();
      } catch (_) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // UI State Switchers
  // ---------------------------------------------------------------------------
  void showLoginPage() {
    _authScreen = AuthScreen.login;
    notifyListeners();
  }

  void showWelcomePage() {
    _authScreen = AuthScreen.welcome;
    notifyListeners();
  }

  void showRegisterPage() {
    _authScreen = AuthScreen.register;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LOGIN (backend + Firebase via custom token)
  // ---------------------------------------------------------------------------
  Future<AuthLoginResult> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final resolvedFcm =
          fcmToken ?? await FirebaseMessaging.instance.getToken();

      // Hit backend, dapatkan seluruh body respons
      final responseBody = await _apiService.loginUser(
        email: email,
        password: password,
        fcmToken: resolvedFcm,
      );

      // ================== PERUBAHAN UTAMA DI SINI ==================

      // 1. Ambil object 'data' dari dalam respons body
      final Map<String, dynamic>? data = responseBody['data'];

      // 2. Tambahkan pengecekan untuk memastikan object 'data' ada
      if (data == null) {
        throw Exception(
          'Struktur respons dari backend tidak valid (field "data" tidak ditemukan).',
        );
      }

      // 3. Ambil semua value dari dalam 'data', bukan dari level atas lagi
      final String? customToken = data['customToken'];
      final String? idToken = data['idToken'];
      final Map<String, dynamic>? userJson = data['user'];
      final bool requireEmailVerification =
          data['requireEmailVerification'] ?? false;

      // ===============================================================

      if (customToken == null || idToken == null || userJson == null) {
        throw Exception('Respons dari backend tidak lengkap.');
      }

      // Sign in ke Firebase client pakai custom token
      await _signInFirebaseWithCustomTokenIfNeeded(customToken);

      // Update state
      _user = User.fromJson(userJson);
      _token = idToken;
      _lastLoginRequiresEmailVerification = requireEmailVerification;

      // Simpan token + role ke storage
      await _storageService.saveTokenAndRole(token: _token!, role: _user!.role);

      // notifyListeners();

      return AuthLoginResult(
        success: true,
        requireEmailVerification: requireEmailVerification,
        user: _user!,
        idToken: _token!,
        customToken: customToken,
      );
    } catch (e) {
      _lastLoginRequiresEmailVerification = false;
      // Jangan notifyListeners() di sini agar error bisa di-handle UI
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign-in Firebase hanya jika belum ada user aktif.
  Future<void> _signInFirebaseWithCustomTokenIfNeeded(
    String customToken,
  ) async {
    final current = fba.FirebaseAuth.instance.currentUser;
    if (current != null) return;
    await fba.FirebaseAuth.instance.signInWithCustomToken(customToken);
    debugPrint('Firebase sign-in success (custom token).');
  }

  // ---------------------------------------------------------------------------
  // REGISTER CUSTOMER (no auto-login)
  // ---------------------------------------------------------------------------
  Future<void> registerCustomer({
    required String email,
    required String password,
    required String nama,
    String? fcmToken,
  }) async {
    try {
      String? resolvedFcm; // Deklarasikan di sini

      try {
        // Coba dapatkan token
        resolvedFcm = fcmToken ?? await FirebaseMessaging.instance.getToken();
      } catch (e) {
        // Jika gagal, biarkan resolvedFcm null dan cetak pesan error
        debugPrint(
          'PERINGATAN: Gagal mendapatkan FCM token. Melanjutkan tanpa token. Error: $e',
        );
        resolvedFcm = null;
      }

      await _apiService.registerCustomer(
        email: email,
        password: password,
        nama: nama,
        fcmToken:
            resolvedFcm, // Kirim token jika berhasil, atau null jika gagal
      );
    } catch (e) {
      debugPrint('Error registerCustomer: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTER WORKER (no auto-login)
  // ---------------------------------------------------------------------------
  Future<void> registerWorker({
    required String email,
    required String password,
    required String nama,
    required List<String> keahlian,
    required String deskripsi,
    required File ktpFile,
    required File fotoDiriFile,
    String? portfolioLink,
    required String noKtp,
    String? fcmToken,
  }) async {
    try {
      final resolvedFcm =
          fcmToken ?? await FirebaseMessaging.instance.getToken();
      await _apiService.registerWorker(
        email: email,
        password: password,
        nama: nama,
        keahlian: keahlian,
        deskripsi: deskripsi,
        ktpFile: ktpFile,
        fotoDiriFile: fotoDiriFile,
        portfolioLink: portfolioLink,
        noKtp: noKtp,
        fcmToken: resolvedFcm,
      );
    } catch (e) {
      debugPrint('Error registerWorker: $e');
      rethrow;
    }
  }

  Future<AuthLoginResult> loginAndGetData({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final resolvedFcm =
          fcmToken ?? await FirebaseMessaging.instance.getToken();
      final responseBody = await _apiService.loginUser(
        email: email,
        password: password,
        fcmToken: resolvedFcm,
      );

      final Map<String, dynamic>? data = responseBody['data'];
      if (data == null) {
        throw Exception('Struktur respons dari backend tidak valid.');
      }

      final user = User.fromJson(data['user']);
      final requireEmailVerification =
          data['requireEmailVerification'] ?? false;

      // Fungsi ini HANYA mengembalikan data, tidak mengubah state provider
      return AuthLoginResult(
        success: true,
        requireEmailVerification: requireEmailVerification,
        user: user,
        idToken: data['idToken'],
        customToken: data['customToken'],
      );
    } catch (e) {
      rethrow;
    }
  }

  // FUNGSI BARU (untuk memproses data login dan mengubah state)
  Future<void> processLoginSuccess(AuthLoginResult loginResult) async {
    _user = loginResult.user;
    _token = loginResult.idToken;
    _lastLoginRequiresEmailVerification = loginResult.requireEmailVerification;

    await _signInFirebaseWithCustomTokenIfNeeded(loginResult.customToken);
    await _storageService.saveTokenAndRole(token: _token!, role: _user!.role);

    // Fetch avatar after successful login
    await getAvatar();

    // ✅ TAMBAHAN: Start real-time notification listener (dengan error handling yang lebih baik)
    _startRealtimeNotifications();

    // Sekarang, baru kita beritahu seluruh aplikasi bahwa login benar-benar selesai
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Hint System Integration
  // ---------------------------------------------------------------------------

  /// Show first login hint if needed (call this from UI after successful login)
  Future<void> showFirstLoginHintIfNeeded(BuildContext context) async {
    try {
      if (await HintSystem.shouldShowFirstLoginHint()) {
        // Add a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          await HintSystem.showFirstLoginHint(context);
        }
      }
    } catch (e) {
      debugPrint('Error showing first login hint: $e');
    }
  }

  /// Show address hint if needed (call this from dashboard or profile)
  Future<void> showAddressHintIfNeeded(BuildContext context) async {
    try {
      if (await HintSystem.shouldShowAddressHint()) {
        // Add a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          await HintSystem.showAddressHint(context);
        }
      }
    } catch (e) {
      debugPrint('Error showing address hint: $e');
    }
  }

  /// Start real-time notifications (non-blocking)
  void _startRealtimeNotifications() {
    // Jalankan secara asynchronous tanpa menunggu hasil
    // Agar tidak memblokir proses login
    Future.microtask(() async {
      try {
        // Pastikan service sudah diinisialisasi
        if (!RealtimeNotificationService().isInitialized) {
          await RealtimeNotificationService.initialize();
        }

        final notificationService = RealtimeNotificationService();
        await notificationService.startListening(_user!.uid, _token);

        // Subscribe to topics based on user role
        await notificationService.subscribeToTopic(
          _user!.role.toLowerCase(),
        ); // 'customer', 'worker'
        await notificationService.subscribeToTopic(
          'all',
        ); // For broadcast notifications

        debugPrint(
          '✅ [_startRealtimeNotifications] Real-time notifications started successfully',
        );
      } catch (e) {
        debugPrint(
          '❌ [_startRealtimeNotifications] Failed to start real-time notifications: $e',
        );
        // Tidak throw error agar tidak mengganggu login
      }
    });
  }

  // ---------------------------------------------------------------------------
  // CHECK EMAIL VERIFICATION (call backend /me)
  // ---------------------------------------------------------------------------
  Future<bool> checkEmailVerification() async {
    if (_token == null) return false;
    try {
      final updatedUser = await _apiService.getMyProfile(_token!);
      final verified = updatedUser.emailVerified;
      _user = updatedUser;
      notifyListeners();
      return verified;
    } catch (e) {
      debugPrint('Gagal cek verifikasi email: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // RESEND EMAIL VERIFICATION
  // ---------------------------------------------------------------------------
  Future<void> resendEmailVerification() async {
    final email = _user?.email;
    if (email == null) throw Exception('Tidak ada email pengguna.');
    try {
      // Jika endpoint kamu butuh auth, ganti token: _token!
      await _apiService.resendVerificationEmail(
        email: email,
        token: _token ?? '',
      );
    } catch (e) {
      debugPrint('Gagal resend verifikasi email: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sync FCM Token
  // ---------------------------------------------------------------------------
  Future<void> syncFcmToken(String fcmToken) async {
    if (!isLoggedIn || _token == null) return;
    try {
      await _apiService.updateFcmToken(token: _token!, fcmToken: fcmToken);
    } catch (e) {
      debugPrint('Gagal sync FCM token: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Avatar Management
  // ---------------------------------------------------------------------------

  /// Get user avatar from backend
  Future<String?> getAvatar() async {
    final tkn = _token;
    if (tkn == null) {
      throw Exception('No user logged in.');
    }
    try {
      final avatarUrl = await _apiService.getAvatar(tkn);
      // Update user state if avatar is different
      if (_user != null && _user!.avatarUrl != avatarUrl) {
        _user = _user!.copyWith(avatarUrl: avatarUrl);
        notifyListeners();
      }
      return avatarUrl;
    } catch (e) {
      debugPrint('Failed to get avatar: $e');
      return null;
    }
  }

  /// Change/Update user avatar
  Future<void> changeAvatar(String storageDownloadUrl) async {
    final tkn = _token;
    if (_user == null || tkn == null) {
      throw Exception('No user logged in.');
    }
    await _apiService.updateAvatar(token: tkn, avatarUrl: storageDownloadUrl);
    _user = _user!.copyWith(avatarUrl: storageDownloadUrl);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Refresh User Data
  // ---------------------------------------------------------------------------
  Future<void> refreshUserData() async {
    if (_token == null) return;
    try {
      final updatedUser = await _apiService.getMyProfile(_token!);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal refresh user: $e');
      await logout();
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    // ✅ TAMBAHAN: Stop real-time notification listener
    try {
      final notificationService = RealtimeNotificationService();
      await notificationService.stopListening();
      debugPrint('✅ [logout] Real-time notifications stopped successfully');
    } catch (e) {
      debugPrint('❌ [logout] Failed to stop real-time notifications: $e');
    }

    try {
      await fba.FirebaseAuth.instance.signOut();
      debugPrint('Firebase signOut success.');
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }

    _user = null;
    _token = null;
    _lastLoginRequiresEmailVerification = false;
    _authScreen = AuthScreen.welcome;
    await _storageService.deleteAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Forgot Password
  // ---------------------------------------------------------------------------
  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  // ---------------------------------------------------------------------------
  // Reset Password
  // ---------------------------------------------------------------------------
  Future<void> resetPassword({
    required String oobCode,
    required String newPassword,
  }) async {
    await _apiService.resetPassword(oobCode: oobCode, newPassword: newPassword);
  }
}
