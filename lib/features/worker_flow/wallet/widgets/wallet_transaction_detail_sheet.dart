import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/models/wallet_model.dart';

Future<void> showWalletTransactionDetail(
  BuildContext context,
  Transaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WalletTransactionDetailSheet(transaction: transaction),
  );
}

class WalletTransactionDetailSheet extends StatelessWidget {
  const WalletTransactionDetailSheet({super.key, required this.transaction});

  final Transaction transaction;

  static const Color _navy = Color(0xFF1A374D);

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String get _typeLabel {
    switch (transaction.type) {
      case 'cash-in':
        return 'Pendapatan';
      case 'cash-in-hold':
        return 'Pendapatan tertahan';
      case 'cash-out':
        return 'Penarikan saldo';
      case 'refund-debit':
        return 'Penyesuaian refund';
      default:
        return 'Transaksi wallet';
    }
  }

  String get _statusLabel {
    switch (transaction.status.toLowerCase()) {
      case 'success':
      case 'confirmed':
      case 'completed':
        return 'Berhasil';
      case 'held':
        return 'Ditahan';
      case 'pending':
        return 'Diproses';
      case 'failed':
        return 'Gagal';
      default:
        return transaction.status;
    }
  }

  Color get _statusColor {
    switch (transaction.status.toLowerCase()) {
      case 'success':
      case 'confirmed':
      case 'completed':
        return const Color(0xFF16803B);
      case 'failed':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFFB54708);
    }
  }

  String get _platformFeeLabel {
    final percentage = transaction.platformFeePercent;
    if (percentage == null) return 'Biaya layanan';
    final rounded = percentage.roundToDouble();
    final value = (percentage - rounded).abs() < 0.01
        ? rounded.toInt().toString()
        : percentage.toStringAsFixed(1);
    return 'Biaya layanan ($value%)';
  }

  String _paymentTargetLabel(String value) {
    switch (value) {
      case 'initial':
        return 'Pembayaran awal';
      case 'final_quote':
        return 'Pembayaran final';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    final voucherAmount = transaction.voucherDiscountAmount ?? 0;
    final initialGross = transaction.initialGrossAmount ?? 0;
    final finalGross = transaction.finalGrossAmount ?? 0;
    final hasSurveyBreakdown = finalGross > 0;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction.isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _typeLabel,
                          style: const TextStyle(color: Color(0xFF667085)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Column(
                  children: [
                    if (transaction.isIncome &&
                        transaction.hasPayoutBreakdown) ...[
                      if (hasSurveyBreakdown) ...[
                        _MoneyRow(
                          label: 'Biaya survei',
                          value: _formatCurrency(initialGross),
                        ),
                        _MoneyRow(
                          label: 'Harga pekerjaan',
                          value: _formatCurrency(finalGross),
                        ),
                      ] else
                        _MoneyRow(
                          label: 'Nilai layanan',
                          value: _formatCurrency(
                            transaction.grossAmount ?? transaction.amount,
                          ),
                        ),
                      if (transaction.customerPaidAmount != null)
                        _MoneyRow(
                          label: 'Dibayar Customer',
                          value: _formatCurrency(
                            transaction.customerPaidAmount!,
                          ),
                        ),
                      if (voucherAmount > 0)
                        _MoneyRow(
                          label: 'Voucher ditanggung aplikasi',
                          value: _formatCurrency(voucherAmount),
                          valueColor: const Color(0xFF16803B),
                        ),
                      _MoneyRow(
                        label: _platformFeeLabel,
                        value:
                            '- ${_formatCurrency(transaction.platformAmount!)}',
                        valueColor: const Color(0xFFB42318),
                      ),
                      const Divider(height: 24),
                      _MoneyRow(
                        label: 'Pendapatan Worker',
                        value: _formatCurrency(transaction.amount),
                        emphasize: true,
                        valueColor: const Color(0xFF16803B),
                      ),
                    ] else ...[
                      _MoneyRow(
                        label: transaction.type == 'cash-out'
                            ? 'Nominal penarikan'
                            : transaction.type == 'refund-debit'
                            ? 'Pengurangan saldo'
                            : 'Nominal transaksi',
                        value: _formatCurrency(transaction.amount),
                        emphasize: true,
                        valueColor: transaction.isIncome
                            ? const Color(0xFF16803B)
                            : const Color(0xFFB42318),
                      ),
                    ],
                  ],
                ),
              ),
              if (voucherAmount > 0) ...[
                const SizedBox(height: 12),
                const _InfoBox(
                  icon: Icons.verified_outlined,
                  text:
                      'Voucher ditanggung aplikasi dan tidak mengurangi nilai layanan yang menjadi dasar pendapatan Worker.',
                  color: Color(0xFF16803B),
                ),
              ] else if (transaction.isIncome &&
                  !transaction.hasPayoutBreakdown) ...[
                const SizedBox(height: 12),
                const _InfoBox(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Rincian perhitungan tidak tersedia pada transaksi lama ini. Nominal pendapatan tetap mengikuti ledger wallet.',
                  color: Color(0xFF667085),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Informasi transaksi',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _DetailRow(label: 'Deskripsi', value: transaction.description),
              _DetailRow(
                label: 'Waktu',
                value: dateFormat.format(transaction.timestamp.toLocal()),
              ),
              if (transaction.orderId != null)
                _DetailRow(label: 'Order ID', value: transaction.orderId!),
              if (transaction.refundId != null)
                _DetailRow(label: 'Refund ID', value: transaction.refundId!),
              if (transaction.paymentTarget != null)
                _DetailRow(
                  label: 'Komponen refund',
                  value: _paymentTargetLabel(transaction.paymentTarget!),
                ),
              if (transaction.destination != null)
                _DetailRow(
                  label: 'Tujuan pencairan',
                  value: transaction.destination!,
                ),
              _DetailRow(
                label: 'Transaction ID',
                value: transaction.id.isEmpty ? '-' : transaction.id,
                selectable: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF475467),
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF101828),
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      color: Color(0xFF344054),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: style)
                : Text(value, style: style),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
