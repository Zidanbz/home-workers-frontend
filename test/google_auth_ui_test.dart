import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/auth/pages/worker_registration_status_page.dart';

void main() {
  testWidgets('pending worker melihat status verifikasi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WorkerRegistrationStatusPage()),
    );

    expect(find.text('Registrasi Sedang Diverifikasi'), findsOneWidget);
    expect(find.text('Kembali ke Login'), findsOneWidget);
  });

  testWidgets('rejected worker melihat alasan penolakan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkerRegistrationStatusPage(
          status: 'rejected',
          rejectionReason: 'Foto KTP tidak terbaca.',
        ),
      ),
    );

    expect(find.text('Registrasi Worker Ditolak'), findsOneWidget);
    expect(find.text('Foto KTP tidak terbaca.'), findsOneWidget);
  });
}
