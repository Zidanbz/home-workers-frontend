// Lokasi: lib/core/state/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as fba; // Beri alias untuk FirebaseAuth
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum AuthScreen { welcome, login, register }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storageService = SecureStorageService();

  User? _user;
  String? _token; // Ini akan menjadi ID Token, bukan custom token
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  AuthScreen _authScreen = AuthScreen.welcome; // State awal

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  AuthScreen get authScreen => _authScreen;

  AuthProvider() {
    // tryAutoLogin();
    initializeApp();
  }

  Future<void> initializeApp() async {
    // Cek apakah onboarding sudah dilihat
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Coba auto-login
    final storedToken = await _storageService.readToken();
    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      try {
        final userProfile = await _apiService.getMyProfile(storedToken);
        _user = userProfile;
        _token = storedToken;
      } catch (e) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void showLoginPage() {
    _authScreen = AuthScreen.login;
    notifyListeners();
  }

  void showWelcomePage() {
    _authScreen = AuthScreen.welcome;
    notifyListeners();
  }

  // --- FUNGSI LOGIN YANG DIPERBAIKI TOTAL ---
  Future<void> login(String email, String password) async {
    try {
      // Langkah 1: Panggil backend untuk mendapatkan Custom Token
      final result = await _apiService.loginUser(email, password);

      if (result['user'] != null && result['customToken'] != null) {
        final String customToken = result['customToken'];

        // Langkah 2: Login ke Firebase di sisi KLIEN menggunakan Custom Token
        final userCredential = await fba.FirebaseAuth.instance
            .signInWithCustomToken(customToken);
        print("Berhasil login ke Firebase di sisi klien!");

        // Langkah 3: Dapatkan ID Token yang sesungguhnya untuk API call
        final firebaseUser = userCredential.user;
        if (firebaseUser == null)
          throw Exception("Gagal mendapatkan user setelah sign-in.");

        final String? idToken = await firebaseUser.getIdToken();
        if (idToken == null) throw Exception("Gagal mendapatkan ID Token.");

        // Langkah 4: Simpan state dan data ke storage
        _user = User.fromJson(result['user']);
        _token = idToken; // Simpan ID Token, bukan custom token

        await _storageService.saveTokenAndRole(
          token: _token!,
          role: _user!.role,
        );

        notifyListeners();
      } else {
        throw Exception('Invalid server response');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi tryAutoLogin juga perlu disesuaikan
  Future<void> tryAutoLogin() async {
    final storedToken = await _storageService.readToken();

    if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
      try {
        // Karena kita tidak punya custom token di sini, kita perlu login ulang
        // atau memanggil API untuk me-refresh sesi. Untuk saat ini, kita
        // panggil API /me untuk mendapatkan data user.
        final userProfile = await _apiService.getMyProfile(storedToken);
        _user = userProfile;
        _token = storedToken;
      } catch (e) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await fba.FirebaseAuth.instance.signOut(); // Logout dari Firebase client
    _user = null;
    _token = null;
    await _storageService.deleteAll();
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    if (_token != null) {
      try {
        final updatedUser = await _apiService.getMyProfile(_token!);
        _user = updatedUser;
        // Beri tahu UI untuk update dengan data baru
        notifyListeners();
      } catch (e) {
        print("Gagal me-refresh data pengguna: $e");
        // Mungkin token sudah tidak valid, lakukan logout
        logout();
      }
    }
  }
}
