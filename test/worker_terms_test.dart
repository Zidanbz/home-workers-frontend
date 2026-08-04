import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/legal/worker_terms.dart';
import 'package:home_workers_fe/features/legal/pages/worker_terms_page.dart';

void main() {
  test('dokumen Worker memiliki versi dan isi substantif', () {
    expect(WorkerTerms.version, 'worker-2026-07-28-v1');
    expect(WorkerTerms.sections.length, greaterThanOrEqualTo(10));
    expect(WorkerTerms.plainText.length, greaterThan(4000));
    expect(WorkerTerms.plainText, contains('Pembatalan, refund, garansi'));
    expect(WorkerTerms.plainText, contains('Data pribadi dan lokasi'));
  });

  testWidgets('halaman menampilkan versi dan konfirmasi setelah isi dokumen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WorkerTermsPage()));

    expect(find.text('Syarat & Ketentuan Worker'), findsOneWidget);
    expect(find.textContaining('Versi ${WorkerTerms.version}'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Saya Sudah Membaca'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Saya Sudah Membaca'), findsOneWidget);
  });
}
