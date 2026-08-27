import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/utils/payment_status_policy.dart';

void main() {
  test('settlement pembayaran awal tidak melunasi final quote', () {
    expect(
      isVerifiedPaidPayment(
        requestedOrderId: 'quote_order-1',
        response: const {
          'order_id': 'order-1',
          'payment_target': 'initial',
          'transaction_status': 'settlement',
        },
      ),
      isFalse,
    );
  });

  test('final quote sukses hanya jika ID dan target persis sama', () {
    expect(
      isVerifiedPaidPayment(
        requestedOrderId: 'quote_order-1',
        response: const {
          'order_id': 'quote_order-1',
          'payment_target': 'final_quote',
          'transaction_status': 'settlement',
        },
      ),
      isTrue,
    );
  });

  test('status not_started tidak dianggap sukses atau gagal', () {
    const response = {
      'order_id': 'quote_order-1',
      'payment_target': 'final_quote',
      'transaction_status': 'not_started',
    };
    expect(
      isVerifiedPaidPayment(
        requestedOrderId: 'quote_order-1',
        response: response,
      ),
      isFalse,
    );
    expect(
      isVerifiedFailedPayment(
        requestedOrderId: 'quote_order-1',
        response: response,
      ),
      isFalse,
    );
  });
}
