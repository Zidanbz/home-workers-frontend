import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/profile/pages/faq_page.dart';

void main() {
  testWidgets('tombol support membuka WhatsApp dengan nomor dan pesan', (
    tester,
  ) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      MaterialApp(
        home: FAQPage(
          launchSupportUrl: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Hubungi via WhatsApp'));
    await tester.pump();

    expect(launchedUri?.scheme, 'https');
    expect(launchedUri?.host, 'wa.me');
    expect(launchedUri?.path, '/6281313622428');
    expect(
      launchedUri?.queryParameters['text'],
      'Halo tim Home Workers, saya membutuhkan bantuan.',
    );
  });

  testWidgets('menampilkan pesan ketika WhatsApp gagal dibuka', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FAQPage(launchSupportUrl: (_) async => false)),
    );

    await tester.tap(find.text('Hubungi via WhatsApp'));
    await tester.pump();

    expect(find.text('Tidak bisa membuka WhatsApp.'), findsOneWidget);
  });
}
