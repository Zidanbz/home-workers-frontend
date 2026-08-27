import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:home_workers_fe/features/main_page.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/utils/payment_redirect_policy.dart';
import 'package:home_workers_fe/core/utils/payment_status_policy.dart';
import 'package:home_workers_fe/features/customer_flow/booking/pages/payment_success_page.dart';

class SnapPaymentPage extends StatefulWidget {
  final String redirectUrl;
  final String? orderId;

  const SnapPaymentPage({super.key, required this.redirectUrl, this.orderId});

  @override
  State<SnapPaymentPage> createState() => _SnapPaymentPageState();
}

class _SnapPaymentPageState extends State<SnapPaymentPage>
    with WidgetsBindingObserver {
  static const _stuckLoaderTimeout = Duration(seconds: 15);

  late final WebViewController _controller;
  late final Uri? _redirectUri;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  final ApiService _apiService = ApiService();

  bool _transactionFinished = false;
  bool _pendingRedirectBlockedOnce = false;
  bool _insecureRedirectBlockedOnce = false;
  String? _webErrorMessage;
  Timer? _statusTimer;
  Timer? _stuckLoaderTimer;
  bool _showStuckLoaderRecovery = false;
  bool _navigatingToSuccess = false;
  String? _midtransOrderIdFromRedirect;
  bool _finishRedirectSeen = false;
  bool _isHandlingFinishRedirect = false;
  bool _isSuccessProbeRunning = false;

  void _armStuckLoaderDetection() {
    _stuckLoaderTimer?.cancel();
    _stuckLoaderTimer = Timer(_stuckLoaderTimeout, _detectStuckLoader);
  }

  Future<void> _detectStuckLoader() async {
    if (!mounted || _navigatingToSuccess || _transactionFinished) return;

    var loaderIsStillVisible = false;
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        "document.body ? (document.body.innerText || '') : ''",
      );
      final bodyText = _normalizeJsStringResult(raw).toLowerCase();
      loaderIsStillVisible =
          bodyText.contains('tunggu sebentar') ||
          bodyText.contains('please wait') ||
          bodyText.contains('just a moment');
    } catch (_) {
      // Error utama akan ditangani NavigationDelegate. Jangan membuka browser
      // secara otomatis karena perpindahan aplikasi harus tetap pilihan user.
    }

    if (!mounted || !loaderIsStillVisible) return;
    setState(() {
      _showStuckLoaderRecovery = true;
    });
  }

  Future<void> _reloadPaymentPage() async {
    final uri = _redirectUri;
    if (uri == null) return;

    setState(() {
      _webErrorMessage = null;
      _showStuckLoaderRecovery = false;
    });
    _armStuckLoaderDetection();

    try {
      // Memuat URL Snap yang sama, bukan meminta transaksi/token baru.
      await _controller.loadRequest(uri);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _webErrorMessage = 'Halaman pembayaran tidak dapat dimuat ulang.';
      });
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = _redirectUri;
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL pembayaran tidak valid.')),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Browser tidak dapat membuka halaman pembayaran.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Browser tidak dapat membuka halaman pembayaran.'),
        ),
      );
    }
  }

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

  void _acceptRedirectOrderId(String? redirectOrderId) {
    if (redirectOrderId == null || redirectOrderId.isEmpty) return;
    final expectedOrderId = widget.orderId;
    if (expectedOrderId == null || redirectOrderId == expectedOrderId) {
      _midtransOrderIdFromRedirect = redirectOrderId;
    }
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
      if (isVerifiedPaidPayment(requestedOrderId: orderId, response: status)) {
        _navigatingToSuccess = true;
        _statusTimer?.cancel();
        _stuckLoaderTimer?.cancel();
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(orderId: orderId),
          ),
        );
        return;
      }

      if (isVerifiedFailedPayment(
            requestedOrderId: orderId,
            response: status,
          ) &&
          !_transactionFinished) {
        setState(() {
          _transactionFinished = true;
        });
        _statusTimer?.cancel();
        _stuckLoaderTimer?.cancel();
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final startedAt = DateTime.now();
    while (mounted &&
        !_navigatingToSuccess &&
        DateTime.now().difference(startedAt) < timeout) {
      final token = auth.token;
      final orderId = _midtransOrderIdFromRedirect ?? widget.orderId;
      if (token == null || orderId == null || orderId.isEmpty) return false;

      try {
        final status = await _apiService.getMidtransStatus(
          token: token,
          orderId: orderId,
        );
        if (!mounted) return false;

        if (isVerifiedPaidPayment(
          requestedOrderId: orderId,
          response: status,
        )) {
          await _goToSuccessPage(params: params);
          return true;
        }
        if (isVerifiedFailedPayment(
          requestedOrderId: orderId,
          response: status,
        )) {
          if (!_transactionFinished) {
            setState(() {
              _transactionFinished = true;
            });
          }
          _statusTimer?.cancel();
          _stuckLoaderTimer?.cancel();
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

      // Teks pada WebView bukan bukti pembayaran. Status tetap harus
      // terverifikasi server-to-server sebelum membuka halaman sukses.
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
    _stuckLoaderTimer?.cancel();

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
      final redirectOrderId =
          params['order_id'] ?? params['orderId'] ?? params['orderid'];
      _acceptRedirectOrderId(redirectOrderId);

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
    WidgetsBinding.instance.addObserver(this);
    _redirectUri = parseTrustedMidtransRedirectUrl(widget.redirectUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _webErrorMessage = null;
              _showStuckLoaderRecovery = false;
            });
            _armStuckLoaderDetection();
            // Setelah WebView instance terbentuk.
            Future.microtask(_enableThirdPartyCookiesIfPossible);
            Future.microtask(_startStatusPolling);

            final lowerUrl = url.toLowerCase();
            if (!_finishRedirectSeen && lowerUrl.contains('/finish')) {
              _finishRedirectSeen = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
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
            final navigationHost = Uri.tryParse(url)?.host;
            debugPrint(
              '🌐 Payment navigation host: ${navigationHost ?? 'invalid'}',
            );

            final params = _extractQueryParams(url);
            final statusCode = params['status_code'];
            final transactionStatus = params['transaction_status'];
            final redirectOrderId =
                params['order_id'] ?? params['orderId'] ?? params['orderid'];
            _acceptRedirectOrderId(redirectOrderId);

            final lowerUrl = url.toLowerCase();
            final isFinishRedirect = lowerUrl.contains('/finish');
            if (isFinishRedirect) {
              _finishRedirectSeen = true;
              // Midtrans sudah menganggap transaksi selesai dan redirect ke finish URL.
              // Jangan tampilkan halaman HTML /finish di WebView; validasi status dulu.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
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
                _waitForPaidAndNavigate(params: params);
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
              Future.microtask(_checkAndHandlePaymentStatus);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Kegagalan gambar/analytics pihak ketiga tidak boleh menutupi form
            // pembayaran utama dengan pesan error.
            if (error.isForMainFrame == false) return;
            // Ini membantu diagnosa jika yang terlihat user adalah halaman "error" setelah pilih bank.
            debugPrint(
              '❌ WebView error: ${error.errorCode} ${error.description} (${error.errorType})',
            );
            if (!mounted) return;
            setState(() {
              _webErrorMessage = error.description;
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
                  onPressed: _reloadPaymentPage,
                ),
              ),
            );
          },
        ),
      );

    // Best-effort: allow cookies/resources that some payment flows rely on,
    // then load the payment page.
    Future.microtask(() async {
      if (_redirectUri == null) {
        if (!mounted) return;
        setState(() {
          _webErrorMessage =
              'URL pembayaran ditolak karena bukan halaman HTTPS Midtrans yang valid.';
        });
        return;
      }
      try {
        await _configurePlatformWebView();
      } catch (_) {}
      if (!mounted) return;
      await _controller.loadRequest(_redirectUri);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.microtask(_checkAndHandlePaymentStatus);
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    _stuckLoaderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_transactionFinished,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_transactionFinished) return;
        _navigateToDashboard(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          actions: [
            IconButton(
              tooltip: 'Buka di browser',
              onPressed: _redirectUri == null ? null : _openInExternalBrowser,
              icon: const Icon(Icons.open_in_browser),
            ),
          ],
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
            if (_webErrorMessage != null || _showStuckLoaderRecovery)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _webErrorMessage == null
                                    ? Icons.hourglass_top
                                    : Icons.error_outline,
                                color: _webErrorMessage == null
                                    ? Colors.orange.shade800
                                    : Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _webErrorMessage == null
                                      ? 'Midtrans masih memuat. Coba muat ulang atau lanjutkan di browser.'
                                      : 'Halaman pembayaran gagal dimuat. Coba muat ulang atau lanjutkan di browser.',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Tutup',
                                onPressed: () {
                                  setState(() {
                                    _webErrorMessage = null;
                                    _showStuckLoaderRecovery = false;
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: _reloadPaymentPage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Muat ulang'),
                                ),
                                FilledButton.icon(
                                  onPressed: _redirectUri == null
                                      ? null
                                      : _openInExternalBrowser,
                                  icon: const Icon(Icons.open_in_browser),
                                  label: const Text('Buka browser'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
