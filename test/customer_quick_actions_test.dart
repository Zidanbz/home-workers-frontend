import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/customer_flow/dashboard/widgets/customer_quick_actions.dart';

void main() {
  testWidgets('quick actions menampilkan hierarki dan menjalankan callback', (
    tester,
  ) async {
    var marketplaceTaps = 0;
    var orderTaps = 0;
    var nearbyTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: CustomerQuickActions(
                marketplaceKey: const ValueKey('marketplace-action'),
                ordersKey: const ValueKey('orders-action'),
                onMarketplaceTap: () => marketplaceTaps += 1,
                onOrdersTap: () => orderTaps += 1,
                onNearbyTap: () => nearbyTaps += 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cari Penyedia Jasa'), findsOneWidget);
    expect(find.text('Riwayat Pesanan'), findsOneWidget);
    expect(find.text('Cari di Sekitar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('marketplace-action')));
    await tester.tap(find.byKey(const ValueKey('orders-action')));
    await tester.tap(find.byKey(const ValueKey('customer-nearby-action')));

    expect(marketplaceTaps, 1);
    expect(orderTaps, 1);
    expect(nearbyTaps, 1);
  });

  testWidgets('quick actions tidak overflow pada layar kecil dan teks besar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.35),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomerQuickActions(
                  onMarketplaceTap: () {},
                  onOrdersTap: () {},
                  onNearbyTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cari di Sekitar'), findsOneWidget);
  });
}
