import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/worker_flow/dashboard/widgets/worker_dashboard_overview.dart';
import 'package:home_workers_fe/features/worker_flow/dashboard/widgets/worker_review_section.dart';

void main() {
  testWidgets(
    'ringkasan Worker menampilkan prioritas dan metrik tanpa duplikasi',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: WorkerDashboardOverview(
                  pendingOrders: 3,
                  acceptedOrders: 2,
                  completedOrders: 18,
                  rating: 4.8,
                  operationalArea: 'Makassar dan sekitarnya',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pesanan perlu respons'), findsOneWidget);
      expect(
        find.text('3 pesanan sedang menunggu keputusan Anda.'),
        findsOneWidget,
      );
      expect(find.text('Ringkasan pekerjaan'), findsOneWidget);
      expect(find.text('Berjalan'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('Total Selesai'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ringkasan dan ulasan tetap rapi pada layar kecil dan teks besar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const WorkerDashboardOverview(
                    pendingOrders: 0,
                    acceptedOrders: 12,
                    completedOrders: 125,
                    rating: 5,
                    operationalArea:
                        'Area operasional yang sangat panjang untuk pengujian',
                  ),
                  const SizedBox(height: 24),
                  WorkerReviewSection(
                    reviews: [
                      {
                        'customerName':
                            'Nama pelanggan yang sangat panjang untuk pengujian',
                        'customerAvatarUrl':
                            'http://alamat-tidak-aman.test/a.jpg',
                        'rating': 5,
                        'comment': 'Pekerjaan rapi dan selesai tepat waktu.',
                        'createdAt': '2026-08-23T03:20:00.000Z',
                        'verified': true,
                      },
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Belum ada pesanan yang menunggu saat ini.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
