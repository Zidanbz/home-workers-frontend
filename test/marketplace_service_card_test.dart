import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/service_model.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/widgets/marketplace_service_card.dart';

void main() {
  test('model layanan membaca informasi jarak yang aman untuk Customer', () {
    final service = Service.fromJson({
      'serviceId': 'service-nearby',
      'namaLayanan': 'Perawatan AC',
      'category': 'Perawatan',
      'distanceKm': 2.4,
      'operationalAreaLabel': 'Panakkukang, Makassar',
      'isWithinServiceRadius': true,
    });

    expect(service.distanceKm, 2.4);
    expect(service.operationalAreaLabel, 'Panakkukang, Makassar');
    expect(service.isWithinServiceRadius, isTrue);
  });

  testWidgets('card marketplace tetap rapi untuk informasi layanan panjang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = Service(
      id: 'service-test',
      namaLayanan: 'Perawatan dan Pembersihan Peralatan Rumah Tangga',
      category: 'Perbaikan dan Perawatan Rumah',
      harga: 150000,
      fotoUtamaUrl: '',
      statusPersetujuan: 'approved',
      dibuatPada: DateTime(2026, 7, 26),
      photoUrls: const [],
      metodePembayaran: const ['Cashless', 'Transfer Bank'],
      deskripsiLayanan: 'Layanan pengujian card marketplace.',
      tipeLayanan: 'fixed',
      workerInfo: const {
        'nama': 'Nama Worker Pengujian yang Sangat Panjang',
        'rating': 4.8,
      },
      availability: const [],
      distanceKm: 2.4,
      operationalAreaLabel: 'Panakkukang, Makassar',
      isWithinServiceRadius: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MarketplaceServiceCard(service: service),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Harga layanan'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(
      find.byKey(const ValueKey('marketplace-distance-info')),
      findsOneWidget,
    );
    expect(
      find.text('2,4 km • Panakkukang, Makassar • Menjangkau alamat Anda'),
      findsOneWidget,
    );

    final cardRect = tester.getRect(find.byType(MarketplaceServiceCard));
    final paymentRect = tester.getRect(
      find.byKey(const ValueKey('marketplace-payment-chip')),
    );
    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('marketplace-detail-button')),
    );
    expect(buttonRect.left - paymentRect.right, 6);
    expect(cardRect.right - buttonRect.right, closeTo(15, 0.1));
    expect(tester.takeException(), isNull);
  });
}
