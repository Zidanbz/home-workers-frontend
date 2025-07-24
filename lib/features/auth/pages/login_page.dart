import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/auth/pages/email_verification_pending_page.dart';
import 'package:home_workers_fe/features/auth/pages/forgot_password_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:home_workers_fe/features/auth/pages/select_role_page.dart';
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
  bool _isPasswordObscured = true;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (mounted) setState(() => _fcmToken = token);
      debugPrint('FCM token (login_page): $token');

      // Dengarkan token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed: $newToken');
        if (mounted) setState(() => _fcmToken = newToken);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isLoggedIn) {
          await authProvider.syncFcmToken(newToken);
        }
      });
    } catch (e) {
      debugPrint('Gagal inisialisasi FCM: $e');
    }
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
        if (!mounted) return;
        await navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainPage(userRole: userRole)),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Login Gagal: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                      onPressed: _performLogin,
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
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E232C),
                  ),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Register',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SelectRolePage(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
