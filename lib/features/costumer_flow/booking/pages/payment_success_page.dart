import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String paymentMethod;
  final num totalAmount;

  const PaymentSuccessPage({
    super.key,
    required this.paymentMethod,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final formatDate = DateFormat('dd MMM yyyy');
    final formatTime = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pembayaran Berhasil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pembayaran Anda telah berhasil diproses.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildSummaryCard(
                formatCurrency,
                formatDate.format(now),
                formatTime.format(now),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigasi ke halaman utama atau halaman riwayat pesanan
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    NumberFormat formatCurrency,
    String date,
    String time,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSummaryRow('Metode Pembayaran', paymentMethod),
            const Divider(height: 24),
            _buildSummaryRow(
              'Jumlah Total',
              formatCurrency.format(totalAmount),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Tanggal Bayar', date),
            const Divider(height: 24),
            _buildSummaryRow('Waktu Bayar', time),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
