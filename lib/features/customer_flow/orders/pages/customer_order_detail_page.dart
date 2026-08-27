import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/helper/voucher_helper.dart';
import 'package:home_workers_fe/core/models/payment_invoice_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/core/utils/order_list_policy.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';
import 'package:home_workers_fe/features/customer_flow/booking/pages/snapPayment_page.dart';
import 'package:home_workers_fe/features/customer_flow/vouchers/pages/voucher_detail_page.dart';
import 'package:home_workers_fe/shared_widgets/action_tap_guard.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/models/refund_model.dart';
import 'package:home_workers_fe/core/models/warranty_model.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/refund_request_sheet.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/order_review_sheet.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/warranty_claim_sheet.dart';
import 'package:home_workers_fe/shared_widgets/refund_additional_evidence_sheet.dart';

class CustomerOrderDetailPage extends StatefulWidget {
  final Order initialOrder;
  final ApiService? apiService;
  final bool enableRealtime;

  static const Color primaryColor = Color(0xFF1A374D);
  static const Color secondaryColor = Color(0xFF2B6478);
  static const Color accentColor = Color(0xFF6C5CE7);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF4F7F9);
  static const Color surfaceBorder = Color(0xFFE5EBEF);
  static const Color mutedText = Color(0xFF647681);

  const CustomerOrderDetailPage({
    super.key,
    required this.initialOrder,
    this.apiService,
    this.enableRealtime = true,
  });

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  late Order _order;
  bool _isLoading = false;
  bool _isStartingPayment = false;
  late final ApiService _apiService;
  FirebaseFirestore? _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _orderSubscription;
  Timer? _acceptanceTicker;
  DateTime _clockNow = DateTime.now();
  bool _isRealtimeActive = false;
  RefundRequest? _refundRequest;
  OrderWarranty? _warranty;
  List<PaymentInvoice> _invoices = [];
  bool _isInvoicesLoading = false;
  String? _sharingInvoiceId;

  // Voucher state
  String? _selectedVoucher;
  String? _appliedVoucherCode;
  int _discount = 0;
  String? _voucherMessage;
  List<Map<String, dynamic>> _vouchers = [];
  bool _isVoucherValid = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _discount = (_order.finalDiscount ?? 0).toInt();
    _appliedVoucherCode = _order.finalAppliedVoucher;
    _selectedVoucher = _order.finalAppliedVoucher;
    _isVoucherValid = _appliedVoucherCode != null;
    _apiService = widget.apiService ?? ApiService();
    if (widget.enableRealtime) {
      _firestore = FirebaseFirestore.instance;
    }
    _isInvoicesLoading = _hasPaidPayment;
    if (_order.status == 'quote_accepted') {
      _fetchVouchers();
    }
    _syncAcceptanceTicker();
    if (widget.enableRealtime) {
      _startRealtimeOrderListener();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrderDetails();
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _acceptanceTicker?.cancel();
    super.dispose();
  }

  void _syncAcceptanceTicker() {
    final shouldTick =
        _order.status == 'pending' && _order.workerAcceptanceDeadlineAt != null;
    if (!shouldTick) {
      _acceptanceTicker?.cancel();
      _acceptanceTicker = null;
      return;
    }
    if (_acceptanceTicker?.isActive == true) return;
    _clockNow = DateTime.now();
    _acceptanceTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _clockNow = DateTime.now());
    });
  }

  Future<void> _fetchVouchers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final raw = await _apiService.getAvailableVouchers(token: token);
      final normalized = normalizeVouchers(raw);
      if (mounted) {
        setState(() {
          _vouchers = normalized;
        });
      }
    } catch (e) {
      debugPrint('Gagal ambil voucher: $e');
    }
  }

  Future<void> _validateAndApplyVoucher(String voucherCode) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final quotedPrice = (_order.quotedPrice ?? 0).toInt();

    try {
      final result = await _apiService.validateVoucherCode(
        token: token!,
        voucherCode: voucherCode,
        orderAmount: quotedPrice,
      );

      final discount = (result['discount'] ?? 0) as int;
      if (!mounted) return;

      setState(() {
        _discount = discount;
        _appliedVoucherCode = result['voucherCode'] ?? voucherCode;
        _voucherMessage = result['message'] ?? 'Voucher diterapkan.';
        _isVoucherValid = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher diterapkan: -${_formatCurrency(discount)}'),
        ),
      );
    } catch (e) {
      final errorMessage = ApiService.readableError(
        e,
        action: 'Validasi voucher gagal',
      );
      if (!mounted) return;
      setState(() {
        _selectedVoucher = null;
        _discount = 0;
        _appliedVoucherCode = null;
        _voucherMessage = errorMessage;
        _isVoucherValid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_voucherMessage!), backgroundColor: Colors.red),
      );
    }
  }

  void _resetVoucher() {
    setState(() {
      _discount = 0;
      _appliedVoucherCode = null;
      _voucherMessage = null;
      _selectedVoucher = null;
      _isVoucherValid = false;
    });
  }

  void _showVoucherSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: CustomerOrderDetailPage.backgroundGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E1E5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: CustomerOrderDetailPage.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Voucher',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CustomerOrderDetailPage.primaryColor,
                          ),
                        ),
                        Text(
                          'Gunakan promo terbaik untuk pesanan ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: CustomerOrderDetailPage.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  itemCount: _vouchers.length,
                  itemBuilder: (_, index) {
                    final voucher = _vouchers[index];
                    final code = voucher['code'] as String;
                    final discountType = voucher['discountType'];
                    final value = voucher['value'];
                    final label = discountType == 'percent'
                        ? '$code • $value%'
                        : '$code • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: CustomerOrderDetailPage.surfaceBorder,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sell_outlined,
                            color: CustomerOrderDetailPage.accentColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(
                            color: CustomerOrderDetailPage.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VoucherDetailPage(voucher: voucher),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                CustomerOrderDetailPage.primaryColor,
                          ),
                          child: const Text('Detail'),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedVoucher = code;
                          });
                          _validateAndApplyVoucher(code);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getVoucherDisplayText(String voucherCode) {
    final voucher = _vouchers.firstWhere(
      (v) => v['code'] == voucherCode,
      orElse: () => {},
    );
    if (voucher.isEmpty) return voucherCode;

    final discountType = voucher['discountType'];
    final value = voucher['value'];
    return discountType == 'percent'
        ? '$voucherCode • $value%'
        : '$voucherCode • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  bool get _hasPaidPayment =>
      _order.paymentStatus == 'paid' || _order.finalPaymentStatus == 'paid';

  Future<List<PaymentInvoice>?> _fetchOrderInvoicesSafely(String token) async {
    try {
      return await _apiService.getOrderInvoices(
        token: token,
        orderId: _order.id,
      );
    } catch (error) {
      debugPrint('Gagal memuat invoice order ${_order.id}: $error');
      return null;
    }
  }

  Future<OrderWarranty?> _fetchOrderWarrantySafely(String token) async {
    try {
      return await _apiService.getOrderWarranty(
        token: token,
        orderId: _order.id,
      );
    } catch (error) {
      debugPrint('Gagal memuat garansi order ${_order.id}: $error');
      return null;
    }
  }

  Future<void> _refreshOrderDetails({bool showError = true}) async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() {
      _isLoading = true;
      if (_hasPaidPayment && _invoices.isEmpty) {
        _isInvoicesLoading = true;
      }
    });
    try {
      final results = await Future.wait<Object?>([
        _apiService.getOrderById(token: auth.token!, orderId: _order.id),
        _apiService.getOrderRefund(token: auth.token!, orderId: _order.id),
        _fetchOrderInvoicesSafely(auth.token!),
        _fetchOrderWarrantySafely(auth.token!),
      ]);
      final updatedOrder = results[0] as Order;
      final updatedRefund = results[1] as RefundRequest?;
      final loadedInvoices = results[2] as List<PaymentInvoice>?;
      final loadedWarranty = results[3] as OrderWarranty?;
      final updatedInvoices = loadedInvoices ?? _invoices;
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _refundRequest = updatedRefund;
          _invoices = updatedInvoices;
          _warranty = loadedWarranty ?? _warranty;
        });
        _syncAcceptanceTicker();
      }
      if (mounted &&
          updatedOrder.status == 'quote_accepted' &&
          _vouchers.isEmpty) {
        _fetchVouchers();
      }
    } catch (e) {
      if (mounted && showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.readableError(
                e,
                action: 'Gagal memuat data pesanan terbaru',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInvoicesLoading = false;
        });
      }
    }
  }

  void _startRealtimeOrderListener() {
    _orderSubscription?.cancel();
    _orderSubscription = _firestore!
        .collection('orders')
        .doc(_order.id)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            if (data == null) return;
            _applyRealtimeUpdate(data);
          },
          onError: (error) {
            debugPrint('Realtime order listener error: $error');
            if (mounted) {
              setState(() => _isRealtimeActive = false);
            }
          },
        );
  }

  void _applyRealtimeUpdate(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final quotedPrice = _parseNum(data['quotedPrice'] ?? data['proposedPrice']);
    final quoteRevision = (data['quoteRevision'] as num?)?.toInt();
    final quoteRevisionRequest = data['quoteRevisionRequest'] is Map
        ? QuoteRevisionRequest.fromJson(
            Map<String, dynamic>.from(data['quoteRevisionRequest']),
          )
        : null;
    final workerId = data['workerId'] as String?;
    final workerName = data['workerName'] as String?;
    final workerAvatar = data['workerAvatar'] as String?;
    final hasBeenReviewed = data['hasBeenReviewed'] as bool?;
    final paymentStatus = data['paymentStatus'] as String?;
    final finalPaymentStatus = data['finalPaymentStatus'] as String?;
    final finalPaymentAmount = _parseNum(data['finalPaymentAmount']);
    final finalDiscount = _parseNum(data['finalDiscount']);
    final finalAppliedVoucher = data['finalAppliedVoucher']?.toString();
    final refundStatus = data['refundStatus'] as String?;
    final disputeStatus = data['disputeStatus'] as String?;
    final completedAt = _parseOptionalTimestamp(data['completedAt']);
    final workerAcceptanceStartedAt = _parseOptionalTimestamp(
      data['workerAcceptanceStartedAt'],
    );
    final workerAcceptanceDeadlineAt = _parseOptionalTimestamp(
      data['workerAcceptanceDeadlineAt'],
    );
    final workerAcceptedAt = _parseOptionalTimestamp(data['workerAcceptedAt']);
    final acceptanceExpiredAt = _parseOptionalTimestamp(
      data['acceptanceExpiredAt'],
    );
    final workerAcceptanceState = data['workerAcceptanceState']?.toString();
    final warrantyStatus = data['warrantyStatus']?.toString();
    final warrantyStartedAt = _parseOptionalTimestamp(
      data['warrantyStartedAt'],
    );
    final warrantyExpiresAt = _parseOptionalTimestamp(
      data['warrantyExpiresAt'],
    );
    final activeWarrantyClaimId = data['activeWarrantyClaimId']?.toString();
    final warrantyClaimCount = (data['warrantyClaimCount'] as num?)?.toInt();
    final jadwalPerbaikan = _parseTimestamp(
      data['jadwalPerbaikan'],
      _order.jadwalPerbaikan,
    );
    final dibuatPada = _parseTimestamp(data['dibuatPada'], _order.dibuatPada);
    final shouldFetchVouchers = status == 'quote_accepted' && _vouchers.isEmpty;
    final shouldRefreshEvidence =
        (status == 'work_in_progress' || status == 'completion_submitted') &&
        _order.status != status;
    final shouldRefreshInvoices =
        (paymentStatus == 'paid' && _order.paymentStatus != 'paid') ||
        (finalPaymentStatus == 'paid' && _order.finalPaymentStatus != 'paid');
    final shouldRefreshWarranty =
        warrantyStatus != null && warrantyStatus != _order.warrantyStatus;

    if (!mounted) return;
    setState(() {
      _order = _order.copyWith(
        status: status ?? _order.status,
        quotedPrice: quotedPrice ?? _order.quotedPrice,
        quoteRevision: quoteRevision ?? _order.quoteRevision,
        quoteRevisionRequest:
            quoteRevisionRequest ?? _order.quoteRevisionRequest,
        workerId: workerId ?? _order.workerId,
        workerName: workerName ?? _order.workerName,
        workerAvatar: workerAvatar ?? _order.workerAvatar,
        jadwalPerbaikan: jadwalPerbaikan,
        dibuatPada: dibuatPada,
        hasBeenReviewed: hasBeenReviewed ?? _order.hasBeenReviewed,
        paymentStatus: paymentStatus ?? _order.paymentStatus,
        finalPaymentStatus: finalPaymentStatus ?? _order.finalPaymentStatus,
        finalPaymentAmount: finalPaymentAmount ?? _order.finalPaymentAmount,
        finalDiscount: finalDiscount ?? _order.finalDiscount,
        finalAppliedVoucher: finalAppliedVoucher ?? _order.finalAppliedVoucher,
        refundStatus: refundStatus ?? _order.refundStatus,
        disputeStatus: disputeStatus ?? _order.disputeStatus,
        completedAt: completedAt ?? _order.completedAt,
        workerAcceptanceStartedAt:
            workerAcceptanceStartedAt ?? _order.workerAcceptanceStartedAt,
        workerAcceptanceDeadlineAt:
            workerAcceptanceDeadlineAt ?? _order.workerAcceptanceDeadlineAt,
        workerAcceptedAt: workerAcceptedAt ?? _order.workerAcceptedAt,
        acceptanceExpiredAt: acceptanceExpiredAt ?? _order.acceptanceExpiredAt,
        workerAcceptanceState:
            workerAcceptanceState ?? _order.workerAcceptanceState,
        warrantyStatus: warrantyStatus ?? _order.warrantyStatus,
        warrantyStartedAt: warrantyStartedAt ?? _order.warrantyStartedAt,
        warrantyExpiresAt: warrantyExpiresAt ?? _order.warrantyExpiresAt,
        activeWarrantyClaimId:
            activeWarrantyClaimId ?? _order.activeWarrantyClaimId,
        warrantyClaimCount: warrantyClaimCount ?? _order.warrantyClaimCount,
      );
      _isRealtimeActive = true;
    });
    _syncAcceptanceTicker();

    if (shouldFetchVouchers) {
      _fetchVouchers();
    }
    if (shouldRefreshEvidence) {
      _refreshOrderDetails();
    }
    if (shouldRefreshInvoices) {
      _refreshOrderDetails();
    }
    if (shouldRefreshWarranty) {
      _refreshOrderDetails();
    }
    if (refundStatus != null && refundStatus != _refundRequest?.status) {
      _refreshOrderDetails();
    }
  }

  DateTime _parseTimestamp(dynamic value, DateTime fallback) {
    if (value == null) return fallback;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return fallback;
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }
    return fallback;
  }

  DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed == null ? null : (parsed.isUtc ? parsed.toLocal() : parsed);
    }
    return null;
  }

  num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  bool _isPaymentCompleted(Order order) {
    if (order.paymentStatus == 'paid' || order.finalPaymentStatus == 'paid') {
      return true;
    }
    if (order.paymentStatus == null && order.finalPaymentStatus == null) {
      return [
        'pending',
        'accepted',
        'quote_proposed',
        'quote_revision_requested',
        'ready_to_start',
        'work_in_progress',
        'completion_submitted',
        'completed',
        'done',
        'paid',
        'waiting',
        'on_the_way',
      ].contains(order.status);
    }
    return false;
  }

  bool _isOrderCompleted(String status) {
    return status == 'completed' || status == 'done';
  }

  bool _isWithinChatWindow(Order order) {
    if (!_isOrderCompleted(order.status)) return true;
    final completedAt = order.completedAt;
    if (completedAt == null) return true;
    return DateTime.now().difference(completedAt) <= const Duration(days: 7);
  }

  String? _chatBlockedReason() {
    if (_order.workerId == null) return 'Belum ada worker yang ditugaskan.';
    if (_order.status == 'worker_acceptance_expired') {
      return 'Chat ditutup karena batas penerimaan Worker telah berakhir.';
    }
    if (!_isPaymentCompleted(_order)) {
      return 'Chat tersedia setelah pembayaran berhasil.';
    }
    if (_isOrderCompleted(_order.status) && !_isWithinChatWindow(_order)) {
      return 'Chat sudah ditutup. Maksimal 7 hari setelah pesanan selesai.';
    }
    return null;
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'awaiting_payment':
        return Icons.payments_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'quote_proposed':
        return Icons.request_quote_rounded;
      case 'quote_revision_requested':
        return Icons.edit_note_rounded;
      case 'quote_accepted':
        return Icons.payment_rounded;
      case 'ready_to_start':
        return Icons.play_circle_outline_rounded;
      case 'work_in_progress':
        return Icons.build_circle_rounded;
      case 'completion_submitted':
        return Icons.fact_check_rounded;
      case 'refund:submitted':
      case 'refund:awaiting_worker_response':
        return Icons.hourglass_top_rounded;
      case 'refund:under_review':
        return Icons.manage_search_rounded;
      case 'refund:more_evidence_required':
        return Icons.add_photo_alternate_outlined;
      case 'refund:rework_offered':
        return Icons.handyman_outlined;
      case 'refund:rework_in_progress':
        return Icons.build_circle_outlined;
      case 'refund:approved':
      case 'refund:awaiting_refund_destination':
      case 'refund:approved_manual':
      case 'refund:processing':
        return Icons.currency_exchange_rounded;
      case 'refund:refunded':
        return Icons.verified_rounded;
      case 'refund:failed':
        return Icons.error_outline_rounded;
      case 'completed':
      case 'done':
      case 'paid':
      case 'quote_rejected':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'rejected':
      case 'worker_acceptance_expired':
        return Icons.cancel_rounded;
      case 'waiting':
        return Icons.hourglass_top_rounded;
      case 'on_the_way':
        return Icons.directions_run_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'awaiting_payment':
        return 'Menunggu Pembayaran';
      case 'accepted':
        return 'Disetujui';
      case 'quote_proposed':
        return 'Penawaran Diajukan';
      case 'quote_revision_requested':
        return 'Menunggu Revisi Harga';
      case 'quote_accepted':
        return 'Siap Bayar';
      case 'ready_to_start':
        return 'Siap Dimulai';
      case 'work_in_progress':
        return 'Dalam Pengerjaan';
      case 'completion_submitted':
        return 'Menunggu Konfirmasi Anda';
      case 'refund:submitted':
        return 'Pengajuan Refund Terkirim';
      case 'refund:awaiting_worker_response':
        return 'Menunggu Tanggapan Worker';
      case 'refund:under_review':
        return 'Refund Ditinjau Admin';
      case 'refund:more_evidence_required':
        return 'Lengkapi Bukti Refund';
      case 'refund:rework_offered':
        return 'Perbaikan Ditawarkan';
      case 'refund:rework_in_progress':
        return 'Perbaikan Ulang Berjalan';
      case 'refund:approved':
        return 'Refund Disetujui';
      case 'refund:awaiting_refund_destination':
        return 'Lengkapi Tujuan Refund';
      case 'refund:approved_manual':
        return 'Menunggu Transfer Refund';
      case 'refund:processing':
        return 'Refund Sedang Diproses';
      case 'refund:refunded':
        return 'Refund Selesai';
      case 'refund:failed':
        return 'Pemrosesan Refund Terkendala';
      case 'completed':
      case 'done':
        return 'Selesai';
      case 'paid':
        return 'Pembayaran Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      case 'quote_rejected':
        return 'Survei Selesai • Penawaran Ditolak';
      case 'rejected':
        return 'Ditolak';
      case 'worker_acceptance_expired':
        return 'Waktu Konfirmasi Worker Habis';
      case 'waiting':
        return 'Menunggu';
      case 'on_the_way':
        return 'Dalam Perjalanan';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Future<bool> _showConfirmationSheet({
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    Color confirmColor = CustomerOrderDetailPage.primaryColor,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E1E5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: confirmColor, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CustomerOrderDetailPage.primaryColor,
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CustomerOrderDetailPage.mutedText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomerOrderDetailPage.primaryColor,
                      side: const BorderSide(
                        color: CustomerOrderDetailPage.surfaceBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmCompletion() async {
    final confirmed = await _showConfirmationSheet(
      icon: Icons.verified_rounded,
      title: 'Konfirmasi pekerjaan selesai?',
      message:
          'Pastikan hasil dan bukti pekerjaan sudah sesuai. Setelah dikonfirmasi, order selesai dan saldo Worker akan dicairkan.',
      confirmLabel: 'Ya, Konfirmasi',
      cancelLabel: 'Periksa Lagi',
      confirmColor: const Color(0xFF16835D),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.refreshAccessToken();
      if (token == null) {
        throw StateError('Sesi berakhir. Silakan login kembali.');
      }

      final confirmation = await _apiService.confirmOrderCompletion(
        token: token,
        orderId: _order.id,
      );
      if (!mounted) return;
      final confirmedAt = confirmation.completedAt ?? DateTime.now();
      setState(() {
        _order = _order.copyWith(
          status: confirmation.status,
          completedAt: confirmedAt,
          completionConfirmedAt: confirmedAt,
          payoutStatus: confirmation.payoutStatus,
          payoutAmount: confirmation.workerAmount,
          payoutAvailableAt: confirmation.payoutAvailableAt,
        );
      });

      // Endpoint GET atau listener Firestore dapat gagal sendiri setelah PUT
      // berhasil. Jangan mengembalikan UI ke status lama; sinkronisasi ulang
      // tetap dicoba tanpa menutupi hasil transaksi yang sudah commit.
      await _refreshOrderDetails(showError: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF4CAF50),
          content: Text(
            'Pekerjaan selesai. Pendapatan langsung masuk ke saldo Worker.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal mengonfirmasi pekerjaan',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePayment() async {
    if (_isStartingPayment) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isStartingPayment = true);
    try {
      final paymentData = await _apiService.startPaymentForQuote(
        token: auth.token!,
        orderId: _order.id,
        voucherCode: _appliedVoucherCode,
      );
      final snapToken = paymentData['snapToken']?.toString();
      if (snapToken == null || snapToken.isEmpty) {
        throw Exception('Token pembayaran tidak diterima dari server.');
      }
      final quotedAmount = (_order.quotedPrice ?? 0).toInt();
      final serverSubtotal = num.tryParse(paymentData['subtotal'].toString());
      final serverDiscount = num.tryParse(paymentData['discount'].toString());
      final serverAmount = num.tryParse(paymentData['amount'].toString());
      final serverVoucher = paymentData['appliedVoucher']?.toString();
      if (serverSubtotal == null ||
          serverDiscount == null ||
          serverAmount == null ||
          serverSubtotal.round() != quotedAmount ||
          serverDiscount < 0 ||
          serverDiscount > serverSubtotal ||
          serverAmount.round() !=
              serverSubtotal.round() - serverDiscount.round() ||
          (_appliedVoucherCode != null &&
              (serverVoucher != _appliedVoucherCode ||
                  serverDiscount.round() != _discount))) {
        throw Exception(
          'Nominal pembayaran dari server tidak sesuai dengan rincian penawaran.',
        );
      }
      if (mounted) {
        setState(() {
          _discount = serverDiscount.round();
          _appliedVoucherCode = serverVoucher;
          _selectedVoucher = serverVoucher;
          _isVoucherValid = serverVoucher != null;
        });
      }

      final redirectUrlFromServer = paymentData['redirectUrl']?.toString();
      final midtransOrderId =
          paymentData['midtransOrderId']?.toString() ?? 'quote_${_order.id}';
      final snapHost = dotenv.env['MIDTRANS_SNAP_HOST'] ?? 'app.midtrans.com';
      final snapRedirectUrl =
          (redirectUrlFromServer != null && redirectUrlFromServer.isNotEmpty)
          ? redirectUrlFromServer
          : "https://$snapHost/snap/v2/vtweb/$snapToken";

      // Guard: kalau app run sandbox tapi backend masih mengembalikan URL production.
      const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
      final isSandboxApp = appEnv.toLowerCase() == 'sandbox';
      final redirectHost = Uri.tryParse(snapRedirectUrl)?.host ?? '';
      final isSandboxRedirect = redirectHost.contains('sandbox.midtrans.com');
      if (isSandboxApp && !isSandboxRedirect) {
        debugPrint(
          '⚠️ [CustomerOrderDetailPage] APP_ENV=sandbox tapi redirectUrl production. '
          'Cek API_BASE_URL & deploy backend dev (howek-dev) + MIDTRANS_IS_PRODUCTION=false.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mode sandbox aktif, tapi link pembayaran masih production. Cek API_BASE_URL dan pastikan backend dev memakai Midtrans sandbox.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }

      final resolvedHost = Uri.tryParse(snapRedirectUrl)?.host;
      if (resolvedHost != null &&
          resolvedHost.isNotEmpty &&
          resolvedHost != snapHost) {
        debugPrint(
          '⚠️ [CustomerOrderDetailPage] Redirect host mismatch. envHost=$snapHost, redirectHost=$resolvedHost',
        );
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SnapPaymentPage(
            redirectUrl: snapRedirectUrl,
            orderId: midtransOrderId,
          ),
        ),
      );

      await _refreshOrderDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.readableError(e, action: 'Gagal memulai pembayaran'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingPayment = false);
    }
  }

  Future<void> _respondToQuote(String decision) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final expectedPrice = _order.quotedPrice;
    if (expectedPrice == null || expectedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga penawaran tidak valid.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _apiService.respondToQuote(
        token: auth.token!,
        orderId: _order.id,
        decision: decision,
        expectedPrice: expectedPrice,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penawaran berhasil ${decision == 'accept' ? 'diterima' : 'ditolak'}',
          ),
        ),
      );

      await _refreshOrderDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.readableError(e, action: 'Gagal memproses penawaran'),
            ),
          ),
        );
        await _refreshOrderDetails(showError: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestQuoteRevision() async {
    final expectedPrice = _order.quotedPrice;
    if (expectedPrice == null || expectedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga penawaran tidak valid.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Minta Revisi Harga'),
        content: Form(
          key: formKey,
          child: TextFormField(
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) => draftReason = value,
            decoration: const InputDecoration(
              labelText: 'Alasan revisi',
              hintText:
                  'Jelaskan bagian harga atau ruang lingkup yang perlu diperiksa ulang.',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value?.trim().length ?? 0) < 10) {
                return 'Alasan revisi minimal 10 karakter.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, draftReason.trim());
            },
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login telah berakhir.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.requestQuoteRevision(
        token: token,
        orderId: _order.id,
        reason: reason,
        expectedPrice: expectedPrice,
        expectedRevision: _order.quoteRevision,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan revisi harga berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrderDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal meminta revisi harga',
            ),
          ),
        ),
      );
      await _refreshOrderDetails(showError: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        _order.jadwalPerbaikan.hour == 0 && _order.jadwalPerbaikan.minute == 0;
    final formattedDate = isMidnight
        ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_order.jadwalPerbaikan)
        : DateFormat(
            'EEEE, d MMM yyyy • HH:mm',
            'id_ID',
          ).format(_order.jadwalPerbaikan);

    return Scaffold(
      backgroundColor: CustomerOrderDetailPage.backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: CustomerOrderDetailPage.primaryColor,
          ),
        ),
        centerTitle: false,
        backgroundColor: CustomerOrderDetailPage.backgroundGray,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: CustomerOrderDetailPage.primaryColor,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrderDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(formattedDate),
              if ((_order.status == 'pending' &&
                      _order.workerAcceptanceDeadlineAt != null) ||
                  _order.status == 'worker_acceptance_expired') ...[
                const SizedBox(height: 16),
                _buildWorkerAcceptanceCard(),
              ],
              const SizedBox(height: 16),
              _buildOrderOverview(),
              if (_invoices.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInvoicesCard(),
              ] else if (_hasPaidPayment && _isInvoicesLoading) ...[
                const SizedBox(height: 16),
                _buildInvoiceLoadingCard(),
              ],
              const SizedBox(height: 16),
              _buildProgressCard(),
              if (_order.workStartSubmission != null ||
                  _order.completionSubmission != null) ...[
                const SizedBox(height: 16),
                _buildCompletionEvidenceCard(),
              ],
              if (_order.status == 'completed' || _warranty?.claim != null) ...[
                const SizedBox(height: 16),
                _buildWarrantySection(),
              ],
              if (_shouldShowRefundSection()) ...[
                const SizedBox(height: 16),
                _buildRefundSection(),
              ],
              if (_order.status == 'quote_accepted') ...[
                const SizedBox(height: 16),
                _buildPaymentPreparationCard(),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String formattedDate) {
    final displayStatus = effectiveCustomerOrderListStatus(
      orderStatus: _order.status,
      refundStatus: _order.refundStatus,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CustomerOrderDetailPage.primaryColor,
            CustomerOrderDetailPage.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261A374D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ORDER #${_order.id.substring(0, _order.id.length.clamp(0, 8)).toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFFBCD0DB),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  _statusIcon(displayStatus),
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _statusText(displayStatus),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  color: Color(0xFFDCE9EF),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFFF0F6F8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerAcceptanceCard() {
    final expired = _order.status == 'worker_acceptance_expired';
    final deadline = _order.workerAcceptanceDeadlineAt;
    final remaining = deadline?.difference(_clockNow) ?? Duration.zero;
    final remainingSeconds = remaining.inSeconds.clamp(0, 30 * 60);
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final waitingForServer =
        !expired && deadline != null && !deadline.isAfter(_clockNow);
    final color = expired || waitingForServer
        ? Colors.red.shade700
        : Colors.orange.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired || waitingForServer
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  expired
                      ? 'Worker tidak menerima pesanan'
                      : waitingForServer
                      ? 'Batas waktu sedang diproses'
                      : 'Menunggu Worker menerima pesanan',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!expired)
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            expired
                ? 'Pesanan tidak dapat diterima lagi. Anda dapat mengajukan refund penuh tanpa mengurangi batas pengajuan refund reguler.'
                : waitingForServer
                ? 'Server sedang memfinalisasi status pesanan. Tarik layar untuk memperbarui dalam beberapa saat.'
                : 'Worker memiliki waktu 30 menit sejak pembayaran berhasil. Waktu server tetap menjadi acuan utama.',
            style: TextStyle(
              color: CustomerOrderDetailPage.primaryColor.withValues(
                alpha: 0.8,
              ),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesCard() {
    return _buildInfoCard(
      icon: Icons.receipt_long_rounded,
      title: 'Invoice Pembayaran',
      child: Column(
        children: _invoices
            .map(
              (invoice) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF15803D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.paymentTargetLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CustomerOrderDetailPage.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                invoice.invoiceNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(invoice.total.round()),
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showInvoiceDetails(invoice),
                            child: const Text('Lihat Detail'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Builder(
                            builder: (buttonContext) => FilledButton.icon(
                              onPressed: _sharingInvoiceId == invoice.id
                                  ? null
                                  : () => _shareInvoicePdf(
                                      invoice,
                                      buttonContext,
                                    ),
                              icon: _sharingInvoiceId == invoice.id
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.ios_share_rounded),
                              label: Text(
                                _sharingInvoiceId == invoice.id
                                    ? 'Menyiapkan'
                                    : 'Bagikan PDF',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    CustomerOrderDetailPage.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInvoiceLoadingCard() {
    return _buildInfoCard(
      icon: Icons.receipt_long_rounded,
      title: 'Invoice Pembayaran',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Menyiapkan invoice pembayaran...',
                style: TextStyle(
                  color: CustomerOrderDetailPage.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInvoicePdf(
    PaymentInvoice invoice,
    BuildContext originContext,
  ) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || _sharingInvoiceId != null) return;
    final renderObject = originContext.findRenderObject();
    final shareOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;
    setState(() => _sharingInvoiceId = invoice.id);
    try {
      final bytes = await _apiService.downloadInvoicePdf(
        token: token,
        invoiceId: invoice.id,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: invoice.invoiceNumber,
          subject: 'Invoice pembayaran Home Workers',
          text:
              '${invoice.paymentTargetLabel} untuk Order #${invoice.orderId}.',
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: ['${invoice.invoiceNumber}.pdf'],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal menyiapkan PDF invoice',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharingInvoiceId = null);
    }
  }

  void _showInvoiceDetails(PaymentInvoice invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: CustomerOrderDetailPage.backgroundGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E1E5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F5EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF16835D),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Pembayaran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CustomerOrderDetailPage.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            color: CustomerOrderDetailPage.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F5EC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'LUNAS',
                      style: TextStyle(
                        color: Color(0xFF16835D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: CustomerOrderDetailPage.surfaceBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _invoiceDetailRow('Jenis', invoice.paymentTargetLabel),
                    _invoiceDetailRow('Layanan', invoice.serviceName),
                    _invoiceDetailRow('Worker', invoice.workerName),
                    _invoiceDetailRow(
                      'Waktu bayar',
                      DateFormat(
                        'dd MMM yyyy • HH:mm',
                        'id_ID',
                      ).format(invoice.paidAt),
                    ),
                    _invoiceDetailRow('Metode', invoice.paymentTypeLabel),
                    _invoiceDetailRow(
                      'ID transaksi',
                      invoice.transactionId ?? invoice.midtransOrderId ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: CustomerOrderDetailPage.surfaceBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _invoiceDetailRow(
                      'Subtotal',
                      _formatCurrency(invoice.subtotal.round()),
                    ),
                    if (invoice.discount > 0) ...[
                      if (invoice.appliedVoucher != null)
                        _invoiceDetailRow('Voucher', invoice.appliedVoucher!),
                      _invoiceDetailRow(
                        'Diskon voucher',
                        '- ${_formatCurrency(invoice.discount.round())}',
                      ),
                    ],
                    const Divider(height: 22),
                    _invoiceDetailRow(
                      'Total dibayar',
                      _formatCurrency(invoice.total.round()),
                      emphasize: true,
                      valueColor: const Color(0xFF16835D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _shareInvoicePdf(invoice, context);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Bagikan / Simpan PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomerOrderDetailPage.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceDetailRow(
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? CustomerOrderDetailPage.primaryColor,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderOverview() {
    final chatBlockedReason = _chatBlockedReason();
    final canChat = chatBlockedReason == null;

    return _buildInfoCard(
      icon: Icons.dashboard_customize_rounded,
      title: 'Ringkasan Pesanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: CustomerOrderDetailPage.secondaryColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order.serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: CustomerOrderDetailPage.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _order.category,
                        style: const TextStyle(
                          color: CustomerOrderDetailPage.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_order.customerAddress.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 17),
              child: Divider(height: 1),
            ),
            _buildOverviewRow(
              icon: Icons.location_on_outlined,
              label: 'Lokasi pekerjaan',
              value: _order.customerAddress,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    _order.workerAvatar != null &&
                        _order.workerAvatar!.isNotEmpty
                    ? NetworkImage(_order.workerAvatar!)
                    : null,
                backgroundColor: const Color(0xFFEAF2F6),
                child: (_order.workerAvatar?.isEmpty ?? true)
                    ? const Icon(
                        Icons.person_rounded,
                        color: CustomerOrderDetailPage.secondaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Worker',
                      style: TextStyle(
                        color: CustomerOrderDetailPage.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _order.workerName ?? 'Belum ada Worker',
                      style: const TextStyle(
                        color: CustomerOrderDetailPage.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (_order.workerName != null)
                IconButton.filledTonal(
                  tooltip: canChat ? 'Chat Worker' : 'Chat tidak tersedia',
                  onPressed: () => _openWorkerChat(chatBlockedReason),
                  style: IconButton.styleFrom(
                    backgroundColor: canChat
                        ? const Color(0xFFEAF2F6)
                        : const Color(0xFFF0F2F3),
                    foregroundColor: canChat
                        ? CustomerOrderDetailPage.primaryColor
                        : Colors.grey,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: CustomerOrderDetailPage.mutedText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: CustomerOrderDetailPage.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CustomerOrderDetailPage.primaryColor,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openWorkerChat(String? chatBlockedReason) async {
    if (chatBlockedReason != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatBlockedReason)));
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null || _order.workerId == null) return;
    try {
      final chatId = await _apiService.createChat(
        token: auth.token!,
        recipientId: _order.workerId!,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            chatId: chatId,
            name: _order.workerName ?? 'Teknisi',
            avatarUrl: _order.workerAvatar ?? '',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(error, action: 'Gagal membuka chat'),
          ),
        ),
      );
    }
  }

  Widget _buildProgressCard() {
    final steps = _buildProgressSteps();
    final currentIndex = _currentProgressIndex(steps);
    final isTerminalStatus = _isTerminalStatus(_order.status);

    return _buildInfoCard(
      icon: Icons.timeline_rounded,
      title: 'Progres Pesanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTerminalStatus) _buildTerminalStatusBanner(),
          for (var i = 0; i < steps.length; i++)
            _buildProgressItem(
              steps[i],
              isCompleted: currentIndex >= 0 && i < currentIndex,
              isActive: currentIndex == i,
              isLast: i == steps.length - 1,
            ),
          const SizedBox(height: 12),
          _buildRealtimeIndicator(),
        ],
      ),
    );
  }

  Widget _buildCompletionEvidenceCard() {
    final startSubmission = _order.workStartSubmission;
    final completionSubmission = _order.completionSubmission;
    final submittedAt = completionSubmission?.submittedAt == null
        ? null
        : DateFormat(
            'd MMM yyyy • HH:mm',
            'id_ID',
          ).format(completionSubmission!.submittedAt!);

    return _buildInfoCard(
      icon: Icons.compare_rounded,
      title: 'Perbandingan Before & After',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEvidenceSection(
            label: 'BEFORE',
            evidence: startSubmission?.beforeEvidence ?? const [],
            accentColor: Colors.orange.shade800,
            emptyText: 'Foto before tidak tersedia untuk order lama.',
          ),
          const SizedBox(height: 20),
          _buildEvidenceSection(
            label: 'AFTER',
            evidence: completionSubmission?.afterEvidence ?? const [],
            accentColor: Colors.green.shade800,
            emptyText: completionSubmission == null
                ? 'Worker belum mengirim foto after.'
                : 'Foto after tidak dapat dimuat.',
          ),
          if (completionSubmission != null) ...[
            const SizedBox(height: 16),
            Text(
              completionSubmission.note,
              style: const TextStyle(height: 1.45),
            ),
          ],
          if (submittedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Foto after dikirim $submittedAt',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (_order.status == 'completion_submitted') ...[
            const SizedBox(height: 14),
            Text(
              'Periksa seluruh bukti sebelum mengonfirmasi. Konfirmasi akan mencairkan pembayaran kepada Worker.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceSection({
    required String label,
    required List<CompletionEvidence> evidence,
    required Color accentColor,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accentColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (evidence.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: evidence.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = evidence[index].url;
                if (url == null || url.isEmpty) {
                  return Container(
                    width: 112,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.broken_image_outlined),
                  );
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showEvidencePreview(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 112,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showEvidencePreview(String url) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: ColoredBox(
            color: const Color(0xFF0D1B24),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Foto tidak dapat dimuat.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filled(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_ProgressStep> _buildProgressSteps() {
    final isSurvey = _order.serviceType == 'survey';
    if (isSurvey) {
      return [
        _ProgressStep(
          id: 'awaiting_payment',
          title: 'Menunggu Pembayaran',
          description: 'Selesaikan pembayaran agar proses bisa dimulai.',
          icon: Icons.payments_rounded,
          activeStatuses: ['awaiting_payment'],
        ),
        _ProgressStep(
          id: 'pending',
          title: 'Menunggu Konfirmasi',
          description: 'Pesanan menunggu konfirmasi dari worker.',
          icon: Icons.access_time_rounded,
          activeStatuses: ['pending'],
        ),
        _ProgressStep(
          id: 'accepted',
          title: 'Diterima Worker',
          description: 'Worker menerima pesanan dan menyiapkan penawaran.',
          icon: Icons.check_circle_rounded,
          activeStatuses: ['accepted'],
        ),
        _ProgressStep(
          id: 'quote_proposed',
          title: _order.status == 'quote_revision_requested'
              ? 'Revisi Harga Diminta'
              : 'Penawaran Diajukan',
          description: _order.status == 'quote_revision_requested'
              ? 'Worker sedang meninjau kembali harga penawaran.'
              : 'Estimasi harga sudah dikirim oleh worker.',
          icon: Icons.request_quote_rounded,
          activeStatuses: const ['quote_proposed', 'quote_revision_requested'],
        ),
        _ProgressStep(
          id: 'quote_accepted',
          title: 'Menunggu Pembayaran Final',
          description: 'Setujui penawaran lalu lakukan pembayaran final.',
          icon: Icons.payment_rounded,
          activeStatuses: ['quote_accepted'],
        ),
        _ProgressStep(
          id: 'ready_to_start',
          title: 'Siap Dimulai',
          description: 'Pembayaran selesai. Worker akan mengambil foto before.',
          icon: Icons.play_circle_outline_rounded,
          activeStatuses: ['ready_to_start'],
        ),
        _ProgressStep(
          id: 'work_in_progress',
          title: 'Pengerjaan Dimulai',
          description: 'Worker sedang mengerjakan pesanan.',
          icon: Icons.build_circle_rounded,
          activeStatuses: ['work_in_progress'],
        ),
        _ProgressStep(
          id: 'completion_submitted',
          title: 'Menunggu Konfirmasi Hasil',
          description: 'Periksa bukti pekerjaan yang dikirim Worker.',
          icon: Icons.fact_check_rounded,
          activeStatuses: ['completion_submitted'],
        ),
        _ProgressStep(
          id: 'completed',
          title: 'Pekerjaan Selesai',
          description: 'Pesanan telah diselesaikan.',
          icon: Icons.verified_rounded,
          activeStatuses: ['completed', 'done'],
        ),
      ];
    }

    return const [
      _ProgressStep(
        id: 'awaiting_payment',
        title: 'Menunggu Pembayaran',
        description: 'Selesaikan pembayaran agar proses bisa dimulai.',
        icon: Icons.payments_rounded,
        activeStatuses: ['awaiting_payment'],
      ),
      _ProgressStep(
        id: 'pending',
        title: 'Menunggu Konfirmasi',
        description: 'Pesanan menunggu konfirmasi dari worker.',
        icon: Icons.access_time_rounded,
        activeStatuses: ['pending'],
      ),
      _ProgressStep(
        id: 'ready_to_start',
        title: 'Siap Dimulai',
        description: 'Worker akan mengambil foto before sebelum bekerja.',
        icon: Icons.play_circle_outline_rounded,
        activeStatuses: ['accepted', 'ready_to_start'],
      ),
      _ProgressStep(
        id: 'work_in_progress',
        title: 'Pengerjaan Dimulai',
        description: 'Worker sedang mengerjakan pesanan.',
        icon: Icons.build_circle_rounded,
        activeStatuses: ['work_in_progress'],
      ),
      _ProgressStep(
        id: 'completion_submitted',
        title: 'Menunggu Konfirmasi Hasil',
        description: 'Periksa bukti pekerjaan yang dikirim Worker.',
        icon: Icons.fact_check_rounded,
        activeStatuses: ['completion_submitted'],
      ),
      _ProgressStep(
        id: 'completed',
        title: 'Pekerjaan Selesai',
        description: 'Pesanan telah diselesaikan.',
        icon: Icons.verified_rounded,
        activeStatuses: ['completed', 'done'],
      ),
    ];
  }

  int _currentProgressIndex(List<_ProgressStep> steps) {
    if (_isTerminalStatus(_order.status)) return -1;
    final index = steps.indexWhere(
      (step) => step.activeStatuses.contains(_order.status),
    );
    return index == -1 ? 0 : index;
  }

  bool _isTerminalStatus(String status) {
    return status == 'cancelled' ||
        status == 'quote_rejected' ||
        status == 'rejected' ||
        status == 'worker_acceptance_expired';
  }

  Widget _buildTerminalStatusBanner() {
    final statusLabel = _statusText(_order.status);
    final surveyCompleted = _order.status == 'quote_rejected';
    final backgroundColor = surveyCompleted
        ? Colors.green.shade50
        : Colors.red.shade50;
    final borderColor = surveyCompleted
        ? Colors.green.shade200
        : Colors.red.shade200;
    final foregroundColor = surveyCompleted
        ? Colors.green.shade700
        : Colors.red.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            surveyCompleted ? Icons.verified_outlined : Icons.info_outline,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status akhir: $statusLabel',
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    _ProgressStep step, {
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final Color activeColor = isCompleted
        ? const Color(0xFF4CAF50)
        : isActive
        ? CustomerOrderDetailPage.primaryColor
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? activeColor : Colors.white,
                border: Border.all(color: activeColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Icon(
                      step.icon,
                      size: 14,
                      color: isActive ? Colors.white : activeColor,
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: activeColor.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : isActive
                        ? CustomerOrderDetailPage.primaryColor
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeIndicator() {
    final Color indicatorColor = _isRealtimeActive
        ? const Color(0xFF4CAF50)
        : Colors.grey;
    final String label = _isRealtimeActive
        ? 'Realtime aktif'
        : 'Menghubungkan pembaruan...';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: indicatorColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CustomerOrderDetailPage.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CustomerOrderDetailPage.surfaceBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A374D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: CustomerOrderDetailPage.secondaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: CustomerOrderDetailPage.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentPreparationCard() {
    final quotedPrice = (_order.quotedPrice ?? 0).toInt();
    final finalPrice = quotedPrice - _discount;

    return _buildInfoCard(
      icon: Icons.payments_rounded,
      title: 'Pembayaran Akhir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga yang diajukan',
                style: TextStyle(color: CustomerOrderDetailPage.mutedText),
              ),
              Text(
                _formatCurrency(quotedPrice),
                style: const TextStyle(
                  color: CustomerOrderDetailPage.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diskon voucher',
                  style: TextStyle(color: Color(0xFF16835D)),
                ),
                Text(
                  '- ${_formatCurrency(_discount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16835D),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total pembayaran',
                style: TextStyle(
                  color: CustomerOrderDetailPage.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatCurrency(finalPrice),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: CustomerOrderDetailPage.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Voucher',
            style: TextStyle(
              color: CustomerOrderDetailPage.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_vouchers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F9),
                border: Border.all(
                  color: CustomerOrderDetailPage.surfaceBorder,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Tidak ada voucher yang tersedia',
                style: TextStyle(color: CustomerOrderDetailPage.mutedText),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showVoucherSelectionDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F9),
                  border: Border.all(
                    color: CustomerOrderDetailPage.surfaceBorder,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      color: CustomerOrderDetailPage.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedVoucher != null
                            ? _getVoucherDisplayText(_selectedVoucher!)
                            : 'Pilih voucher',
                        style: TextStyle(
                          color: _selectedVoucher != null
                              ? CustomerOrderDetailPage.primaryColor
                              : CustomerOrderDetailPage.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
          if (_voucherMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                _voucherMessage!,
                style: TextStyle(
                  color: _appliedVoucherCode != null
                      ? Colors.green
                      : Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          if (_appliedVoucherCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: _resetVoucher,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Batalkan Voucher'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _warrantyRemainingLabel(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Masa garansi berakhir';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    if (days > 0) return 'Tersisa $days hari $hours jam';
    final minutes = remaining.inMinutes.remainder(60);
    return 'Tersisa $hours jam $minutes menit';
  }

  Future<void> _openWarrantyClaim() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WarrantyClaimSheet(
        onSubmit:
            ({
              required issueType,
              required description,
              required preferredVisitAt,
              required declarationAccepted,
              required evidence,
            }) => _apiService.createWarrantyClaim(
              token: auth.token!,
              orderId: _order.id,
              issueType: issueType,
              description: description,
              preferredVisitAt: preferredVisitAt,
              declarationAccepted: declarationAccepted,
              evidencePaths: evidence.map((item) => item.path).toList(),
            ),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klaim garansi berhasil dikirim untuk ditinjau.'),
        ),
      );
      await _refreshOrderDetails();
    }
  }

  Future<void> _openWarrantyAdditionalEvidence(WarrantyClaim claim) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    final instruction =
        claim.adminDecision?['reason']?.toString() ??
        'Admin membutuhkan bukti tambahan untuk memeriksa klaim garansi.';
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RefundAdditionalEvidenceSheet(
        instruction: instruction,
        onSubmit: (note, evidence) =>
            _apiService.submitWarrantyAdditionalEvidence(
              token: auth.token!,
              claimId: claim.id,
              note: note,
              evidencePaths: evidence.map((item) => item.path).toList(),
            ),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti tambahan berhasil dikirim.')),
      );
      await _refreshOrderDetails();
    }
  }

  Future<void> _confirmWarrantyRepair({
    required WarrantyClaim claim,
    required bool accepted,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    final noteController = TextEditingController();
    String? error;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3DDE2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    accepted
                        ? Icons.verified_rounded
                        : Icons.report_problem_outlined,
                    color: accepted
                        ? const Color(0xFF16835D)
                        : const Color(0xFFB76E00),
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    accepted
                        ? 'Perbaikan sudah sesuai?'
                        : 'Masalah masih terjadi?',
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accepted
                        ? 'Konfirmasi akan menutup klaim garansi ini.'
                        : 'Jelaskan bagian yang masih bermasalah. Kasus akan diteruskan kepada Admin.',
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.mutedText,
                      height: 1.4,
                    ),
                  ),
                  if (!accepted) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Masalah yang masih terjadi',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!accepted &&
                                noteController.text.trim().length < 20) {
                              setSheetState(
                                () => error = 'Penjelasan minimal 20 karakter.',
                              );
                              return;
                            }
                            Navigator.pop(sheetContext, true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accepted
                                ? const Color(0xFF16835D)
                                : const Color(0xFFB76E00),
                          ),
                          child: Text(
                            accepted ? 'Ya, Selesaikan' : 'Eskalasi ke Admin',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }
    try {
      await _apiService.confirmWarrantyRepair(
        token: auth.token!,
        claimId: claim.id,
        accepted: accepted,
        note: noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Perbaikan garansi telah diselesaikan.'
                : 'Kasus diteruskan kepada Admin.',
          ),
        ),
      );
      await _refreshOrderDetails();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.readableError(
                error,
                action: 'Gagal mengonfirmasi perbaikan',
              ),
            ),
          ),
        );
      }
    } finally {
      noteController.dispose();
    }
  }

  Widget _buildWarrantyEvidenceStrip(
    String title,
    List<WarrantyEvidence> evidence,
  ) {
    if (evidence.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CustomerOrderDetailPage.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: evidence.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = evidence[index].url;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 78,
                  height: 78,
                  color: const Color(0xFFEAF2F6),
                  child: url == null
                      ? const Icon(Icons.broken_image_outlined)
                      : Image.network(url, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantySection() {
    final warranty = _warranty;
    final claim = warranty?.claim;
    final eligibility = warranty?.eligibility;
    final expiry =
        eligibility?.expiresAt ??
        _order.warrantyExpiresAt ??
        _order.completionConfirmedAt?.add(const Duration(days: 7)) ??
        _order.completedAt?.add(const Duration(days: 7));

    return _buildInfoCard(
      icon: Icons.verified_user_outlined,
      title: 'Garansi Pekerjaan',
      child: claim == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expiry != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expiry.isAfter(DateTime.now())
                                  ? 'Garansi aktif'
                                  : 'Garansi berakhir',
                              style: TextStyle(
                                color: expiry.isAfter(DateTime.now())
                                    ? const Color(0xFF16835D)
                                    : CustomerOrderDetailPage.mutedText,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Sampai ${DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(expiry)}',
                              style: const TextStyle(
                                color: CustomerOrderDetailPage.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (expiry.isAfter(DateTime.now()))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EF),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _warrantyRemainingLabel(expiry),
                            style: const TextStyle(
                              color: Color(0xFF16835D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'Mencakup masalah yang sama, kesalahan pengerjaan, atau kerusakan akibat pekerjaan awal. Permintaan tambahan di luar pekerjaan tidak termasuk.',
                  style: TextStyle(
                    color: CustomerOrderDetailPage.mutedText,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                if (eligibility?.eligible == true) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openWarrantyClaim,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: CustomerOrderDetailPage.primaryColor,
                    ),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Ajukan Klaim Garansi'),
                  ),
                ] else if (eligibility?.reason != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    eligibility!.reason!,
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    claim.statusLabel,
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.secondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  claim.description,
                  style: const TextStyle(
                    color: CustomerOrderDetailPage.primaryColor,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (claim.workerResponse?['scheduledAt'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Jadwal Worker: ${_formatWarrantyDynamicDate(claim.workerResponse!['scheduledAt'])}',
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (claim.adminDecision?['reason'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan Admin: ${claim.adminDecision!['reason']}',
                    style: const TextStyle(
                      color: CustomerOrderDetailPage.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (claim.repair != null) ...[
                  const SizedBox(height: 16),
                  _buildWarrantyEvidenceStrip(
                    'Foto before perbaikan',
                    claim.repair!.beforeEvidence,
                  ),
                  if (claim.repair!.afterEvidence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildWarrantyEvidenceStrip(
                      'Foto after perbaikan',
                      claim.repair!.afterEvidence,
                    ),
                  ],
                ],
                if (claim.status == 'more_evidence_required') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openWarrantyAdditionalEvidence(claim),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Lengkapi Bukti'),
                  ),
                ],
                if (claim.status == 'customer_confirmation') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmWarrantyRepair(
                            claim: claim,
                            accepted: false,
                          ),
                          child: const Text('Masih Bermasalah'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _confirmWarrantyRepair(
                            claim: claim,
                            accepted: true,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16835D),
                          ),
                          child: const Text('Sudah Sesuai'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  String _formatWarrantyDynamicDate(dynamic value) {
    DateTime? date;
    if (value is String) date = DateTime.tryParse(value)?.toLocal();
    if (value is Map && value['_seconds'] is num) {
      date = DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      ).toLocal();
    }
    return date == null
        ? '-'
        : DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(date);
  }

  bool _shouldShowRefundSection() {
    if (_refundRequest != null) return true;
    final paid =
        _order.paymentStatus == 'paid' || _order.finalPaymentStatus == 'paid';
    return paid &&
        {
          'pending',
          'accepted',
          'quote_proposed',
          'quote_revision_requested',
          'quote_accepted',
          'ready_to_start',
          'work_in_progress',
          'completion_submitted',
          'completed',
        }.contains(_order.status);
  }

  Future<void> _openRefundRequest() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RefundRequestSheet(
        order: _order,
        onSubmit:
            ({
              required reasonCode,
              required resolutionRequested,
              required description,
              required paymentTarget,
              required contactedWorker,
              required declarationAccepted,
              requestedAmount,
              required evidence,
            }) async {
              await _apiService.createRefundRequest(
                token: token,
                orderId: _order.id,
                reasonCode: reasonCode,
                resolutionRequested: resolutionRequested,
                description: description,
                paymentTarget: paymentTarget,
                contactedWorker: contactedWorker,
                declarationAccepted: declarationAccepted,
                requestedAmount: requestedAmount,
                evidencePaths: evidence.map((item) => item.path).toList(),
              );
            },
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan refund berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrderDetails();
    }
  }

  Future<void> _requestAcceptanceTimeoutRefund() async {
    final confirmed = await _showConfirmationSheet(
      icon: Icons.currency_exchange_rounded,
      title: 'Ajukan refund penuh?',
      message:
          'Worker tidak menerima pesanan dalam 30 menit. Pengajuan akan langsung diperiksa Admin dan tidak mengurangi batas refund reguler Anda.',
      confirmLabel: 'Ajukan Refund',
      cancelLabel: 'Nanti',
      confirmColor: const Color(0xFFB42318),
    );
    if (confirmed != true || !mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.createAcceptanceTimeoutRefund(
        token: token,
        orderId: _order.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refund penuh berhasil diajukan untuk pemeriksaan Admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrderDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal mengajukan refund timeout',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAdditionalRefundEvidence(RefundRequest refund) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final instruction =
        refund.adminDecision?['reason']?.toString() ??
        'Admin meminta bukti tambahan untuk melanjutkan pemeriksaan.';
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RefundAdditionalEvidenceSheet(
        instruction: instruction,
        onSubmit: (note, evidence) =>
            _apiService.submitRefundAdditionalEvidence(
              token: token,
              refundId: refund.id,
              note: note,
              evidencePaths: evidence.map((item) => item.path).toList(),
            ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti tambahan berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrderDetails();
    }
  }

  Widget _buildRefundSection() {
    final refund = _refundRequest;
    return _buildInfoCard(
      icon: Icons.support_agent_rounded,
      title: 'Bantuan & Refund',
      child: refund == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _order.status == 'completion_submitted'
                      ? 'Jika hasil belum sesuai, ajukan masalah sebelum mengonfirmasi pekerjaan.'
                      : 'Ajukan masalah dengan kronologi dan bukti. Admin akan memeriksa transaksi serta bukti pekerjaan.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _openRefundRequest,
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(
                    {
                          'pending',
                          'accepted',
                          'quote_proposed',
                          'quote_revision_requested',
                          'quote_accepted',
                          'ready_to_start',
                        }.contains(_order.status)
                        ? 'Batalkan & Ajukan Refund'
                        : 'Laporkan Masalah',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: refund.status == 'rejected'
                        ? Colors.red.shade50
                        : refund.status == 'refunded'
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    refund.statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  refund.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                if (refund.approvedAmount != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Nominal disetujui: ${_formatCurrency(refund.approvedAmount!.round())}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                if (refund.workerResponse != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Worker telah memberikan tanggapan.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                if (refund.status == 'more_evidence_required' &&
                    refund.evidenceRequestedFrom != 'worker') ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _openAdditionalRefundEvidence(refund),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Lengkapi Bukti yang Diminta'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: CustomerOrderDetailPage.primaryColor,
                    ),
                  ),
                ],
                if (refund.status == 'awaiting_refund_destination') ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _openManualRefundDestination(refund),
                    icon: const Icon(Icons.account_balance_outlined),
                    label: const Text('Isi Rekening / E-Wallet Tujuan'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: CustomerOrderDetailPage.primaryColor,
                    ),
                  ),
                ],
                if (refund.status == 'rework_offered') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _respondToRework(refund, accept: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _respondToRework(refund, accept: true),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                CustomerOrderDetailPage.primaryColor,
                          ),
                          child: const Text('Terima Perbaikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  InputDecoration _sheetInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: CustomerOrderDetailPage.surfaceBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: CustomerOrderDetailPage.surfaceBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: CustomerOrderDetailPage.secondaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _openManualRefundDestination(RefundRequest refund) async {
    final providerController = TextEditingController();
    final accountController = TextEditingController();
    final holderController = TextEditingController();
    var destinationType = 'bank';
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
            ),
            decoration: const BoxDecoration(
              color: CustomerOrderDetailPage.backgroundGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9E1E5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tujuan Refund',
                    style: TextStyle(
                      color: CustomerOrderDetailPage.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan rekening atau e-wallet untuk menerima dana refund.',
                    style: TextStyle(
                      color: CustomerOrderDetailPage.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2F6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: CustomerOrderDetailPage.secondaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Data dienkripsi dan hanya dapat dibuka oleh Admin yang memproses refund.',
                            style: TextStyle(
                              color: CustomerOrderDetailPage.secondaryColor,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: destinationType,
                    decoration: _sheetInputDecoration(
                      label: 'Jenis tujuan',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text('Rekening bank'),
                      ),
                      DropdownMenuItem(
                        value: 'ewallet',
                        child: Text('E-Wallet'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => destinationType = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: providerController,
                    decoration: _sheetInputDecoration(
                      label: 'Nama bank / e-wallet',
                      icon: Icons.business_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: _sheetInputDecoration(
                      label: 'Nomor rekening / e-wallet',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: holderController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _sheetInputDecoration(
                      label: 'Nama pemilik',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                CustomerOrderDetailPage.primaryColor,
                            side: const BorderSide(
                              color: CustomerOrderDetailPage.surfaceBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (providerController.text.trim().length < 2 ||
                                accountController.text.trim().length < 6 ||
                                holderController.text.trim().length < 3) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lengkapi seluruh data tujuan refund.',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(sheetContext, {
                              'destinationType': destinationType,
                              'providerName': providerController.text.trim(),
                              'accountNumber': accountController.text.trim(),
                              'accountHolder': holderController.text.trim(),
                            });
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                CustomerOrderDetailPage.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    providerController.dispose();
    accountController.dispose();
    holderController.dispose();
    if (result == null || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.submitManualRefundDestination(
        token: auth.token!,
        refundId: refund.id,
        destinationType: result['destinationType']!,
        providerName: result['providerName']!,
        accountNumber: result['accountNumber']!,
        accountHolder: result['accountHolder']!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tujuan refund berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshOrderDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal menyimpan tujuan refund',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToRework(
    RefundRequest refund, {
    required bool accept,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.respondToRefundRework(
        token: auth.token!,
        refundId: refund.id,
        accept: accept,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Perbaikan ulang telah diterima.'
                : 'Pengajuan dikembalikan untuk ditinjau Admin.',
          ),
        ),
      );
      await _refreshOrderDetails();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal merespons perbaikan',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showReviewSheet() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final submitted = await showOrderReviewSheet(
      context: context,
      serviceName: _order.serviceName,
      workerName: _order.workerName,
      onSubmit: (rating, comment) async {
        final token = auth.token;
        if (token == null) throw Exception('Sesi login telah berakhir.');
        try {
          await _apiService.submitReview(
            token: token,
            orderId: _order.id,
            rating: rating,
            comment: comment,
          );
        } catch (error) {
          throw Exception(
            ApiService.readableError(error, action: 'Gagal mengirim ulasan'),
          );
        }
      },
    );
    if (!submitted || !mounted) return;
    setState(() => _order = _order.copyWith(hasBeenReviewed: true));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terima kasih, ulasan berhasil dikirim.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_order.status == 'worker_acceptance_expired' &&
        _refundRequest == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _requestAcceptanceTimeoutRefund,
          icon: const Icon(Icons.currency_exchange_rounded),
          label: const Text('Ajukan Refund Penuh'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (_order.status == 'completion_submitted') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          // Konfirmasi memiliki dialog sendiri dan melakukan refresh token.
          // Jangan memakai guard global karena aksi dapat terabaikan diam-diam
          // ketika ada proses lain yang masih menahan ActionTapGuard._busy.
          onPressed: _confirmCompletion,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: const Color(0xFF1A374D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Konfirmasi Pekerjaan Selesai',
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_order.status == 'quote_proposed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              ActionTapGuard.run(
                context,
                () => _respondToQuote('accept'),
                label: 'Memproses',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Terima Penawaran'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _requestQuoteRevision,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Minta Revisi Harga'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB76E00),
              side: const BorderSide(color: Color(0xFFB76E00)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ActionTapGuard.run(
                context,
                () => _respondToQuote('reject'),
                label: 'Memproses',
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
              side: const BorderSide(color: Color(0xFFF44336)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tolak Penawaran'),
          ),
        ],
      );
    }

    if (_order.status == 'quote_revision_requested') {
      final reason = _order.quoteRevisionRequest?.reason.trim();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD591)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_rounded, color: Color(0xFFB76E00)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Menunggu revisi harga dari Worker',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(reason, style: const TextStyle(height: 1.4)),
            ],
          ],
        ),
      );
    }

    if (_order.status == 'quote_accepted') {
      final hasInvalidVoucher = _appliedVoucherCode != null && !_isVoucherValid;
      final isDisabled = hasInvalidVoucher || _isStartingPayment;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasInvalidVoucher)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voucher tidak dapat digunakan. Perbaiki atau hapus voucher untuk melanjutkan pembayaran.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDisabled
                  ? null
                  // _handlePayment menunggu route Snap ditutup agar detail
                  // dapat dimuat ulang. Jangan bungkus dengan ActionTapGuard:
                  // overlay root-nya ikut terbawa ke route Snap dan baru akan
                  // hilang setelah route tersebut ditutup.
                  : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasInvalidVoucher
                    ? Colors.grey.shade400
                    : const Color(0xFF2196F3),
                foregroundColor: hasInvalidVoucher
                    ? Colors.grey.shade600
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: hasInvalidVoucher ? 0 : 2,
              ),
              child: _isStartingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Membuka pembayaran...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasInvalidVoucher ? Icons.block : Icons.payment,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasInvalidVoucher
                              ? 'Pembayaran Dinonaktifkan'
                              : 'Bayar Sekarang',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    }

    if (_order.status == 'completed' && !_order.hasBeenReviewed) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('detail-review-button'),
          onPressed: _showReviewSheet,
          icon: const Icon(Icons.star_rounded),
          label: const Text('Beri Rating & Ulasan'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF6AE2D),
            foregroundColor: const Color(0xFF3B2A00),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ProgressStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> activeStatuses;

  const _ProgressStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.activeStatuses,
  });
}
