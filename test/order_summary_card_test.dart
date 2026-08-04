import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/shared_widgets/order_summary_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('card pesanan bersama tetap rapi dan meneruskan aksi role', (
    tester,
  ) async {
    await initializeDateFormatting('id_ID');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var cardTapped = false;
    var actionTapped = false;
    final order = Order(
      id: 'order-reusable-card',
      status: 'pending',
      jadwalPerbaikan: DateTime(2026, 7, 26, 13, 30),
      dibuatPada: DateTime(2026, 7, 25),
      serviceName: 'Perbaikan Instalasi Listrik Rumah',
      customerName: 'Customer Pengujian',
      customerAddress: 'Makassar',
      customerId: 'customer-1',
      category: 'Perbaikan',
      serviceType: 'fixed',
      hasBeenReviewed: false,
      quotedPrice: 150000,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id', 'ID'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OrderSummaryCard(
                order: order,
                status: const OrderSummaryStatus(
                  label: 'Pesanan Baru',
                  color: Color(0xFFB76E00),
                  icon: Icons.notifications_active_outlined,
                ),
                onTap: () => cardTapped = true,
                action: OrderSummaryAction(
                  label: 'Tindak Lanjut',
                  icon: Icons.verified_user_outlined,
                  onPressed: () => actionTapped = true,
                  foregroundColor: const Color(0xFF16835D),
                  backgroundColor: const Color(0xFFE8F7EF),
                ),
                supportingLabel: 'Customer • Customer Pengujian',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pesanan Baru'), findsOneWidget);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text('Customer • Customer Pengujian'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tindak Lanjut'));
    await tester.pump();
    expect(actionTapped, isTrue);

    await tester.tap(find.text('Perbaikan Instalasi Listrik Rumah'));
    await tester.pump();
    expect(cardTapped, isTrue);
  });
}
