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
                url.contains('transaction_status=settlement')) {
              Future.delayed(Duration.zero, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentSuccessPage(
                      paymentMethod:
                          'Midtrans', // Atau bisa parsing dari URL nanti
                      totalAmount:
                          0, // Ganti dengan jumlah yang sesuai jika ada
                    ),
                  ),
                );
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
