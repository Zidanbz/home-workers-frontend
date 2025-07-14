// Lokasi: lib/core/state/auth_provider.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as fba; // Beri alias untuk FirebaseAuth
import 'package:google_sign_in/google_sign_in.dart';
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
    // Langkah 1: Panggil backend untuk mendapatkan ID Token dan data user
    final result = await _apiService.loginUser(email, password);

    if (result['user'] != null && result['idToken'] != null) {
      // Gunakan langsung ID Token dari backend
      final String idToken = result['idToken'];

      // (Opsional) Verifikasi token ke Firebase Auth jika perlu, tapi biasanya tidak perlu
      // final userCredential = await fba.FirebaseAuth.instance.signInWithCustomToken(idToken);

      // Simpan state dan data ke storage
      _user = User.fromJson(result['user']);
      _token = idToken;

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

  Future<void> registerCustomer({
    required String email,
    required String password,
    required String nama,
  }) async {
    try {
      final result = await _apiService.registerCustomer(
        email: email,
        password: password,
        nama: nama,
      );

      final data = result['data'];
      if (data == null || data['userId'] == null) {
        throw Exception('Gagal mengambil data user dari server.');
      }

      // Buat User secara manual karena response tidak lengkap
      _user = User(
        uid: data['userId'],
        email: email,
        nama: nama,
        role: 'customer',
      );

      // Jika belum ada token dari backend, bisa kosongkan sementara
      _token = null;

      await _storageService.saveTokenAndRole(
        token: _token ?? '',
        role: _user!.role,
      );
      notifyListeners();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

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
  }) async {
    try {
      final response = await _apiService.registerWorker(
        email: email,
        password: password,
        nama: nama,
        keahlian: keahlian,
        deskripsi: deskripsi,
        ktpFile: ktpFile,
        portfolioLink: portfolioLink,
        noKtp: noKtp,
        fotoDiriFile: fotoDiriFile,
      );

      final user = User.fromJson(response['user']);
      final token = response['idToken'];

      await _storageService.saveTokenAndRole(token: token!, role: user.role);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Future<void> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) throw Exception('Login dibatalkan oleh pengguna');

  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  //     final credential = fba.GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Login ke Firebase Auth
  //     final userCredential = await fba.FirebaseAuth.instance.signInWithCredential(credential);
  //     final user = userCredential.user;
  //     if (user == null) throw Exception('Gagal login dengan Google');

  //     // Cek apakah user sudah ada di Firestore
  //     final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  //     final userDoc = await userDocRef.get();

  //     if (!userDoc.exists) {
  //       await userDocRef.set({
  //         'email': user.email,
  //         'nama': user.displayName ?? '',
  //         'role': 'CUSTOMER',
  //         'createdAt': DateTime.now(),
  //       });
  //     }

  //     // Simpan token dan role ke penyimpanan lokal
  //     final token = await user.getIdToken();
  //     await _storageService.saveTokenAndRole(token: token, role: 'CUSTOMER');

  //     notifyListeners();
  //   } catch (e) {
  //     throw Exception('Login dengan Google gagal: $e');
  //   }
  // }
}
