import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/payment_success_page.dart';

class SnapPaymentPage extends StatefulWidget {
  final String redirectUrl;

  const SnapPaymentPage({super.key, required this.redirectUrl});

  @override
  State<SnapPaymentPage> createState() => _SnapPaymentPageState();
}

class _SnapPaymentPageState extends State<SnapPaymentPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            print('🌐 Navigated to: $url');

            // ✅ Cek apakah URL mengandung indikator sukses
            if (url.contains('status=200') ||
                url.contains('transaction_status=settlement') ||
                url.contains('transaction_status=capture') ||
                url.contains('status_code=200') ||
                url.contains('payment_type=') ||
                url.contains('finish')) {
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentSuccessPage(
                      paymentMethod: 'Midtrans',
                      totalAmount: 0,
                    ),
                  ),
                );
              });
              return NavigationDecision.prevent;
            }

            // ❌ Cek apakah URL mengandung indikator gagal
            if (url.contains('status=failed') ||
                url.contains('transaction_status=deny') ||
                url.contains('transaction_status=expire') ||
                url.contains('transaction_status=cancel')) {
              Future.delayed(Duration.zero, () {
                _showPaymentFailureDialog(context);
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _showPaymentFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Pembayaran Gagal'),
            ],
          ),
          content: const Text(
            'Pembayaran Anda tidak dapat diproses. Silakan coba lagi atau gunakan metode pembayaran lain.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
              },
              child: const Text('Coba Lagi'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
