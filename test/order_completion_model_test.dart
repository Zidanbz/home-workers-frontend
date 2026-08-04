import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/order_model.dart';

void main() {
  test('Order mem-parsing foto before dan after dari respons backend', () {
    final order = Order.fromJson({
      'id': 'order-1',
      'status': 'completion_submitted',
      'customerId': 'customer-1',
      'serviceName': 'Servis AC',
      'customerName': 'Customer',
      'customerAddress': 'Makassar',
      'category': 'Elektronik',
      'serviceType': 'fixed',
      'jadwalPerbaikan': '2026-07-25T02:00:00Z',
      'dibuatPada': '2026-07-24T02:00:00Z',
      'workStartSubmission': {
        'startedAt': '2026-07-25T02:30:00Z',
        'beforeEvidence': [
          {
            'url': 'https://example.test/before-1',
            'originalName': 'sebelum.jpg',
            'contentType': 'image/jpeg',
            'size': 900,
          },
        ],
      },
      'completionSubmission': {
        'note': 'AC sudah dibersihkan dan kembali dingin.',
        'submittedAt': '2026-07-25T03:00:00Z',
        'afterEvidence': [
          {
            'url': 'https://example.test/evidence-1',
            'originalName': 'hasil.jpg',
            'contentType': 'image/jpeg',
            'size': 1024,
          },
        ],
      },
      'payoutStatus': 'pending',
      'payoutAmount': 80000,
    });

    expect(order.status, 'completion_submitted');
    expect(
      order.completionSubmission?.note,
      'AC sudah dibersihkan dan kembali dingin.',
    );
    expect(order.completionSubmission?.evidence, hasLength(1));
    expect(
      order.completionSubmission?.afterEvidence.first.url,
      'https://example.test/evidence-1',
    );
    expect(order.workStartSubmission?.beforeEvidence, hasLength(1));
    expect(
      order.workStartSubmission?.beforeEvidence.first.url,
      'https://example.test/before-1',
    );
    expect(order.payoutAmount, 80000);
  });

  test('field evidence lama tetap dibaca sebagai foto after', () {
    final submission = CompletionSubmission.fromJson({
      'note': 'Pekerjaan legacy sudah selesai.',
      'evidence': [
        {
          'url': 'https://example.test/legacy',
          'originalName': 'legacy.jpg',
          'contentType': 'image/jpeg',
          'size': 100,
        },
      ],
    });

    expect(submission.afterEvidence, hasLength(1));
    expect(submission.afterEvidence.first.url, 'https://example.test/legacy');
  });

  test('Order lama tanpa bukti tetap dapat diparsing', () {
    final order = Order.fromJson({
      'id': 'order-lama',
      'status': 'completed',
      'customerId': 'customer-1',
      'serviceName': 'Layanan lama',
      'customerName': 'Customer',
      'customerAddress': 'Makassar',
      'category': 'Lainnya',
      'serviceType': 'fixed',
      'jadwalPerbaikan': '2026-07-20T02:00:00Z',
      'dibuatPada': '2026-07-19T02:00:00Z',
    });

    expect(order.completionSubmission, isNull);
    expect(order.status, 'completed');
  });

  test('Order mem-parsing deadline dan status penerimaan Worker', () {
    final order = Order.fromJson({
      'id': 'order-timeout',
      'status': 'pending',
      'customerId': 'customer-1',
      'serviceName': 'Servis AC',
      'customerName': 'Customer',
      'customerAddress': 'Makassar',
      'category': 'Elektronik',
      'serviceType': 'fixed',
      'jadwalPerbaikan': '2026-07-27T02:00:00Z',
      'dibuatPada': '2026-07-26T02:00:00Z',
      'workerAcceptanceStartedAt': '2026-07-26T02:05:00Z',
      'workerAcceptanceDeadlineAt': '2026-07-26T02:35:00Z',
      'workerAcceptanceState': 'waiting',
    });

    expect(order.workerAcceptanceState, 'waiting');
    expect(order.workerAcceptanceStartedAt, isNotNull);
    expect(order.workerAcceptanceDeadlineAt, isNotNull);
    expect(
      order.workerAcceptanceDeadlineAt!.difference(
        order.workerAcceptanceStartedAt!,
      ),
      const Duration(minutes: 30),
    );
  });

  test('hasil konfirmasi completion mem-parsing payout dan waktu server', () {
    final result = OrderCompletionConfirmation.fromJson({
      'alreadyCompleted': false,
      'status': 'completed',
      'workerAmount': 80000,
      'payoutStatus': 'held',
      'completedAt': {'_seconds': 1785852000},
      'payoutAvailableAt': {'_seconds': 1785938400},
    });

    expect(result.status, 'completed');
    expect(result.workerAmount, 80000);
    expect(result.payoutStatus, 'held');
    expect(result.completedAt, isNotNull);
    expect(
      result.payoutAvailableAt!.difference(result.completedAt!),
      const Duration(hours: 24),
    );
  });

  test('respons tanpa status payout mengikuti kebijakan payout langsung', () {
    final result = OrderCompletionConfirmation.fromJson({
      'alreadyCompleted': false,
      'workerAmount': 80000,
    });

    expect(result.status, 'completed');
    expect(result.payoutStatus, 'released');
  });
}
