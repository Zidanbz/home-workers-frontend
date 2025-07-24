import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:provider/provider.dart';

class ClaimVoucherPage extends StatefulWidget {
  const ClaimVoucherPage({super.key});

  @override
  State<ClaimVoucherPage> createState() => _ClaimVoucherPageState();
}

class _ClaimVoucherPageState extends State<ClaimVoucherPage> {
  final _controller = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleClaim() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anda belum login.')));
      return;
    }
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan kode voucher.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.claimVoucher(
        token: token,
        voucherCode: code,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voucher berhasil diklaim! Diskon: Rp ${result['discount'] ?? 0}',
          ),
        ),
      );
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Voucher'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Kode Voucher',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E232C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Klaim Voucher'),
                  ),
          ],
        ),
      ),
    );
  }
}
