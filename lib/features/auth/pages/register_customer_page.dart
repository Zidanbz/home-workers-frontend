import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/services/google_auth_service.dart';
import 'package:home_workers_fe/core/widgets/google_auth_button.dart';
import 'package:home_workers_fe/features/main_page.dart';
import 'package:home_workers_fe/features/auth/pages/worker_registration_status_page.dart';

// Import AuthProvider kustom Anda dengan alias untuk menghindari konflik
import '../../../core/state/auth_provider.dart' as AppAuthProvider;

// Import halaman baru untuk verifikasi email
import 'email_verification_pending_page.dart';
import 'login_page.dart'; // Sudah ada, pastikan
import '../../../core/utils/contact_input_policy.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({
    super.key,
    this.googleRegistration = false,
    this.initialName,
    this.initialEmail,
  });

  final bool googleRegistration;
  final String? initialName;
  final String? initialEmail;

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AppAuthProvider.AuthProvider>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nama = _namaController.text.trim();
    final contact = _contactController.text.trim();

    try {
      if (widget.googleRegistration) {
        await authProvider.registerGoogleCustomer(nama: nama, contact: contact);
      } else {
        await authProvider.registerCustomer(
          email: email,
          password: password,
          nama: nama,
          contact: contact,
          // fcmToken opsional; kalau null nanti provider ambil sendiri
        );
      }

      if (!mounted) return;

      if (widget.googleRegistration) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainPage(userRole: 'CUSTOMER'),
          ),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Registrasi berhasil! Cek email untuk verifikasi.'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerificationPendingPage(email: email),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            ApiService.readableError(e, action: 'Registrasi customer gagal'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authProvider = context.read<AppAuthProvider.AuthProvider>();
    setState(() => _isGoogleLoading = true);
    try {
      final result = await authProvider.authenticateWithGoogle();
      if (!mounted) return;

      if (result.nextAction == AppAuthProvider.GoogleAuthNextAction.openApp) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                MainPage(userRole: authProvider.user?.role ?? 'CUSTOMER'),
          ),
          (_) => false,
        );
        return;
      }

      if (result.nextAction ==
          AppAuthProvider.GoogleAuthNextAction.selectRole) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => RegisterCustomerPage(
              googleRegistration: true,
              initialName: result.nama,
              initialEmail: result.email,
            ),
          ),
          (_) => false,
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => WorkerRegistrationStatusPage(
            status:
                result.nextAction ==
                    AppAuthProvider.GoogleAuthNextAction.showRejection
                ? 'rejected'
                : (result.workerStatus ?? 'pending'),
            rejectionReason: result.rejectionReason,
          ),
        ),
        (_) => false,
      );
    } on GoogleSignInCancelledException {
      // User menutup pemilih akun.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            ApiService.readableError(e, action: 'Registrasi Google gagal'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // Hapus _showSuccessDialog() atau pastikan tidak dipanggil lagi
  // karena navigasi ke EmailVerificationPendingPage sudah menggantikannya.
  // ... (bagian _showSuccessDialog yang lama) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        title: const Text('Daftar Akun Customer'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            if (widget.googleRegistration) {
              await context
                  .read<AppAuthProvider.AuthProvider>()
                  .cancelGoogleRegistration();
            }
            if (!context.mounted) return;
            Provider.of<AppAuthProvider.AuthProvider>(
              context,
              listen: false,
            ).showWelcomePage();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Buat Akun Anda',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A374D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mulai perjalanan Anda bersama kami.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          readOnly: widget.googleRegistration,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email wajib diisi';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp',
                            hintText: '081234567890',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: validateIndonesianWhatsApp,
                        ),
                        if (!widget.googleRegistration) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordObscured = !_isPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 6
                                ? 'Password minimal 6 karakter'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 32),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF1A374D),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.googleRegistration
                                      ? 'Selesaikan Pendaftaran'
                                      : 'Daftar Sekarang',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                        if (!widget.googleRegistration) ...[
                          const SizedBox(height: 14),
                          GoogleAuthButton(
                            label: 'Daftar dengan Google',
                            isLoading: _isGoogleLoading,
                            onPressed: _isLoading
                                ? null
                                : _handleGoogleRegister,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                  children: [
                    const TextSpan(text: 'Sudah punya akun? '),
                    TextSpan(
                      text: 'Login di sini',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (widget.googleRegistration) {
                            await context
                                .read<AppAuthProvider.AuthProvider>()
                                .cancelGoogleRegistration();
                          }
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
