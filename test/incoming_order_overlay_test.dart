import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/utils/incoming_order_policy.dart';
import 'package:home_workers_fe/features/worker_flow/order_management/widgets/incoming_order_overlay.dart';
import 'package:intl/date_symbol_data_local.dart';

Order _order({
  String workerId = 'worker-1',
  String status = 'pending',
  String paymentStatus = 'paid',
  bool workerAccess = true,
  String workerAcceptanceState = 'waiting',
  DateTime? deadline,
}) {
  final now = DateTime(2026, 8, 23, 13);
  return Order(
    id: 'order-1',
    status: status,
    jadwalPerbaikan: DateTime(2026, 8, 24, 9),
    dibuatPada: now,
    serviceName: 'Perbaikan AC',
    customerName: 'Customer',
    customerAddress: 'Alamat lengkap tidak ditampilkan pada kartu',
    customerId: 'customer-1',
    category: 'Elektronik',
    serviceType: 'fixed',
    hasBeenReviewed: false,
    workerId: workerId,
    quotedPrice: 150000,
    paymentStatus: paymentStatus,
    workerAccess: workerAccess,
    workerAcceptanceState: workerAcceptanceState,
    workerAcceptanceDeadlineAt:
        deadline ?? now.add(const Duration(minutes: 30)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  test(
    'order incoming wajib milik Worker, paid, pending, dan belum expired',
    () {
      final now = DateTime(2026, 8, 23, 13);
      final validOrder = _order(deadline: now.add(const Duration(minutes: 30)));

      expect(
        isIncomingOrderEligible(validOrder, workerId: 'worker-1', now: now),
        isTrue,
      );
      expect(
        isIncomingOrderEligible(
          _order(paymentStatus: 'unpaid'),
          workerId: 'worker-1',
          now: now,
        ),
        isFalse,
      );
      expect(
        isIncomingOrderEligible(validOrder, workerId: 'worker-lain', now: now),
        isFalse,
      );
      expect(
        isIncomingOrderEligible(
          _order(deadline: now.subtract(const Duration(seconds: 1))),
          workerId: 'worker-1',
          now: now,
        ),
        isFalse,
      );
    },
  );

  test('countdown memakai format menit dan jam yang stabil', () {
    expect(
      incomingOrderCountdown(const Duration(minutes: 4, seconds: 9)),
      '04:09',
    );
    expect(
      incomingOrderCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(incomingOrderCountdown(Duration.zero), '00:00');
  });

  testWidgets('floating card menampilkan ringkasan aman dan membuka detail', (
    tester,
  ) async {
    var opened = false;
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: IncomingOrderCard(
              order: _order(),
              remaining: const Duration(minutes: 12, seconds: 5),
              queuedOrderCount: 1,
              onDismiss: () => dismissed = true,
              onOpen: () => opened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('incoming-order-card')), findsOneWidget);
    expect(find.text('Pesanan baru masuk'), findsOneWidget);
    expect(find.text('Perbaikan AC'), findsOneWidget);
    expect(find.text('12:05'), findsOneWidget);
    expect(find.textContaining('Alamat lengkap'), findsNothing);

    await tester.tap(find.byKey(const Key('incoming-order-open')));
    expect(opened, isTrue);
    await tester.tap(find.byKey(const Key('incoming-order-later')));
    expect(dismissed, isTrue);
  });
}
