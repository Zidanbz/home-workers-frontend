import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/main_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String? orderId;
  final Map<String, String>? redirectParams;

  const PaymentSuccessPage({super.key, this.orderId, this.redirectParams});

  void _goToOrders(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = (authProvider.user?.role ?? 'CUSTOMER').toUpperCase();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainPage(userRole: role, initialIndex: 2),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F7EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1E8E3E),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pesanan Berhasil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A374D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pembayaran sudah berhasil diproses. Pesanan kamu sedang kami siapkan dan bisa dilihat di halaman pesanan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToOrders(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A374D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Lihat Pesanan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
