import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/kyc_revision_model.dart';

void main() {
  test('mem-parsing permintaan revisi KYC beserta checklist Admin', () {
    final status = KycRevisionStatus.fromJson({
      'status': 'revision_required',
      'canAccessApp': false,
      'revisionCount': 2,
      'review': {
        'id': 'review-1',
        'version': 3,
        'status': 'revision_required',
        'corrections': [
          {
            'field': 'ktp',
            'reasonCode': 'BLURRY',
            'note': 'Pantulan cahaya menutup NIK',
          },
        ],
      },
    });

    expect(status.status, 'revision_required');
    expect(status.canAccessApp, isFalse);
    expect(status.revisionCount, 2);
    expect(status.review?.version, 3);
    expect(status.review?.corrections.single.field, 'ktp');
    expect(
      status.review?.corrections.single.note,
      'Pantulan cahaya menutup NIK',
    );
  });
}
