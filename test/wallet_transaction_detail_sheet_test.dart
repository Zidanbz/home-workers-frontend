import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';
import 'package:home_workers_fe/features/worker_flow/wallet/widgets/wallet_transaction_detail_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('detail payout menjelaskan voucher dan biaya layanan', (
    tester,
  ) async {
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
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalletTransactionDetailSheet(transaction: transaction),
        ),
      ),
    );

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Biaya survei'), findsOneWidget);
    expect(find.text('Harga pekerjaan'), findsOneWidget);
    expect(find.text('Voucher ditanggung aplikasi'), findsOneWidget);
    expect(find.text('Biaya layanan (20%)'), findsOneWidget);
    expect(find.text('Pendapatan Worker'), findsOneWidget);
    expect(find.text('order-1'), findsOneWidget);
  });

  testWidgets('transaksi lama tetap memiliki detail nominal', (tester) async {
    final transaction = Transaction.fromJson({
      'id': 'legacy-1',
      'type': 'cash-in',
      'amount': 64000,
      'status': 'success',
      'description': 'Pembayaran lama',
      'timestamp': {'_seconds': 10},
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalletTransactionDetailSheet(transaction: transaction),
        ),
      ),
    );

    expect(find.text('Nominal transaksi'), findsOneWidget);
    expect(
      find.textContaining('Rincian perhitungan tidak tersedia'),
      findsOneWidget,
    );
    expect(find.text('legacy-1'), findsOneWidget);
  });
}
