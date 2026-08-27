import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/refund_request_sheet.dart';

void main() {
  testWidgets('refund memakai wizard dan memvalidasi setiap langkah', (
    tester,
  ) async {
    final order = Order(
      id: 'order-test',
      status: 'pending',
      jadwalPerbaikan: DateTime(2026, 7, 26),
      dibuatPada: DateTime(2026, 7, 25),
      serviceName: 'Servis AC',
      customerName: 'Customer',
      customerAddress: 'Makassar',
      customerId: 'customer-1',
      category: 'Perbaikan',
      serviceType: 'fixed',
      hasBeenReviewed: false,
      paymentStatus: 'paid',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefundRequestSheet(
            order: order,
            onSubmit:
                ({
                  required reasonCode,
                  required resolutionRequested,
                  required description,
                  required paymentTarget,
                  required contactedWorker,
                  required declarationAccepted,
                  requestedAmount,
                  required evidence,
                }) async {},
          ),
        ),
      ),
    );

    expect(find.text('Apa yang terjadi?'), findsOneWidget);
    expect(find.text('Pilih solusi'), findsNothing);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();
    expect(find.text('Kronologi masalah minimal 50 karakter.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Worker tidak datang sesuai jadwal dan tidak memberikan kabar kepada Customer.',
    );
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih solusi'), findsOneWidget);
    expect(find.text('Perbaikan ulang pekerjaan'), findsNothing);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Periksa pengajuan'), findsOneWidget);
    expect(find.text('Saya sudah mencoba menghubungi Worker.'), findsNothing);
    expect(
      find.text('Saya menyatakan data dan bukti yang dikirim adalah benar.'),
      findsOneWidget,
    );
  });
}
