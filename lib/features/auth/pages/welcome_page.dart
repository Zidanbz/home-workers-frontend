// lib/features/auth/pages/welcome_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/auth_provider.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Ganti dengan path aset Anda
              Image.asset(
                'assets/splash.png',
                height: 300,
              ),
              const SizedBox(height: 48),
              const Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E232C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Untuk menggunakan semua kemampuan\nyang tersedia dalam aplikasi, Anda perlu\nlogin terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF8391A1)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // --- PERUBAHAN UTAMA ---
                  Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).showLoginPage();
                },
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
