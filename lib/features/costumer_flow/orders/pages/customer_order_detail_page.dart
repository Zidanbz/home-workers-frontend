import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/helper/voucher_helper.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/snapPayment_page.dart';
import 'package:home_workers_fe/features/costumer_flow/vouchers/pages/voucher_detail_page.dart';
import 'package:home_workers_fe/shared_widgets/action_tap_guard.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/models/order_model.dart';

class CustomerOrderDetailPage extends StatefulWidget {
  final Order initialOrder;

  static const Color primaryColor = Color(0xFF1A374D);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  const CustomerOrderDetailPage({super.key, required this.initialOrder});

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  late Order _order;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _orderSubscription;
  bool _isRealtimeActive = false;

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
    if (_order.status == 'quote_accepted') {
      _fetchVouchers();
    }
    _startRealtimeOrderListener();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
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

    print('DEBUG: _validateAndApplyVoucher - voucherCode: $voucherCode, quotedPrice: $quotedPrice');

    try {
      final result = await _apiService.validateVoucherCode(
        token: token!,
        voucherCode: voucherCode,
        orderAmount: quotedPrice,
      );

      print('DEBUG: _validateAndApplyVoucher - result: $result');

      final discount = (result['discount'] ?? 0) as int;
      final finalTotal = (result['finalTotal'] ?? (quotedPrice - discount)) as int;

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
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _selectedVoucher = null;
        _discount = 0;
        _appliedVoucherCode = null;
        _voucherMessage = 'Gagal: $errorMessage';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Pilih Voucher',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CustomerOrderDetailPage.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _vouchers[index];
                    final code = voucher['code'] as String;
                    final discountType = voucher['discountType'];
                    final value = voucher['value'];
                    final label = discountType == 'percent'
                        ? '$code • ${value}%'
                        : '$code • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(label),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VoucherDetailPage(
                                  voucher: voucher,
                                ),
                              ),
                            );
                          },
                          child: const Text('Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: CustomerOrderDetailPage.primaryColor,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedVoucher = code;
                          });
                          _validateAndApplyVoucher(code);
                          Navigator.pop(context);
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
        ? '$voucherCode • ${value}%'
        : '$voucherCode • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _refreshOrderDetails() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedOrder = await _apiService.getOrderById(
        token: auth.token!,
        orderId: _order.id,
      );
      if (mounted) {
        setState(() {
          _order = updatedOrder;
        });
      }
      if (mounted &&
          updatedOrder.status == 'quote_accepted' &&
          _vouchers.isEmpty) {
        _fetchVouchers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data terbaru: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startRealtimeOrderListener() {
    _orderSubscription?.cancel();
    _orderSubscription = _firestore
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
    final workerId = data['workerId'] as String?;
    final workerName = data['workerName'] as String?;
    final workerAvatar = data['workerAvatar'] as String?;
    final hasBeenReviewed = data['hasBeenReviewed'] as bool?;
    final paymentStatus = data['paymentStatus'] as String?;
    final finalPaymentStatus = data['finalPaymentStatus'] as String?;
    final completedAt = _parseOptionalTimestamp(data['completedAt']);
    final jadwalPerbaikan = _parseTimestamp(
      data['jadwalPerbaikan'],
      _order.jadwalPerbaikan,
    );
    final dibuatPada = _parseTimestamp(data['dibuatPada'], _order.dibuatPada);
    final shouldFetchVouchers =
        status == 'quote_accepted' && _vouchers.isEmpty;

    if (!mounted) return;
    setState(() {
      _order = _order.copyWith(
        status: status ?? _order.status,
        quotedPrice: quotedPrice ?? _order.quotedPrice,
        workerId: workerId ?? _order.workerId,
        workerName: workerName ?? _order.workerName,
        workerAvatar: workerAvatar ?? _order.workerAvatar,
        jadwalPerbaikan: jadwalPerbaikan,
        dibuatPada: dibuatPada,
        hasBeenReviewed: hasBeenReviewed ?? _order.hasBeenReviewed,
        paymentStatus: paymentStatus ?? _order.paymentStatus,
        finalPaymentStatus: finalPaymentStatus ?? _order.finalPaymentStatus,
        completedAt: completedAt ?? _order.completedAt,
      );
      _isRealtimeActive = true;
    });

    if (shouldFetchVouchers) {
      _fetchVouchers();
    }
  }

  DateTime _parseTimestamp(dynamic value, DateTime fallback) {
    if (value == null) return fallback;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    if (value is String) {
      return DateTime.tryParse(value);
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
        'work_in_progress',
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
    return DateTime.now().difference(completedAt) <= const Duration(days: 3);
  }

  String? _chatBlockedReason() {
    if (_order.workerId == null) return 'Belum ada worker yang ditugaskan.';
    if (!_isPaymentCompleted(_order)) {
      return 'Chat tersedia setelah pembayaran berhasil.';
    }
    if (_isOrderCompleted(_order.status) && !_isWithinChatWindow(_order)) {
      return 'Chat sudah ditutup. Maksimal 3 hari setelah pesanan selesai.';
    }
    return null;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'awaiting_payment':
        return const Color(0xFFFFC107);
      case 'accepted':
      case 'quote_proposed':
        return const Color(0xFF2196F3);
      case 'quote_accepted':
        return const Color(0xFF4CAF50);
      case 'work_in_progress':
        return const Color(0xFF9C27B0);
      case 'completed':
      case 'done':
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'quote_rejected':
      case 'rejected':
        return const Color(0xFFF44336);
      case 'waiting':
        return const Color(0xFF9E9E9E);
      case 'on_the_way':
        return const Color(0xFF03A9F4);
      default:
        return CustomerOrderDetailPage.lightGray;
    }
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
      case 'quote_accepted':
        return Icons.payment_rounded;
      case 'work_in_progress':
        return Icons.build_circle_rounded;
      case 'completed':
      case 'done':
      case 'paid':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'quote_rejected':
      case 'rejected':
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
      case 'quote_accepted':
        return 'Siap Bayar';
      case 'work_in_progress':
        return 'Dalam Pengerjaan';
      case 'completed':
      case 'done':
        return 'Selesai';
      case 'paid':
        return 'Pembayaran Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      case 'quote_rejected':
        return 'Penawaran Ditolak';
      case 'rejected':
        return 'Ditolak';
      case 'waiting':
        return 'Menunggu';
      case 'on_the_way':
        return 'Dalam Perjalanan';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Future<void> _handlePayment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);
    try {
      final paymentData = await _apiService.startPaymentForQuote(
        token: auth.token!,
        orderId: _order.id,
        voucherCode: _appliedVoucherCode,
      );
      final snapToken = paymentData['snapToken'];
      final snapRedirectUrl =
          "https://app.midtrans.com/snap/v2/vtweb/$snapToken";

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SnapPaymentPage(redirectUrl: snapRedirectUrl),
        ),
      );

      await _refreshOrderDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memulai pembayaran: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToQuote(String decision) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await _apiService.respondToQuote(
        token: auth.token!,
        orderId: _order.id,
        decision: decision,
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
          SnackBar(content: Text('Gagal memproses penawaran: $e')),
        );
      }
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
            fontWeight: FontWeight.w700,
            color: CustomerOrderDetailPage.primaryColor,
          ),
        ),
        backgroundColor: CustomerOrderDetailPage.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: CustomerOrderDetailPage.primaryColor,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrderDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(formattedDate),
              const SizedBox(height: 24),
              _buildServiceInfo(),
              const SizedBox(height: 20),
              _buildScheduleCard(formattedDate),
              // const SizedBox(height: 20),
              // _buildDescriptionCard(),
              const SizedBox(height: 20),
              _buildWorkerCard(),
              const SizedBox(height: 20),
              _buildProgressCard(),
              if (_order.status == 'quote_accepted') ...[
                const SizedBox(height: 20),
                _buildPriceCard(),
                const SizedBox(height: 20),
                _buildVoucherSection(),
              ],
              const SizedBox(height: 32),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor(_order.status).withOpacity(0.15),
            _statusColor(_order.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(_order.status).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor(_order.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _statusIcon(_order.status),
              color: _statusColor(_order.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText(_order.status),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _statusColor(_order.status),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomerOrderDetailPage.primaryColor.withOpacity(
                      0.7,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return _buildInfoCard(
      icon: Icons.build_rounded,
      title: 'Informasi Layanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _order.serviceName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CustomerOrderDetailPage.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text('Kategori: ${_order.category}'),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String formattedDate) {
    return _buildInfoCard(
      icon: Icons.schedule_rounded,
      title: 'Jadwal Perbaikan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            // child: Text(_order.customerAddress),
          ),
        ],
      ),
    );
  }

  // Widget _buildDescriptionCard() {
  //   // Asumsi: Model Order memiliki field `description` untuk deskripsi masalah.
  //   // Ganti `_order.description` jika nama fieldnya berbeda.
  //   return _buildInfoCard(
  //     icon: Icons.description_rounded,
  //     title: 'Deskripsi Masalah',
  //     child: Text(
  //       _order.workerDescription ?? 'Tidak ada deskripsi dari customer.',
  //     ),
  //   );
  // }

  Widget _buildWorkerCard() {
    final chatBlockedReason = _chatBlockedReason();
    final canChat = chatBlockedReason == null;

    return _buildInfoCard(
      icon: Icons.person_rounded,
      title: 'Dikerjakan oleh',
      child: _order.workerName != null
          ? Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      _order.workerAvatar != null &&
                          _order.workerAvatar!.isNotEmpty
                      ? NetworkImage(_order.workerAvatar!)
                      : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_order.workerName!)),
                TextButton.icon(
                  onPressed: () async {
                    if (!canChat) {
                      if (chatBlockedReason != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(chatBlockedReason)),
                        );
                      }
                      return;
                    }
                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (auth.token == null || _order.workerId == null) return;
                    try {
                      final chatId = await _apiService.createChat(
                        token: auth.token!,
                        recipientId: _order.workerId!,
                      );
                      if (mounted) {
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
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuka chat: $e')),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        canChat ? CustomerOrderDetailPage.primaryColor : Colors.grey,
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(canChat ? 'Chat' : 'Chat Nonaktif'),
                ),
              ],
            )
          : const Text('Belum ada worker yang ditugaskan.'),
    );
  }

  Widget _buildProgressCard() {
    final steps = _buildProgressSteps();
    final currentIndex = _currentProgressIndex(steps);
    final isTerminalStatus = _isTerminalStatus(_order.status);

    return _buildInfoCard(
      icon: Icons.timeline_rounded,
      title: 'Monitor Progres Real-Time',
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

  List<_ProgressStep> _buildProgressSteps() {
    final isSurvey = _order.serviceType == 'survey';
    if (isSurvey) {
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
          id: 'accepted',
          title: 'Diterima Worker',
          description: 'Worker menerima pesanan dan menyiapkan penawaran.',
          icon: Icons.check_circle_rounded,
          activeStatuses: ['accepted'],
        ),
        _ProgressStep(
          id: 'quote_proposed',
          title: 'Penawaran Diajukan',
          description: 'Estimasi harga sudah dikirim oleh worker.',
          icon: Icons.request_quote_rounded,
          activeStatuses: ['quote_proposed'],
        ),
        _ProgressStep(
          id: 'quote_accepted',
          title: 'Menunggu Pembayaran Final',
          description: 'Setujui penawaran lalu lakukan pembayaran final.',
          icon: Icons.payment_rounded,
          activeStatuses: ['quote_accepted'],
        ),
        _ProgressStep(
          id: 'work_in_progress',
          title: 'Pengerjaan Dimulai',
          description: 'Worker sedang mengerjakan pesanan.',
          icon: Icons.build_circle_rounded,
          activeStatuses: ['work_in_progress'],
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
        id: 'work_in_progress',
        title: 'Pengerjaan Dimulai',
        description: 'Worker sedang mengerjakan pesanan.',
        icon: Icons.build_circle_rounded,
        activeStatuses: ['accepted', 'work_in_progress'],
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
        status == 'rejected';
  }

  Widget _buildTerminalStatusBanner() {
    final statusLabel = _statusText(_order.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status akhir: $statusLabel',
              style: TextStyle(
                color: Colors.red.shade700,
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
                color: activeColor.withOpacity(0.4),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeIndicator() {
    final Color indicatorColor =
        _isRealtimeActive ? const Color(0xFF4CAF50) : Colors.grey;
    final String label =
        _isRealtimeActive ? 'Realtime aktif' : 'Menghubungkan pembaruan...';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: indicatorColor),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomerOrderDetailPage.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CustomerOrderDetailPage.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    final quotedPrice = (_order.quotedPrice ?? 0).toInt();
    final finalPrice = quotedPrice - _discount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomerOrderDetailPage.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                color: CustomerOrderDetailPage.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rincian Harga',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga yang Diajukan',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _formatCurrency(quotedPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
                  'Diskon Voucher',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
                Text(
                  '- ${_formatCurrency(_discount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(finalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomerOrderDetailPage.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomerOrderDetailPage.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: CustomerOrderDetailPage.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pilih Voucher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_vouchers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tidak ada voucher yang tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            InkWell(
              onTap: () => _showVoucherSelectionDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedVoucher != null
                            ? _getVoucherDisplayText(_selectedVoucher!)
                            : 'Pilih voucher',
                        style: TextStyle(
                          color: _selectedVoucher != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
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
                  color: _appliedVoucherCode != null ? Colors.green : Colors.red,
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
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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

    if (_order.status == 'quote_accepted') {
      final isDisabled = _appliedVoucherCode != null && !_isVoucherValid;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDisabled)
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
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 20),
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
                  : () {
                      ActionTapGuard.run(
                        context,
                        _handlePayment,
                        label: 'Membuka pembayaran',
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey.shade400 : const Color(0xFF2196F3),
                foregroundColor: isDisabled ? Colors.grey.shade600 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isDisabled ? 0 : 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDisabled ? Icons.block : Icons.payment,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDisabled ? 'Pembayaran Dinonaktifkan' : 'Bayar Sekarang',
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

    // Anda bisa menambahkan tombol lain di sini,
    // misalnya tombol untuk memberi ulasan jika status 'completed'
    // if (_order.status == 'completed' && !_order.hasBeenReviewed) {
    //   return ...
    // }

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
