import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/payment_invoice_model.dart';

void main() {
  test('PaymentInvoice mem-parsing snapshot pembayaran', () {
    final invoice = PaymentInvoice.fromJson({
      'id': 'order-1--initial',
      'invoiceNumber': 'INV-20260726-ABCDEF12-01',
      'orderId': 'order-1',
      'paymentTarget': 'initial',
      'status': 'paid',
      'currency': 'IDR',
      'subtotal': 100000,
      'discount': 10000,
      'total': 90000,
      'appliedVoucher': 'HEMAT10',
      'customer': {'name': 'Customer', 'email': 'customer@example.test'},
      'worker': {'name': 'Worker'},
      'service': {'name': 'Servis AC', 'type': 'fixed'},
      'payment': {
        'paymentType': 'bank_transfer',
        'transactionId': 'tx-1',
        'paidAt': '2026-07-26T02:00:00.000Z',
      },
    });

    expect(invoice.total, 90000);
    expect(invoice.paymentTargetLabel, 'Pembayaran Awal');
    expect(invoice.paymentTypeLabel, 'Transfer Bank / Virtual Account');
    expect(invoice.paidAt.year, 2026);
  });
}
