import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/refund_model.dart';

void main() {
  test('RefundRequest mem-parsing status dan bukti customer', () {
    final refund = RefundRequest.fromJson({
      'id': 'refund-1',
      'orderId': 'order-1',
      'status': 'under_review',
      'reasonCode': 'work_not_as_agreed',
      'resolutionRequested': 'partial_refund',
      'description':
          'Hasil pekerjaan belum sesuai dengan kesepakatan awal customer.',
      'paymentTarget': 'initial',
      'requestedAmount': 25000,
      'evidenceRequestedFrom': 'customer',
      'customerEvidence': [
        {'originalName': 'bukti.jpg', 'url': 'https://example.test/bukti'},
      ],
    });

    expect(refund.isActive, isTrue);
    expect(refund.statusLabel, 'Sedang ditinjau Admin');
    expect(refund.customerEvidence.single.originalName, 'bukti.jpg');
    expect(refund.evidenceRequestedFrom, 'customer');
  });

  test('refund selesai tidak lagi dianggap aktif', () {
    final refund = RefundRequest.fromJson({
      'id': 'refund-2',
      'orderId': 'order-2',
      'status': 'refunded',
      'reasonCode': 'duplicate_payment',
      'resolutionRequested': 'full_refund',
      'description':
          'Pembayaran terproses dua kali untuk satu pesanan yang sama.',
      'paymentTarget': 'initial',
      'requestedAmount': 100000,
      'approvedAmount': 100000,
    });

    expect(refund.isActive, isFalse);
    expect(refund.statusLabel, 'Refund selesai');
  });
}
