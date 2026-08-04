import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // opsional: untuk debug/snackbar
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_service.dart';
import '../models/operational_location_model.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import '../services/google_auth_service.dart';
import '../services/realtime_notification_service.dart';
import '../services/chat_service.dart';
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
  final String refreshToken;
  final int expiresIn; // dalam detik
  final String? nextAction;
  final String? workerStatus;
  final String? rejectionReason;

  AuthLoginResult({
    required this.success,
    required this.requireEmailVerification,
    required this.user,
    required this.idToken,
    required this.customToken,
    required this.refreshToken,
    required this.expiresIn,
    this.nextAction,
    this.workerStatus,
    this.rejectionReason,
  });
}

enum GoogleAuthNextAction {
  openApp,
  selectRole,
  completeWorkerKyc,
  showWorkerStatus,
  showRejection,
  openKycRevision,
}

class GoogleAuthFlowResult {
  final GoogleAuthNextAction nextAction;
  final String? nama;
  final String? email;
  final String? workerStatus;
  final String? rejectionReason;

  const GoogleAuthFlowResult({
    required this.nextAction,
    this.nama,
    this.email,
    this.workerStatus,
    this.rejectionReason,
  });
}

class AuthProvider with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  final ApiService _apiService = ApiService();
  final SecureStorageService _storageService;
  final GoogleAuthService _googleAuthService = GoogleAuthService.instance;
  final Duration _logoutStepTimeout;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  User? _user;
  String?
  _token; // idToken dari backend (Firebase ID token). Dipakai untuk API bearer.
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Timer? _refreshTimer;
  bool _usesFirebaseManagedSession = false;
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  AuthScreen _authScreen = AuthScreen.welcome;
  Future<void>? _logoutFuture;
  int _sessionGeneration = 0;

  // flag internal: apakah login terakhir butuh verifikasi email
  bool _lastLoginRequiresEmailVerification = false;

  AuthProvider({
    SecureStorageService? storageService,
    Duration logoutStepTimeout = const Duration(seconds: 3),
    bool initializeOnCreate = true,
  }) : _storageService = storageService ?? SecureStorageService(),
       _logoutStepTimeout = logoutStepTimeout {
    if (initializeOnCreate) {
      initializeApp();
    } else {
      _isLoading = false;
    }
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

  Future<String?> _getOptionalFcmToken(String? fcmToken) async {
    if (fcmToken != null && fcmToken.isNotEmpty) return fcmToken;
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('FCM disabled on iOS for now. Continuing without token.');
      return null;
    }

    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Gagal mendapatkan FCM token. Melanjutkan tanpa token: $e');
      return null;
    }
  }

  void updateLocalProfile({String? nama, String? contact}) {
    if (_user == null) return;
    _user = _user!.copyWith(
      nama: nama ?? _user!.nama,
      contact: contact ?? _user!.contact,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Token Helpers
  // ---------------------------------------------------------------------------
  static const Duration _refreshBuffer = Duration(minutes: 5);

  DateTime _calculateExpiry({String? expiresIn, String? token}) {
    final seconds = int.tryParse(expiresIn ?? '');
    if (seconds != null && seconds > 0) {
      return DateTime.now().add(Duration(seconds: seconds));
    }
    if (token != null) {
      return JwtDecoder.getExpirationDate(token);
    }
    // Fallback konservatif: 45 menit
    return DateTime.now().add(const Duration(minutes: 45));
  }

  DateTime? _safeExpiryFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      debugPrint('Token expiry parse failed: $e');
      return null;
    }
  }

  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    final expiry = _tokenExpiry;
    if (expiry == null) return;
    if (!_usesFirebaseManagedSession && _refreshToken == null) return;

    final refreshAt = expiry.subtract(_refreshBuffer);
    final now = DateTime.now();
    final delay = refreshAt.isAfter(now)
        ? refreshAt.difference(now)
        : Duration.zero;

    _refreshTimer = Timer(delay, () {
      if (_usesFirebaseManagedSession) {
        unawaited(_refreshFirebaseManagedSession());
      } else {
        unawaited(_refreshSession());
      }
    });
  }

  Future<bool> _refreshFirebaseManagedSession() async {
    final sessionGeneration = _sessionGeneration;
    final firebaseUser = fba.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return false;

    try {
      final newIdToken = await firebaseUser.getIdToken(true);
      if (newIdToken == null || newIdToken.isEmpty) return false;
      if (sessionGeneration != _sessionGeneration || _user == null) {
        return false;
      }
      _token = newIdToken;
      _tokenExpiry =
          _safeExpiryFromToken(newIdToken) ??
          DateTime.now().add(const Duration(minutes: 55));
      if (_user != null) {
        try {
          await _storageService
              .saveFirebaseSession(
                token: newIdToken,
                role: _user!.role,
                expiresAt: _tokenExpiry!,
              )
              .timeout(_logoutStepTimeout);
        } on TimeoutException {
          debugPrint(
            'Penyimpanan Firebase session melewati batas waktu; token in-memory tetap digunakan.',
          );
        } catch (e) {
          debugPrint('Penyimpanan Firebase session gagal: $e');
        }
      }
      _scheduleTokenRefresh();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gagal refresh Firebase session: $e');
      return false;
    }
  }

  Future<bool> _refreshSession() async {
    final sessionGeneration = _sessionGeneration;
    final refreshToken =
        _refreshToken ?? await _storageService.readRefreshToken();
    if (refreshToken == null) return false;
    if (sessionGeneration != _sessionGeneration) return false;

    try {
      final responseBody = await _apiService.refreshIdToken(
        refreshToken: refreshToken,
      );

      final Map<String, dynamic>? data = responseBody['data'];
      if (data == null) {
        throw Exception('Struktur respons refresh token tidak valid.');
      }

      final String? newIdToken = data['idToken'];
      final String? newRefreshToken = data['refreshToken'];
      final String? expiresIn = data['expiresIn']?.toString();

      if (newIdToken == null) {
        throw Exception('Refresh token gagal: idToken kosong.');
      }
      if (sessionGeneration != _sessionGeneration) return false;

      _token = newIdToken;
      _refreshToken = newRefreshToken ?? refreshToken;
      _tokenExpiry = _calculateExpiry(expiresIn: expiresIn, token: newIdToken);

      try {
        await _storageService
            .saveTokenAndRole(
              token: _token!,
              role: _user?.role,
              refreshToken: _refreshToken,
              expiresAt: _tokenExpiry,
              authMethod: 'password',
            )
            .timeout(_logoutStepTimeout);
      } on TimeoutException {
        debugPrint(
          'Penyimpanan password session melewati batas waktu; token in-memory tetap digunakan.',
        );
      } catch (e) {
        debugPrint('Penyimpanan password session gagal: $e');
      }

      _scheduleTokenRefresh();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gagal refresh token: $e');
      return false;
    }
  }

  Future<void> _restoreSession() async {
    if (await _storageService.isLogoutPending()) {
      try {
        await _storageService.deleteAll().timeout(_logoutStepTimeout);
      } on TimeoutException {
        debugPrint(
          'Secure storage cleanup masih tertunda; sesi lama tidak dipulihkan.',
        );
      } catch (e) {
        debugPrint(
          'Secure storage cleanup gagal; sesi lama tidak dipulihkan: $e',
        );
      }
      return;
    }

    final authMethod = await _storageService.readAuthMethod();
    if (authMethod == 'google') {
      final firebaseUser = fba.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        await _storageService.deleteAll();
        return;
      }

      try {
        final firebaseToken = await firebaseUser.getIdToken(true);
        if (firebaseToken == null || firebaseToken.isEmpty) {
          throw Exception('Firebase ID token kosong.');
        }
        final response = await _apiService.bootstrapGoogleAccount(
          firebaseIdToken: firebaseToken,
        );
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['user'] is! Map) {
          await _googleAuthService.signOut();
          await _storageService.deleteAll();
          return;
        }
        await _applyGoogleSession(
          data: data,
          firebaseIdToken: firebaseToken,
          notify: false,
        );
        if (_user?.workerStatus == null || _user?.workerStatus == 'approved') {
          _startRealtimeNotifications();
          _startRealtimeChats();
        }
        return;
      } catch (_) {
        await _googleAuthService.signOut();
        await _storageService.deleteAll();
        return;
      }
    }

    final storedToken = await _storageService.readToken();
    final storedRefreshToken = await _storageService.readRefreshToken();
    final storedExpiry = await _storageService.readTokenExpiry();

    _refreshToken = storedRefreshToken;
    _tokenExpiry = storedExpiry ?? _safeExpiryFromToken(storedToken);

    final tokenLooksValid =
        storedToken != null && _safeExpiryFromToken(storedToken) != null;
    final tokenNotExpired =
        tokenLooksValid && !JwtDecoder.isExpired(storedToken);

    if (tokenNotExpired) {
      try {
        final userProfile = await _apiService.getMyProfile(storedToken);
        await _restorePasswordFirebaseSession(
          apiToken: storedToken,
          expectedUid: userProfile.uid,
        );
        _user = userProfile;
        _token = storedToken;

        if (userProfile.role.toUpperCase() != 'WORKER' ||
            userProfile.workerStatus == 'approved') {
          await getAvatar();
        }

        _scheduleTokenRefresh();
        if (userProfile.role.toUpperCase() != 'WORKER' ||
            userProfile.workerStatus == 'approved') {
          _startRealtimeNotifications();
          _startRealtimeChats();
        }
        return;
      } catch (_) {
        await logout();
        return;
      }
    }

    if (storedRefreshToken != null) {
      final refreshed = await _refreshSession();
      if (refreshed && _token != null) {
        try {
          final userProfile = await _apiService.getMyProfile(_token!);
          await _restorePasswordFirebaseSession(
            apiToken: _token!,
            expectedUid: userProfile.uid,
          );
          _user = userProfile;
          if (userProfile.role.toUpperCase() != 'WORKER' ||
              userProfile.workerStatus == 'approved') {
            await getAvatar();
            _startRealtimeNotifications();
            _startRealtimeChats();
          }
          return;
        } catch (_) {
          await logout();
          return;
        }
      }
    }

    if (storedToken != null && !tokenLooksValid) {
      // Bersihkan token lama/invalid agar startup berikutnya tidak macet.
      await _storageService.deleteAll();
    }
  }

  // ---------------------------------------------------------------------------
  // Init / Auto Login
  // ---------------------------------------------------------------------------
  Future<void> initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      await _restoreSession();
    } catch (e) {
      debugPrint('initializeApp failed: $e');
      // Jangan biarkan root app terkunci di splash saat startup error.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    try {
      await _restoreSession();
    } catch (e) {
      debugPrint('tryAutoLogin failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memperbarui bearer token sebelum aksi sensitif yang mengubah transaksi.
  /// Token lama tidak digunakan bila refresh gagal atau sesi sudah logout.
  Future<String?> refreshAccessToken() async {
    await _waitForLogoutCleanup();
    if (_token == null || _user == null) return null;

    final refreshed = _usesFirebaseManagedSession
        ? await _refreshFirebaseManagedSession()
        : await _refreshSession();
    return refreshed ? _token : null;
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
    await _waitForLogoutCleanup();
    try {
      _isLoading = true;
      notifyListeners();

      final resolvedFcm = await _getOptionalFcmToken(fcmToken);

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
      final String? refreshToken = data['refreshToken'];
      final String? expiresIn = data['expiresIn']?.toString();
      final Map<String, dynamic>? userJson = data['user'];
      final bool requireEmailVerification =
          data['requireEmailVerification'] ?? false;

      // ===============================================================

      if (customToken == null ||
          idToken == null ||
          refreshToken == null ||
          expiresIn == null ||
          userJson == null) {
        throw Exception('Respons dari backend tidak lengkap.');
      }
      final parsedUser = User.fromJson(userJson);

      // Sign in ke Firebase client pakai custom token
      await _signInFirebaseWithCustomTokenIfNeeded(
        customToken,
        expectedUid: parsedUser.uid,
      );

      // Update state
      _user = parsedUser;
      _token = idToken;
      _refreshToken = refreshToken;
      _usesFirebaseManagedSession = false;
      _tokenExpiry = _calculateExpiry(expiresIn: expiresIn, token: idToken);
      _lastLoginRequiresEmailVerification = requireEmailVerification;

      // Simpan token + role ke storage
      await _storageService.saveTokenAndRole(
        token: _token!,
        role: _user!.role,
        refreshToken: _refreshToken,
        expiresAt: _tokenExpiry,
        authMethod: 'password',
      );

      _scheduleTokenRefresh();

      // notifyListeners();

      return AuthLoginResult(
        success: true,
        requireEmailVerification: requireEmailVerification,
        user: _user!,
        idToken: _token!,
        customToken: customToken,
        refreshToken: refreshToken,
        expiresIn: int.tryParse(expiresIn) ?? 3600,
        nextAction: data['nextAction']?.toString(),
        workerStatus: data['workerStatus']?.toString(),
        rejectionReason: data['rejectionReason']?.toString(),
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
    String customToken, {
    required String expectedUid,
  }) async {
    final current = fba.FirebaseAuth.instance.currentUser;
    if (current?.uid == expectedUid) {
      try {
        final currentToken = await current!.getIdToken();
        if (currentToken != null && currentToken.isNotEmpty) return;
      } catch (e) {
        debugPrint('Firebase session lama tidak dapat digunakan: $e');
      }
    }
    if (current != null) {
      await fba.FirebaseAuth.instance.signOut();
    }
    final credential = await fba.FirebaseAuth.instance.signInWithCustomToken(
      customToken,
    );
    if (credential.user?.uid != expectedUid) {
      await fba.FirebaseAuth.instance.signOut();
      throw StateError('Firebase session UID tidak sesuai dengan akun login.');
    }
    debugPrint('Firebase sign-in success (custom token).');
  }

  Future<void> _restorePasswordFirebaseSession({
    required String apiToken,
    required String expectedUid,
  }) async {
    final current = fba.FirebaseAuth.instance.currentUser;
    if (current?.uid == expectedUid) {
      try {
        final currentToken = await current!.getIdToken();
        if (currentToken != null && currentToken.isNotEmpty) return;
      } catch (e) {
        debugPrint('Firebase Auth perlu dipulihkan: $e');
      }
    }

    final customToken = await _apiService.createFirebaseSessionCustomToken(
      token: apiToken,
    );
    await _signInFirebaseWithCustomTokenIfNeeded(
      customToken,
      expectedUid: expectedUid,
    );
  }

  Future<void> _applyGoogleSession({
    required Map<String, dynamic> data,
    required String firebaseIdToken,
    bool notify = true,
  }) async {
    final rawUser = data['user'];
    if (rawUser is! Map) {
      throw StateError('Profile user Google tidak ditemukan.');
    }

    _user = User.fromJson(Map<String, dynamic>.from(rawUser));
    _token = firebaseIdToken;
    _refreshToken = null;
    _usesFirebaseManagedSession = true;
    _lastLoginRequiresEmailVerification = false;
    _tokenExpiry =
        _safeExpiryFromToken(firebaseIdToken) ??
        DateTime.now().add(const Duration(minutes: 55));

    await _storageService.saveFirebaseSession(
      token: firebaseIdToken,
      role: _user!.role,
      expiresAt: _tokenExpiry!,
    );
    _scheduleTokenRefresh();
    if (notify) notifyListeners();
  }

  GoogleAuthNextAction _parseGoogleNextAction(String? action) {
    switch (action) {
      case 'OPEN_CUSTOMER_HOME':
      case 'OPEN_WORKER_HOME':
        return GoogleAuthNextAction.openApp;
      case 'SELECT_ROLE':
        return GoogleAuthNextAction.selectRole;
      case 'COMPLETE_WORKER_KYC':
        return GoogleAuthNextAction.completeWorkerKyc;
      case 'SHOW_REJECTION':
        return GoogleAuthNextAction.showRejection;
      case 'OPEN_KYC_REVISION':
        return GoogleAuthNextAction.openKycRevision;
      case 'SHOW_VERIFICATION_STATUS':
      default:
        return GoogleAuthNextAction.showWorkerStatus;
    }
  }

  Future<GoogleAuthFlowResult> authenticateWithGoogle({
    String? fcmToken,
  }) async {
    await _waitForLogoutCleanup();
    try {
      final credential = await _googleAuthService.signIn();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw StateError('Firebase tidak mengembalikan pengguna Google.');
      }
      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw StateError('Firebase ID token tidak tersedia.');
      }

      final resolvedFcm = await _getOptionalFcmToken(fcmToken);
      final response = await _apiService.bootstrapGoogleAccount(
        firebaseIdToken: firebaseIdToken,
        fcmToken: resolvedFcm,
      );
      final rawData = response['data'];
      if (rawData is! Map) {
        throw StateError('Respons bootstrap Google tidak valid.');
      }
      final data = Map<String, dynamic>.from(rawData);
      final nextAction = _parseGoogleNextAction(data['nextAction']?.toString());

      if (nextAction == GoogleAuthNextAction.openApp) {
        await _applyGoogleSession(data: data, firebaseIdToken: firebaseIdToken);
        await getAvatar();
        _startRealtimeNotifications();
        _startRealtimeChats();
      } else if (nextAction != GoogleAuthNextAction.selectRole &&
          nextAction != GoogleAuthNextAction.completeWorkerKyc) {
        // Sesi tetap disimpan agar Worker dapat membuka status/revisi KYC.
        // Endpoint bisnis tetap dikunci oleh backend sampai status approved.
        await _applyGoogleSession(data: data, firebaseIdToken: firebaseIdToken);
      }

      final googleProfile = data['googleProfile'] is Map
          ? Map<String, dynamic>.from(data['googleProfile'] as Map)
          : <String, dynamic>{};
      final appUser = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : <String, dynamic>{};

      return GoogleAuthFlowResult(
        nextAction: nextAction,
        nama:
            googleProfile['nama']?.toString() ??
            appUser['nama']?.toString() ??
            firebaseUser.displayName,
        email:
            googleProfile['email']?.toString() ??
            appUser['email']?.toString() ??
            firebaseUser.email,
        workerStatus: data['workerStatus']?.toString(),
        rejectionReason: data['rejectionReason']?.toString(),
      );
    } catch (_) {
      // Pertahankan credential hanya pada respons sukses yang memang menuju
      // onboarding Google. Semua kegagalan harus kembali ke keadaan signed-out.
      await _googleAuthService.signOut().catchError((_) {});
      await _storageService.deleteAll();
      rethrow;
    }
  }

  Future<void> registerGoogleCustomer({
    required String nama,
    required String contact,
    String? fcmToken,
  }) async {
    final firebaseUser = fba.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('Sesi registrasi Google sudah berakhir.');
    }
    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Firebase ID token tidak tersedia.');
    }

    final resolvedFcm = await _getOptionalFcmToken(fcmToken);
    final response = await _apiService.registerGoogleCustomer(
      firebaseIdToken: firebaseIdToken,
      nama: nama,
      contact: contact,
      fcmToken: resolvedFcm,
    );
    final rawData = response['data'];
    if (rawData is! Map) {
      throw StateError('Respons registrasi Google tidak valid.');
    }
    await _applyGoogleSession(
      data: Map<String, dynamic>.from(rawData),
      firebaseIdToken: firebaseIdToken,
    );
    _startRealtimeNotifications();
    _startRealtimeChats();
  }

  Future<void> registerGoogleWorker({
    required String nama,
    required String contact,
    required List<String> keahlian,
    required String deskripsi,
    required File ktpFile,
    required File fotoDiriFile,
    File? certificateFile,
    String? portfolioLink,
    required String noKtp,
    String? fcmToken,
    required OperationalLocation operationalLocation,
    required String termsVersion,
    required String registrationRequestId,
  }) async {
    final firebaseUser = fba.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('Sesi registrasi Google sudah berakhir.');
    }
    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Firebase ID token tidak tersedia.');
    }
    final resolvedFcm = await _getOptionalFcmToken(fcmToken);
    await _apiService.registerGoogleWorker(
      firebaseIdToken: firebaseIdToken,
      nama: nama,
      contact: contact,
      keahlian: keahlian,
      deskripsi: deskripsi,
      ktpFile: ktpFile,
      fotoDiriFile: fotoDiriFile,
      certificateFile: certificateFile,
      portfolioLink: portfolioLink,
      noKtp: noKtp,
      fcmToken: resolvedFcm,
      operationalLocation: operationalLocation,
      termsVersion: termsVersion,
      registrationRequestId: registrationRequestId,
    );

    try {
      await _googleAuthService.signOut();
    } catch (e) {
      debugPrint('Google sign-out setelah registrasi Worker gagal: $e');
    } finally {
      await _storageService.deleteAll();
    }
  }

  Future<void> cancelGoogleRegistration() async {
    try {
      await _googleAuthService.signOut();
    } catch (e) {
      debugPrint('Google sign-out gagal: $e');
    } finally {
      await _storageService.deleteAll();
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTER CUSTOMER (no auto-login)
  // ---------------------------------------------------------------------------
  Future<void> registerCustomer({
    required String email,
    required String password,
    required String nama,
    required String contact,
    String? fcmToken,
  }) async {
    try {
      final resolvedFcm = await _getOptionalFcmToken(fcmToken);

      await _apiService.registerCustomer(
        email: email,
        password: password,
        nama: nama,
        contact: contact,
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
    required String contact,
    required List<String> keahlian,
    required String deskripsi,
    required File ktpFile,
    required File fotoDiriFile,
    File? certificateFile,
    String? portfolioLink,
    required String noKtp,
    String? fcmToken,
    required OperationalLocation operationalLocation,
    required String termsVersion,
    required String registrationRequestId,
  }) async {
    try {
      final resolvedFcm = await _getOptionalFcmToken(fcmToken);
      await _apiService.registerWorker(
        email: email,
        password: password,
        nama: nama,
        contact: contact,
        keahlian: keahlian,
        deskripsi: deskripsi,
        ktpFile: ktpFile,
        fotoDiriFile: fotoDiriFile,
        certificateFile: certificateFile,
        portfolioLink: portfolioLink,
        noKtp: noKtp,
        fcmToken: resolvedFcm,
        operationalLocation: operationalLocation,
        termsVersion: termsVersion,
        registrationRequestId: registrationRequestId,
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
    await _waitForLogoutCleanup();
    try {
      final resolvedFcm = await _getOptionalFcmToken(fcmToken);
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
      final String? refreshToken = data['refreshToken'];
      final String? expiresIn = data['expiresIn']?.toString();
      final String? idToken = data['idToken'];
      final String? customToken = data['customToken'];

      if (refreshToken == null ||
          expiresIn == null ||
          idToken == null ||
          customToken == null) {
        throw Exception('Respons dari backend tidak lengkap.');
      }

      // Fungsi ini HANYA mengembalikan data, tidak mengubah state provider
      return AuthLoginResult(
        success: true,
        requireEmailVerification: requireEmailVerification,
        user: user,
        idToken: idToken,
        customToken: customToken,
        refreshToken: refreshToken,
        expiresIn: int.tryParse(expiresIn) ?? 3600,
        nextAction: data['nextAction']?.toString(),
        workerStatus: data['workerStatus']?.toString(),
        rejectionReason: data['rejectionReason']?.toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // FUNGSI BARU (untuk memproses data login dan mengubah state)
  Future<void> processLoginSuccess(AuthLoginResult loginResult) async {
    await _waitForLogoutCleanup();
    _user = loginResult.user;
    _token = loginResult.idToken;
    _refreshToken = loginResult.refreshToken;
    _usesFirebaseManagedSession = false;
    _tokenExpiry = _calculateExpiry(
      expiresIn: loginResult.expiresIn.toString(),
      token: loginResult.idToken,
    );
    _lastLoginRequiresEmailVerification = loginResult.requireEmailVerification;

    await _signInFirebaseWithCustomTokenIfNeeded(
      loginResult.customToken,
      expectedUid: loginResult.user.uid,
    );
    await _storageService.saveTokenAndRole(
      token: _token!,
      role: _user!.role,
      refreshToken: _refreshToken,
      expiresAt: _tokenExpiry,
      authMethod: 'password',
    );

    _scheduleTokenRefresh();

    final unrestricted =
        loginResult.user.role.toUpperCase() != 'WORKER' ||
        loginResult.workerStatus == 'approved';
    if (unrestricted) {
      await getAvatar();
      _startRealtimeNotifications();
      _startRealtimeChats();
    }

    // Sekarang, baru kita beritahu seluruh aplikasi bahwa login benar-benar selesai
    notifyListeners();
  }

  void markKycResubmitted() {
    if (_user == null) return;
    _user = _user!.copyWith(workerStatus: 'resubmitted');
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
      final currentUser = _user;
      final currentToken = _token;
      if (currentUser == null ||
          currentToken == null ||
          currentUser.role.toUpperCase() != 'CUSTOMER') {
        return;
      }

      if (!await HintSystem.shouldShowAddressHint(currentUser.uid)) {
        return;
      }

      final addresses = await _apiService.getMyAddresses(currentToken);
      if (addresses.isNotEmpty) {
        return;
      }

      // Add a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        await HintSystem.showAddressHint(context, userId: currentUser.uid);
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

  /// Start real-time chat listener (non-blocking)
  void _startRealtimeChats() {
    Future.microtask(() async {
      try {
        if (!ChatService().isInitialized) {
          await ChatService.initialize();
        }

        final chatService = ChatService();
        await chatService.startListening(_user!.uid, _token);

        debugPrint(
          '✅ [_startRealtimeChats] Chat listener started successfully',
        );
      } catch (e) {
        debugPrint('❌ [_startRealtimeChats] Failed to start chat listener: $e');
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
      if (_token != tkn) return null;
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
    if (_token != tkn || _user == null) return;
    _user = _user!.copyWith(avatarUrl: storageDownloadUrl);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Refresh User Data
  // ---------------------------------------------------------------------------
  Future<void> refreshUserData() async {
    final tkn = _token;
    if (tkn == null) return;
    try {
      final updatedUser = await _apiService.getMyProfile(tkn);
      if (_token != tkn) return;
      _user = updatedUser;
      // Fetch avatar after refreshing user profile to ensure avatar URL is up to date
      await getAvatar();
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal refresh user: $e');
      await logout();
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  Future<void> logout() {
    return _logoutFuture ??= _performLogout().whenComplete(() {
      _logoutFuture = null;
    });
  }

  Future<void> _waitForLogoutCleanup() async {
    final pendingLogout = _logoutFuture;
    if (pendingLogout != null) await pendingLogout;
  }

  Future<void> _runLogoutStep(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      await action().timeout(_logoutStepTimeout);
      debugPrint('✅ [logout] $name selesai');
    } on TimeoutException {
      debugPrint('❌ [logout] $name melewati batas waktu');
    } catch (e) {
      debugPrint('❌ [logout] $name gagal: $e');
    }
  }

  Future<void> _performLogout() async {
    // Putuskan akses UI dan bearer token secara sinkron. Navigasi tidak boleh
    // menunggu plugin native, jaringan, atau Android Keystore.
    final usedFirebaseManagedSession = _usesFirebaseManagedSession;
    _sessionGeneration++;
    _user = null;
    _token = null;
    _refreshToken = null;
    _usesFirebaseManagedSession = false;
    _tokenExpiry = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _lastLoginRequiresEmailVerification = false;
    _authScreen = AuthScreen.login;
    notifyListeners();

    await _runLogoutStep('marker logout', _storageService.markLogoutPending);
    await Future.wait([
      _runLogoutStep(
        'listener notifikasi',
        () => RealtimeNotificationService().stopListening(clearData: true),
      ),
      _runLogoutStep(
        'listener chat',
        () => ChatService().stopListening(clearData: true),
      ),
      _runLogoutStep('Firebase sign-out', () async {
        if (usedFirebaseManagedSession) {
          await _googleAuthService.signOut();
        } else {
          await fba.FirebaseAuth.instance.signOut();
        }
      }),
      _runLogoutStep('secure storage cleanup', _storageService.deleteAll),
    ]);
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
