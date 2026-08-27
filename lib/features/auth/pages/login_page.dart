import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const LoginPage({super.key, this.initializeFcm = true});

  final bool initializeFcm;

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
    if (widget.initializeFcm) _initFcm();
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

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0xFFDCE4E8);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: borderColor),
    );

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F9FA),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 15),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF667985), size: 21),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border,
      border: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF1A536A), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomSpacing = (mediaQuery.viewPadding.bottom + 20).clamp(
      24.0,
      64.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF2F6F7),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                key: const Key('login-scroll-view'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: bottomSpacing),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        Container(
                          key: const Key('login-brand-header'),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF12384B), Color(0xFF24657C)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(32),
                            ),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/logo_howe_branding.png',
                                    width: 190,
                                    height: 46,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Selamat datang kembali',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Masuk untuk melanjutkan aktivitas Anda.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              key: const Key('login-form-card'),
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                22,
                                20,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE6ECEF),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x120C2C3A),
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _LoginFieldLabel('Alamat email'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: const Key('login-email-field'),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: _fieldDecoration(
                                      hintText: 'contoh@email.com',
                                      prefixIcon: Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const _LoginFieldLabel('Kata sandi'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: const Key('login-password-field'),
                                    controller: _passwordController,
                                    obscureText: _isPasswordObscured,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading && !_isGoogleLoading) {
                                        _performLogin();
                                      }
                                    },
                                    decoration: _fieldDecoration(
                                      hintText: 'Masukkan kata sandi',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        tooltip: _isPasswordObscured
                                            ? 'Tampilkan kata sandi'
                                            : 'Sembunyikan kata sandi',
                                        icon: Icon(
                                          _isPasswordObscured
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF667985),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordObscured =
                                                !_isPasswordObscured;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF1A536A,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: const Text(
                                        'Lupa kata sandi?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      key: const Key('login-submit-button'),
                                      onPressed: _isLoading || _isGoogleLoading
                                          ? null
                                          : _performLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A374D,
                                        ),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: const Color(
                                          0xFF9AA8B0,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                key: ValueKey('login-loading'),
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                key: ValueKey('login-label'),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const _LoginDivider(),
                                  const SizedBox(height: 18),
                                  GoogleAuthButton(
                                    label: 'Lanjutkan dengan Google',
                                    isLoading: _isGoogleLoading,
                                    onPressed: _isLoading
                                        ? null
                                        : _performGoogleAuth,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    key: const Key('login-register-footer'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          'Belum punya akun?',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            _isLoading || _isGoogleLoading
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SelectRolePage(),
                                                  ),
                                                );
                                              },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF1A536A,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginFieldLabel extends StatelessWidget {
  const _LoginFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF263842),
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  const _LoginDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFDDE5E8))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau masuk dengan',
            style: TextStyle(color: Color(0xFF8391A1), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFDDE5E8))),
      ],
    );
  }
}
