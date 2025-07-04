// Ini adalah contoh widget test yang lebih baik dan terstruktur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Impor halaman spesifik yang ingin kita tes
import 'package:home_workers_fe/features/auth/pages/welcome_page.dart';

void main() {
  // Kita bisa mengelompokkan tes untuk fitur tertentu
  group('Welcome Page Tests', () {
    // Kasus Tes 1: Memverifikasi bahwa halaman welcome menampilkan widget yang benar
    testWidgets('WelcomePage should display title and sign in button', (
      WidgetTester tester,
    ) async {
      // "Bangun" widget WelcomePage di dalam MaterialApp.
      // MaterialApp dibutuhkan untuk menyediakan konteks dasar seperti tema, arah teks, dll.
      // Ini mengisolasi WelcomePage dari logika startup di main.dart.
      await tester.pumpWidget(const MaterialApp(home: WelcomePage()));

      // Verifikasi bahwa judul utama "Sign In" ada di halaman.
      // findsAtLeastNWidgets(1) lebih baik daripada findsOneWidget jika ada teks yang sama
      // di tempat lain (misalnya di tombol).
      expect(find.text('Sign In'), findsAtLeastNWidgets(1));

      // Verifikasi bahwa teks deskripsi ada.
      expect(
        find.textContaining('Untuk menggunakan semua kemampuan'),
        findsOneWidget,
      );

      // Verifikasi bahwa tombol ElevatedButton dengan teks "Sign In" ada.
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    // Anda bisa menambahkan kasus tes lain di sini, misalnya:
    // testWidgets('tapping sign in button navigates to login page', (WidgetTester tester) async {
    //   // ... logika tes untuk navigasi ...
    // });
  });
}
