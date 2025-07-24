import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Penting untuk Firebase Auth
import 'package:home_workers_fe/features/auth/pages/login_page.dart'; // Import Login Page

class EmailVerificationPendingPage extends StatefulWidget {
  final String email;

  const EmailVerificationPendingPage({super.key, required this.email});

  @override
  State<EmailVerificationPendingPage> createState() =>
      _EmailVerificationPendingPageState();
}

class _EmailVerificationPendingPageState
    extends State<EmailVerificationPendingPage> {
  // Color Palette (sesuaikan dengan RegisterWorkerPage jika perlu)
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color secondaryColor = Color(0xFFD9D9D9);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF406882);

  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Opsional: Anda bisa mulai cek status verifikasi email di sini secara berkala
    // atau hanya bergantung pada tombol "Saya Sudah Verifikasi"
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _showCustomSnackBar(
          'Email verifikasi telah dikirim ulang!',
          isError: false,
        );
      } else {
        _showCustomSnackBar(
          'Tidak ada pengguna yang login. Silakan coba login kembali.',
          isError: true,
        );
        // Mungkin arahkan kembali ke login page jika user null
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _showCustomSnackBar('Gagal mengirim ulang email: $e', isError: true);
      print('Error resending verification email: $e');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  // Fungsi SnackBar yang sama dengan di RegisterWorkerPage
  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: primaryColor,
                size: 100,
              ),
              const SizedBox(height: 32),
              const Text(
                'Verifikasi Email Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kami telah mengirim email verifikasi ke ${widget.email}. Harap cek kotak masuk Anda (dan folder spam) untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Ulang Email Verifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Saat user klik ini, dia akan kembali ke halaman login.
                  // Di halaman login, saat dia mencoba login, status emailVerified
                  // akan diperiksa lagi (sesuai modifikasi backend kita sebelumnya).
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  'Saya Sudah Verifikasi, Lanjutkan ke Login',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
