import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();

  @override
  String toString() => 'Login Google dibatalkan.';
}

class GoogleSignInConfigurationException implements Exception {
  const GoogleSignInConfigurationException();

  @override
  String toString() =>
      'Konfigurasi Login Google untuk build aplikasi ini belum valid.';
}

class GoogleSignInInterruptedException implements Exception {
  const GoogleSignInInterruptedException();

  @override
  String toString() =>
      'Login Google terputus. Pastikan koneksi stabil lalu coba lagi.';
}

/// Adapter tunggal untuk Google Sign-In + Firebase Authentication.
///
/// Hanya scope identitas dasar yang digunakan. Token Google tidak disimpan
/// oleh aplikasi dan tidak dikirim ke backend; backend menerima Firebase ID
/// token yang dapat diverifikasi oleh Firebase Admin.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );
  static const String _iosSandboxClientId =
      '132125085396-6j9q9uh7bcok75lmg09hgh1eqgeod80j'
      '.apps.googleusercontent.com';
  static const String _iosProductionClientId =
      '891691718664-df6narc91kga6ckpud5tacmgmm36pgv3'
      '.apps.googleusercontent.com';
  static const String _androidSandboxServerClientId =
      '132125085396-984levalimj08hagnoh5i7j62e1h9q0a'
      '.apps.googleusercontent.com';
  static const String _androidProductionServerClientId =
      '891691718664-4dvnlivp2uiqgdte9p3p1n0bkf9m80p7'
      '.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initializeFuture;

  @visibleForTesting
  static String androidServerClientIdFor(String appEnv) {
    return appEnv.toLowerCase() == 'sandbox'
        ? _androidSandboxServerClientId
        : _androidProductionServerClientId;
  }

  Future<void> initialize() {
    if (kIsWeb) return Future.value();
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isSandbox = _appEnv.toLowerCase() == 'sandbox';
    return _initializeFuture ??= _googleSignIn.initialize(
      clientId: isIos
          ? (isSandbox ? _iosSandboxClientId : _iosProductionClientId)
          : null,
      // Jangan hanya bergantung pada default_web_client_id hasil Gradle.
      // Project ini mengganti google-services.json berdasarkan APP_ENV dan
      // output incremental build dapat membawa resource environment lama.
      serverClientId: isAndroid ? androidServerClientIdFor(_appEnv) : null,
    );
  }

  Future<UserCredential> signIn() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});
      return FirebaseAuth.instance.signInWithPopup(provider);
    }

    await initialize();
    try {
      final googleAccount = await _googleSignIn.authenticate();
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google tidak mengembalikan ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelledException();
      }
      if (error.code == GoogleSignInExceptionCode.interrupted) {
        throw const GoogleSignInInterruptedException();
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const GoogleSignInConfigurationException();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await initialize();
      await _googleSignIn.signOut();
    }
  }
}
