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
}
