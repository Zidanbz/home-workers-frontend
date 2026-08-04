import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/service_model.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/marketplace_detail_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('detail menampilkan nama layanan dan foto membuka viewer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = Service(
      id: 'service-1',
      namaLayanan: 'Perbaikan Plafon dan Pengecatan Rumah',
      category: 'Perbaikan',
      harga: 250000,
      fotoUtamaUrl: 'https://example.test/service-main.jpg',
      statusPersetujuan: 'approved',
      dibuatPada: DateTime(2026, 8, 4),
      photoUrls: const [
        'https://example.test/service-main.jpg',
        'https://example.test/service-second.jpg',
      ],
      metodePembayaran: const ['Cashless'],
      deskripsiLayanan: 'Perbaikan plafon rusak dan pengecatan ulang.',
      tipeLayanan: 'fixed',
      workerInfo: const {'nama': 'Budisanto', 'rating': 5.0, 'totalReviews': 1},
      availability: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerServiceDetailPage(
          serviceId: service.id,
          loadService: (_) async => service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbaikan Plafon dan Pengecatan Rumah'), findsOneWidget);
    expect(find.byKey(const ValueKey('service-detail-name')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('service-main-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('service-photo-viewer')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    final secondPhoto = find.byKey(const ValueKey('service-gallery-photo-1'));
    await tester.ensureVisible(secondPhoto);
    await tester.tap(secondPhoto);
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
