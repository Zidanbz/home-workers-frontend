import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';

void main() {
  test('wallet membaca saldo negatif dan alasan blokir pencairan', () {
    final wallet = Wallet.fromJson({
      'currentBalance': -40000,
      'heldBalance': 0,
      'withdrawalBlocked': true,
      'withdrawalBlockedReason':
          'Pencairan diblokir sampai kewajiban diselesaikan.',
      'transactions': [
        {
          'id': 'refund-1',
          'type': 'refund-debit',
          'amount': 40000,
          'description': 'Penyesuaian refund',
          'status': 'success',
          'timestamp': {'_seconds': 1},
        },
      ],
    });

    expect(wallet.currentBalance, -40000);
    expect(wallet.withdrawalBlocked, isTrue);
    expect(wallet.transactions.single.type, 'refund-debit');
  });

  test('transaksi membaca snapshot rincian payout tanpa menghitung ulang', () {
    final transaction = Transaction.fromJson({
      'id': 'order-order-1-completion',
      'type': 'cash-in',
      'amount': 132000,
      'grossAmount': 165000,
      'initialGrossAmount': 15000,
      'finalGrossAmount': 150000,
      'customerPaidAmount': 132000,
      'voucherDiscountAmount': 33000,
      'platformAmount': 33000,
      'platformNetAmount': 0,
      'orderId': 'order-1',
      'status': 'success',
      'description': 'Pembayaran dari Order #order-1 (80%)',
      'timestamp': {'_seconds': 10},
      'paymentBreakdown': {
        'initial': {'serviceAmount': 15000},
        'final_quote': {'serviceAmount': 150000},
      },
    });

    expect(transaction.isIncome, isTrue);
    expect(transaction.hasPayoutBreakdown, isTrue);
    expect(transaction.orderId, 'order-1');
    expect(transaction.grossAmount, 165000);
    expect(transaction.voucherDiscountAmount, 33000);
    expect(transaction.platformAmount, 33000);
    expect(transaction.platformFeePercent, 20);
    expect(transaction.paymentBreakdown, contains('final_quote'));
  });
}
