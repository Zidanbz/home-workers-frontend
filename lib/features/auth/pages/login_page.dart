import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/services/google_auth_service.dart';
import 'package:home_workers_fe/core/widgets/google_auth_button.dart';
import 'package:home_workers_fe/features/auth/pages/email_verification_pending_page.dart';
import 'package:home_workers_fe/features/auth/pages/forgot_password_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:home_workers_fe/features/auth/pages/select_role_page.dart';
import 'package:home_workers_fe/features/auth/pages/register_worker_page.dart';
import 'package:home_workers_fe/features/auth/pages/worker_registration_status_page.dart';
import 'package:home_workers_fe/features/auth/pages/worker_kyc_revision_page.dart';
import 'package:home_workers_fe/features/main_page.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPasswordObscured = true;
  String? _fcmToken;
  StreamSubscription<String>? _fcmTokenRefreshSubscription;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('FCM disabled on iOS for now.');
      return;
    }

    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) return;
      setState(() => _fcmToken = token);
      debugPrint(
        'FCM token login tersedia: ${token != null && token.isNotEmpty}',
      );

      // Dengarkan token refresh
      _fcmTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) async {
            debugPrint('FCM token diperbarui.');
            if (!mounted) return;
            setState(() => _fcmToken = newToken);

            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (authProvider.isLoggedIn) {
              await authProvider.syncFcmToken(newToken);
            }
          });
    } catch (e) {
      debugPrint('Gagal inisialisasi FCM: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_fcmTokenRefreshSubscription?.cancel());
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      /* ... validasi ... */
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Panggil fungsi yang HANYA mengambil data
      final result = await authProvider.loginAndGetData(
        email: email,
        password: password,
        fcmToken: _fcmToken,
      );

      // 2. Logika pengecekan tetap sama
      if (result.requireEmailVerification) {
        // Jika belum verifikasi, langsung arahkan ke halaman tunggu
        // State global BELUM diubah, jadi AuthWrapper tidak akan mengganggu
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Login berhasil! Silakan verifikasi email Anda.'),
          ),
        );
        await navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPendingPage(email: email),
          ),
          (route) => false,
        );
      } else {
        // Jika SUDAH verifikasi
        // 3. BARU kita proses login dan ubah state global
        await authProvider.processLoginSuccess(result);

        // 4. Setelah state diubah, baru kita navigasi
        final userRole = result.user.role;
        final workerStatus = (result.workerStatus ?? result.user.workerStatus)
            ?.toLowerCase();
        final Widget destination;
        if (userRole.toUpperCase() == 'WORKER' &&
            workerStatus == 'revision_required') {
          destination = const WorkerKycRevisionPage();
        } else if (userRole.toUpperCase() == 'WORKER' &&
            (workerStatus == 'pending' ||
                workerStatus == 'resubmitted' ||
                workerStatus == 'rejected')) {
          destination = WorkerRegistrationStatusPage(
            status: workerStatus!,
            rejectionReason: result.rejectionReason,
          );
        } else if (userRole.toUpperCase() != 'WORKER' ||
            workerStatus == 'approved') {
          destination = MainPage(userRole: userRole);
        } else {
          destination = WorkerRegistrationStatusPage(
            status: workerStatus ?? 'registration_incomplete',
            rejectionReason: result.rejectionReason,
          );
        }
        if (!mounted) return;
        await navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destination),
          (route) => false,
        );

        // 5. Show first login hint after navigation
        if (mounted &&
            (userRole.toUpperCase() != 'WORKER' ||
                workerStatus == 'approved')) {
          await authProvider.showFirstLoginHintIfNeeded(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiService.readableError(e, action: 'Login gagal');
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performGoogleAuth() async {
    final authProvider = context.read<AuthProvider>();
    setState(() => _isGoogleLoading = true);

    try {
      final result = await authProvider.authenticateWithGoogle(
        fcmToken: _fcmToken,
      );
      if (!mounted) return;

      final Widget destination = switch (result.nextAction) {
        GoogleAuthNextAction.openApp => MainPage(
          userRole: authProvider.user?.role ?? 'CUSTOMER',
        ),
        GoogleAuthNextAction.selectRole => SelectRolePage(
          googleRegistration: true,
          googleName: result.nama,
          googleEmail: result.email,
        ),
        GoogleAuthNextAction.completeWorkerKyc => RegisterWorkerPage(
          googleRegistration: true,
          initialName: result.nama,
          initialEmail: result.email,
        ),
        GoogleAuthNextAction.showRejection => WorkerRegistrationStatusPage(
          status: 'rejected',
          rejectionReason: result.rejectionReason,
        ),
        GoogleAuthNextAction.showWorkerStatus => WorkerRegistrationStatusPage(
          status: result.workerStatus ?? 'pending',
          rejectionReason: result.rejectionReason,
        ),
        GoogleAuthNextAction.openKycRevision => const WorkerKycRevisionPage(),
      };

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } on GoogleSignInCancelledException {
      // Pembatalan pemilih akun bukan error yang perlu ditampilkan.
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        ApiService.readableError(e, action: 'Login Google gagal'),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Message only
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E232C),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E232C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Login to your\naccount.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E232C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to your account',
              style: TextStyle(fontSize: 16, color: Color(0xFF8391A1)),
            ),
            const SizedBox(height: 40),
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E232C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E232C),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _isPasswordObscured,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _isGoogleLoading ? null : _performLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E232C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'atau',
                    style: TextStyle(color: Color(0xFF8391A1)),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            GoogleAuthButton(
              label: 'Lanjutkan dengan Google',
              isLoading: _isGoogleLoading,
              onPressed: _isLoading ? null : _performGoogleAuth,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun?',
                  style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
                ),
                TextButton(
                  onPressed: _isLoading || _isGoogleLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SelectRolePage(),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A374D),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
