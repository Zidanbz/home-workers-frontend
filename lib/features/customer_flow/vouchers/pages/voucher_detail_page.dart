import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherDetailPage extends StatelessWidget {
  final Map<String, dynamic> voucher;

  const VoucherDetailPage({super.key, required this.voucher});

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tidak tersedia';
    try {
      if (date is DateTime) {
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      }
      return 'Tidak tersedia';
    } catch (e) {
      return 'Tidak tersedia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = voucher['code'] ?? '';
    final discountType = voucher['discountType'] ?? 'percent';
    final value = voucher['value'] ?? 0;
    final minOrder = voucher['minOrder'] ?? 0;
    final maxDiscount = voucher['maxDiscount'] ?? 0;
    final startDate = voucher['startDate'];
    final endDate = voucher['endDate'];
    final type = voucher['type'] ?? 'global';
    final status = voucher['status'] ?? 'active';
    final claimedAt = voucher['claimedAt'];
    final used = voucher['used'] ?? false;

    final discountText = discountType == 'percent'
        ? '${value}%'
        : _formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Detail Voucher',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A374D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1A374D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voucher Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: type == 'user_claimed'
                      ? [const Color(0xFF6C63FF), const Color(0xFF5A52D5)]
                      : [const Color(0xFF4CAF50), const Color(0xFF45A049)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (type == 'user_claimed' ? const Color(0xFF6C63FF) : const Color(0xFF4CAF50))
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type == 'user_claimed' ? 'SUDAH DIKLAIM' : 'VOUCHER GLOBAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Discount Info
            _buildInfoCard(
              icon: Icons.discount,
              title: 'Diskon',
              value: discountText,
            ),

            const SizedBox(height: 16),

            // Min Order
            _buildInfoCard(
              icon: Icons.shopping_cart,
              title: 'Minimal Order',
              value: _formatCurrency(minOrder),
            ),

            const SizedBox(height: 16),

            // Max Discount
            if (discountType == 'percent')
              _buildInfoCard(
                icon: Icons.price_check,
                title: 'Maksimal Diskon',
                value: _formatCurrency(maxDiscount),
              ),

            const SizedBox(height: 16),

            // Validity Period
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Periode Berlaku',
              value: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            ),

            const SizedBox(height: 16),

            // Status
            _buildInfoCard(
              icon: status == 'active' ? Icons.check_circle : Icons.cancel,
              title: 'Status',
              value: status == 'active' ? 'Aktif' : 'Tidak Aktif',
              valueColor: status == 'active' ? Colors.green : Colors.red,
            ),

            // User specific info
            if (type == 'user_claimed') ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.access_time,
                title: 'Tanggal Klaim',
                value: _formatDate(claimedAt),
              ),

              const SizedBox(height: 16),
              _buildInfoCard(
                icon: used ? Icons.check_circle : Icons.radio_button_unchecked,
                title: 'Status Penggunaan',
                value: used ? 'Sudah Digunakan' : 'Belum Digunakan',
                valueColor: used ? Colors.blue : Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A374D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1A374D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1A374D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
