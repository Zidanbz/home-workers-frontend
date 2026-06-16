import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';

import 'package:home_workers_fe/features/main_page.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/payment_success_page.dart';

class SnapPaymentPage extends StatefulWidget {
  final String redirectUrl;
  final String? orderId;

  const SnapPaymentPage({super.key, required this.redirectUrl, this.orderId});

  @override
  State<SnapPaymentPage> createState() => _SnapPaymentPageState();
}

class _SnapPaymentPageState extends State<SnapPaymentPage> {
  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  final ApiService _apiService = ApiService();

  bool _transactionFinished = false;
  bool _pendingRedirectBlockedOnce = false;
  bool _insecureRedirectBlockedOnce = false;
  WebResourceError? _lastWebError;
  Timer? _statusTimer;
  bool _navigatingToSuccess = false;
  String? _midtransOrderIdFromRedirect;
  bool _finishRedirectSeen = false;
  bool _isHandlingFinishRedirect = false;
  bool _isSuccessProbeRunning = false;

  Map<String, String> _extractQueryParams(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return const {};

    final params = <String, String>{...uri.queryParameters};

    // Kadang Midtrans/merchant finish URL menaruh parameter di fragment (#...).
    // Contoh: https://merchant/finish#/?transaction_status=pending&status_code=201
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final fragmentQueryIndex = fragment.indexOf('?');
      final fragmentQuery = fragmentQueryIndex >= 0
          ? fragment.substring(fragmentQueryIndex + 1)
          : fragment;
      final fragUri = Uri.tryParse('https://local/?$fragmentQuery');
      if (fragUri != null) {
        params.addAll(fragUri.queryParameters);
      }
    }

    return params;
  }

  void _navigateToDashboard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = (authProvider.user?.role ?? 'CUSTOMER').toUpperCase();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainPage(userRole: role)),
      (route) => false,
    );
  }

  bool _isPaidStatus(String? txStatus) {
    final v = (txStatus ?? '').toLowerCase();
    return v == 'settlement' || v == 'capture' || v == 'paid';
  }

  bool _isFailedStatus(String? txStatus) {
    final v = (txStatus ?? '').toLowerCase();
    return v == 'deny' || v == 'expire' || v == 'cancel';
  }

  Future<void> _checkAndHandlePaymentStatus() async {
    if (_navigatingToSuccess || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    final orderId = _midtransOrderIdFromRedirect ?? widget.orderId;
    if (token == null || orderId == null || orderId.isEmpty) return;

    try {
      final status = await _apiService.getMidtransStatus(
        token: token,
        orderId: orderId,
      );

      if (!mounted) return;
      final txStatus = status['transaction_status']?.toString();

      if (_isPaidStatus(txStatus)) {
        _navigatingToSuccess = true;
        _statusTimer?.cancel();
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(orderId: orderId),
          ),
        );
        return;
      }

      if (_isFailedStatus(txStatus) && !_transactionFinished) {
        setState(() {
          _transactionFinished = true;
        });
        _statusTimer?.cancel();
        _showPaymentFailureDialog(context);
      }
    } catch (_) {
      // Best-effort polling, abaikan error sementara.
    }
  }

  Future<bool> _waitForPaidAndNavigate({
    required Map<String, String> params,
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final startedAt = DateTime.now();
    while (mounted &&
        !_navigatingToSuccess &&
        DateTime.now().difference(startedAt) < timeout) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      final orderId = _midtransOrderIdFromRedirect ?? widget.orderId;
      if (token == null || orderId == null || orderId.isEmpty) return false;

      try {
        final status = await _apiService.getMidtransStatus(
          token: token,
          orderId: orderId,
        );
        if (!mounted) return false;

        final txStatus = status['transaction_status']?.toString();
        if (_isPaidStatus(txStatus)) {
          await _goToSuccessPage(params: params);
          return true;
        }
        if (_isFailedStatus(txStatus)) {
          if (!_transactionFinished) {
            setState(() {
              _transactionFinished = true;
            });
          }
          _statusTimer?.cancel();
          _showPaymentFailureDialog(context);
          return false;
        }
      } catch (_) {
        // Best-effort retry
      }

      await Future.delayed(interval);
    }
    return false;
  }

  String _normalizeJsStringResult(Object raw) {
    final text = raw.toString();
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  Future<void> _probeMidtransSuccessTextAndNavigate(String url) async {
    if (_isSuccessProbeRunning || _navigatingToSuccess || !mounted) return;
    _isSuccessProbeRunning = true;
    try {
      final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
      final isMidtransHost = host.contains('midtrans.com');
      if (!isMidtransHost) return;

      final raw = await _controller.runJavaScriptReturningResult(
        "document.body ? (document.body.innerText || '') : ''",
      );
      if (!mounted) return;

      final bodyText = _normalizeJsStringResult(raw).toLowerCase();
      final hasSuccessMarker =
          bodyText.contains('transaction is successful') ||
          bodyText.contains('successful, will redirect') ||
          bodyText.contains('transaksi berhasil');
      if (!hasSuccessMarker) return;

      final didNavigate = await _waitForPaidAndNavigate(
        params: const {},
        timeout: const Duration(seconds: 20),
        interval: const Duration(seconds: 2),
      );
      if (!mounted || _navigatingToSuccess || didNavigate) return;

      // Fail-open untuk kasus Midtrans simulator yang sukses tapi redirect tidak terjadi.
      await _goToSuccessPage(params: const {});
    } catch (_) {
      // Best-effort probe only.
    } finally {
      _isSuccessProbeRunning = false;
    }
  }

  Future<void> _goToSuccessPage({required Map<String, String> params}) async {
    if (_navigatingToSuccess || !mounted) return;
    _navigatingToSuccess = true;
    _statusTimer?.cancel();

    final orderId =
        _midtransOrderIdFromRedirect ?? widget.orderId ?? params['order_id'];

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            PaymentSuccessPage(orderId: orderId, redirectParams: params),
      ),
    );
  }

  Future<void> _handleFinishRedirect(String url) async {
    if (_isHandlingFinishRedirect || !mounted) return;
    _isHandlingFinishRedirect = true;

    try {
      final params = _extractQueryParams(url);
      final transactionStatus = params['transaction_status'];
      final redirectOrderId =
          params['order_id'] ?? params['orderId'] ?? params['orderid'];
      if (redirectOrderId != null && redirectOrderId.isNotEmpty) {
        _midtransOrderIdFromRedirect = redirectOrderId;
      }

      if (_isPaidStatus(transactionStatus)) {
        await _goToSuccessPage(params: params);
        return;
      }

      if (_isFailedStatus(transactionStatus)) {
        if (!_transactionFinished && mounted) {
          setState(() {
            _transactionFinished = true;
          });
        }
        _statusTimer?.cancel();
        if (mounted) {
          _showPaymentFailureDialog(context);
        }
        return;
      }

      // Optimistic UX:
      // Jika sudah benar-benar redirect ke endpoint merchant `/finish`,
      // langsung anggap sukses dan bawa user ke halaman sukses.
      // Ini menghindari kasus Midtrans sandbox yang kadang tidak melampirkan
      // query status/terlambat sinkron, padahal transaksi sudah selesai.
      final finishPath = Uri.tryParse(url)?.path.toLowerCase() ?? '';
      if (finishPath.endsWith('/finish')) {
        await _goToSuccessPage(params: params);
        return;
      }

      final didNavigate = await _waitForPaidAndNavigate(params: params);
      if (!mounted || _navigatingToSuccess || didNavigate) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran masih diproses. Tunggu beberapa saat lalu cek status pesanan.',
          ),
        ),
      );
    } finally {
      _isHandlingFinishRedirect = false;
    }
  }

  void _startStatusPolling() {
    if (_statusTimer != null) return;
    if (widget.orderId == null || widget.orderId!.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    // Midtrans status bisa berubah setelah redirect selesai (misal e-wallet).
    // Poll ringan agar UX tetap "auto success" walau finish redirect URL diblokir WebView.
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkAndHandlePaymentStatus();
    });
  }

  Future<void> _configurePlatformWebView() async {
    if (defaultTargetPlatform == TargetPlatform.android &&
        _controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
    }
  }

  Future<void> _enableThirdPartyCookiesIfPossible() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_controller.platform is! AndroidWebViewController) return;

    final cookiePlatform = _cookieManager.platform;
    if (cookiePlatform is! AndroidWebViewCookieManager) return;

    try {
      await cookiePlatform.setAcceptThirdPartyCookies(
        _controller.platform as AndroidWebViewController,
        true,
      );
    } catch (_) {
      // Best-effort: beberapa device/WebView butuh timing tertentu.
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _lastWebError = null;
            });
            // Setelah WebView instance terbentuk.
            Future.microtask(_enableThirdPartyCookiesIfPossible);
            Future.microtask(_startStatusPolling);

            final lowerUrl = url.toLowerCase();
            if (!_finishRedirectSeen && lowerUrl.contains('/finish')) {
              _finishRedirectSeen = true;
              final params = _extractQueryParams(url);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_isPaidStatus(params['transaction_status'])) {
                  _goToSuccessPage(params: params);
                  return;
                }
                _handleFinishRedirect(url);
              });
            }
          },
          onPageFinished: (url) {
            if (!mounted) return;
            if (_finishRedirectSeen) return;
            Future.microtask(() => _probeMidtransSuccessTextAndNavigate(url));
          },
          onNavigationRequest: (request) {
            final url = request.url;
            print('🌐 Navigated to: $url');

            final params = _extractQueryParams(url);
            final statusCode = params['status_code'];
            final transactionStatus = params['transaction_status'];
            final redirectOrderId =
                params['order_id'] ?? params['orderId'] ?? params['orderid'];
            if (redirectOrderId != null && redirectOrderId.isNotEmpty) {
              _midtransOrderIdFromRedirect = redirectOrderId;
            }

            final lowerUrl = url.toLowerCase();
            final isFinishRedirect = lowerUrl.contains('/finish');
            if (isFinishRedirect) {
              _finishRedirectSeen = true;
              // Midtrans sudah menganggap transaksi selesai dan redirect ke finish URL.
              // Jangan tampilkan halaman HTML /finish di WebView; validasi status dulu.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_isPaidStatus(transactionStatus)) {
                  _goToSuccessPage(params: params);
                  return;
                }
                _handleFinishRedirect(url);
              });
              return NavigationDecision.prevent;
            }

            // ✅ Sukses (beberapa metode pakai capture)
            if (statusCode == '200' &&
                (transactionStatus == 'settlement' ||
                    transactionStatus == 'capture')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _goToSuccessPage(params: params);
              });
              return NavigationDecision.prevent;
            }

            // 🟡 Bank Transfer/VA biasanya akan mengarah ke finish URL dengan status pending.
            // Pada WebView, redirect ke domain merchant yang tidak tersedia bisa tampak seperti "error".
            // Blok redirect finish URL, biarkan user tetap di halaman instruksi Midtrans.
            if (transactionStatus == 'pending') {
              final host = Uri.tryParse(url)?.host ?? '';
              final isMidtransHost = host.contains('midtrans.com');
              if (!isMidtransHost) {
                if (!_pendingRedirectBlockedOnce) {
                  _pendingRedirectBlockedOnce = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'VA berhasil dibuat. Silakan salin nomor VA & lakukan pembayaran. Tekan tombol kembali untuk menutup halaman ini.',
                        ),
                      ),
                    );
                  });
                }
                return NavigationDecision.prevent;
              }
            }

            final uri = Uri.tryParse(url);
            if (uri != null && uri.scheme.toLowerCase() == 'http') {
              // Android WebView (API 28+) memblokir cleartext HTTP by default.
              // Ini sering terjadi kalau Midtrans "finish redirect URL" masih default `http://example.com/`.
              if (!_insecureRedirectBlockedOnce) {
                _insecureRedirectBlockedOnce = true;
                Future.microtask(() async {
                  await _checkAndHandlePaymentStatus();
                  if (!mounted || _navigatingToSuccess) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Redirect pembayaran mengarah ke URL HTTP (cleartext) yang diblokir Android. '
                        'Jika muncul `http://example.com`, ubah Midtrans Finish Redirect URL jadi HTTPS.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                });
              } else {
                Future.microtask(_checkAndHandlePaymentStatus);
              }
              return NavigationDecision.prevent;
            }

            // ❌ Cek apakah URL mengandung indikator gagal
            if (transactionStatus == 'deny' ||
                transactionStatus == 'expire' ||
                transactionStatus == 'cancel') {
              setState(() {
                _transactionFinished = true;
              });
              Future.delayed(Duration.zero, () {
                _showPaymentFailureDialog(context);
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Ini membantu diagnosa jika yang terlihat user adalah halaman "error" setelah pilih bank.
            print(
              '❌ WebView error: ${error.errorCode} ${error.description} (${error.errorType})',
            );
            if (!mounted) return;
            setState(() {
              _lastWebError = error;
            });
            final desc = error.description.toLowerCase();
            final isCleartextBlocked = desc.contains(
              'err_cleartext_not_permitted',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isCleartextBlocked
                      ? 'Gagal memuat halaman karena URL masih HTTP (cleartext). '
                            'Kalau ini sandbox, pastikan Finish Redirect URL Midtrans pakai HTTPS.'
                      : 'Gagal memuat halaman pembayaran: ${error.description}',
                ),
                action: SnackBarAction(
                  label: 'Reload',
                  onPressed: () => _controller.reload(),
                ),
              ),
            );
          },
        ),
      );

    // Best-effort: allow cookies/resources that some payment flows rely on,
    // then load the payment page.
    Future.microtask(() async {
      try {
        await _configurePlatformWebView();
      } catch (_) {}
      if (!mounted) return;
      await _controller.loadRequest(Uri.parse(widget.redirectUrl));
    });
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
                _navigateToDashboard(context);
              },
              child: const Text('Coba Lagi'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _navigateToDashboard(context);
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
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_transactionFinished) {
          _navigateToDashboard(context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_transactionFinished) {
                _navigateToDashboard(context);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_lastWebError != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade700,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gagal memuat halaman. Coba reload atau buka di browser.',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _controller.reload(),
                          child: const Text(
                            'Reload',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
