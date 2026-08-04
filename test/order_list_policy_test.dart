import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/utils/order_list_policy.dart';

void main() {
  test('order pending dengan refund aktif dipindahkan ke riwayat', () {
    expect(
      shouldShowCustomerOrderInOngoing(
        orderStatus: 'pending',
        refundStatus: 'under_review',
      ),
      isFalse,
    );
    expect(
      shouldShowCustomerOrderInHistory(
        orderStatus: 'pending',
        refundStatus: 'under_review',
      ),
      isTrue,
    );
    expect(
      effectiveCustomerOrderListStatus(
        orderStatus: 'pending',
        refundStatus: 'under_review',
      ),
      'refund:under_review',
    );
  });

  test('refund ditolak membuat order pending kembali ke mendatang', () {
    expect(
      shouldShowCustomerOrderInOngoing(
        orderStatus: 'pending',
        refundStatus: 'rejected',
      ),
      isTrue,
    );
    expect(
      shouldShowCustomerOrderInHistory(
        orderStatus: 'pending',
        refundStatus: 'rejected',
      ),
      isFalse,
    );
  });

  test('perbaikan ulang tetap menjadi pekerjaan aktif', () {
    expect(
      shouldShowCustomerOrderInOngoing(
        orderStatus: 'work_in_progress',
        refundStatus: 'rework_in_progress',
      ),
      isTrue,
    );
    expect(
      effectiveCustomerOrderListStatus(
        orderStatus: 'work_in_progress',
        refundStatus: 'rework_in_progress',
      ),
      'refund:rework_in_progress',
    );
  });
}
