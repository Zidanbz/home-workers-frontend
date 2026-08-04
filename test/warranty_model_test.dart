import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/warranty_model.dart';

void main() {
  test('OrderWarranty mem-parsing eligibility dan klaim aktif', () {
    final model = OrderWarranty.fromJson({
      'eligibility': {
        'eligible': false,
        'reason': 'Masih ada klaim aktif.',
        'startedAt': '2026-07-20T00:00:00.000Z',
        'expiresAt': '2026-07-27T00:00:00.000Z',
        'claimCount': 1,
        'maxClaims': 2,
      },
      'claim': {
        'id': 'warranty-1',
        'orderId': 'order-1',
        'status': 'repair_in_progress',
        'issueType': 'same_issue',
        'description':
            'Masalah yang sama muncul kembali setelah pekerjaan selesai.',
        'customerEvidence': [
          {'url': 'https://example.test/customer.jpg', 'size': 1200},
        ],
        'repair': {
          'beforeEvidence': [
            {'url': 'https://example.test/before.jpg', 'size': 1400},
          ],
          'afterEvidence': [],
        },
      },
    });

    expect(model.eligibility.eligible, isFalse);
    expect(model.eligibility.claimCount, 1);
    expect(model.claim?.isActive, isTrue);
    expect(model.claim?.statusLabel, 'Perbaikan Berlangsung');
    expect(model.claim?.customerEvidence, hasLength(1));
    expect(model.claim?.repair?.beforeEvidence, hasLength(1));
  });
}
