import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/services/secure_storage_service.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HangingSecureStorageService extends SecureStorageService {
  _HangingSecureStorageService({this.logoutPending = false});

  final bool logoutPending;
  bool logoutMarked = false;
  bool cleanupStarted = false;

  @override
  Future<bool> isLogoutPending() async => logoutPending;

  @override
  Future<void> markLogoutPending() async {
    logoutMarked = true;
  }

  @override
  Future<void> deleteAll() {
    cleanupStarted = true;
    return Completer<void>().future;
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.invalid/api');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logout tidak macet ketika secure storage tidak merespons', () async {
    final storage = _HangingSecureStorageService();
    final auth = AuthProvider(
      storageService: storage,
      logoutStepTimeout: const Duration(milliseconds: 10),
      initializeOnCreate: false,
    );

    var notifications = 0;
    auth.addListener(() => notifications++);

    final logoutFuture = auth.logout();

    // Route dapat dipindahkan segera; cleanup native/secure storage tidak
    // boleh menahan perubahan state autentikasi lokal.
    expect(auth.isLoggedIn, isFalse);
    expect(auth.authScreen, AuthScreen.login);

    await logoutFuture.timeout(const Duration(seconds: 1));

    expect(auth.isLoggedIn, isFalse);
    expect(auth.isLoading, isFalse);
    expect(auth.authScreen, AuthScreen.login);
    expect(storage.logoutMarked, isTrue);
    expect(storage.cleanupStarted, isTrue);
    expect(notifications, greaterThanOrEqualTo(1));
  });

  test('startup tidak memulihkan sesi saat cleanup logout tertunda', () async {
    final storage = _HangingSecureStorageService(logoutPending: true);
    final auth = AuthProvider(
      storageService: storage,
      logoutStepTimeout: const Duration(milliseconds: 10),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(auth.isLoading, isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(storage.cleanupStarted, isTrue);
  });
}
