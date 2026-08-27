import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/customer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/customer_flow/orders/pages/customer_order_detail_page.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/order_review_sheet.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/utils/order_list_policy.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/services/realtime_notification_service.dart';
import '../../../../shared_widgets/order_summary_card.dart';
import '../../../../shared_widgets/content_loading_skeleton.dart';

class CustomerOrdersPage extends StatefulWidget {
  final double bottomNavigationClearance;

  const CustomerOrdersPage({super.key, this.bottomNavigationClearance = 0});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;

  // Color Palette
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  late final RealtimeNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();

    _notificationService = RealtimeNotificationService();
    _notificationService.addListener(_onNotificationUpdate);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null && authProvider.user != null) {
      _notificationService.startListening(
        authProvider.user!.uid,
        authProvider.token,
      );
    }
  }

  void _onNotificationUpdate() {
    // When notifications update, refresh orders to reflect any changes
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      final future = _apiService.getMyOrdersCustomer(
        authProvider.token!,
        asWorker: false,
      );

      setState(() {
        _ordersFuture = future;
      });

      // Tunggu hingga data selesai diambil agar RefreshIndicator berhenti di waktu yang tepat
      await _ordersFuture;
    } else {
      // Fallback singkat agar indikator refresh tetap menutup dengan rapi
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: primaryColor,
          ),
        ),
        backgroundColor: white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerChatListPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: white,
                unselectedLabelColor: primaryColor,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Mendatang'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Riwayat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return ContentLoadingSkeleton(
              itemCount: 3,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                widget.bottomNavigationClearance +
                    MediaQuery.viewPaddingOf(context).bottom,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ApiService.readableError(
                      snapshot.error,
                      action: 'Gagal memuat pesanan',
                    ),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final allOrders = snapshot.data ?? [];

          final ongoingOrders =
              allOrders
                  .where(
                    (o) => shouldShowCustomerOrderInOngoing(
                      orderStatus: o.status,
                      refundStatus: o.refundStatus,
                    ),
                  )
                  .toList()
                ..sort(_sortByScheduleNewest);
          final historyOrders =
              allOrders
                  .where(
                    (o) => shouldShowCustomerOrderInHistory(
                      orderStatus: o.status,
                      refundStatus: o.refundStatus,
                    ),
                  )
                  .toList()
                ..sort(_sortByLastActivityNewest);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(ongoingOrders, isUpcoming: true),
              _buildOrderList(historyOrders, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }

  int _sortByScheduleNewest(Order a, Order b) {
    final scheduleCompare = b.jadwalPerbaikan.compareTo(a.jadwalPerbaikan);
    if (scheduleCompare != 0) return scheduleCompare;
    return b.dibuatPada.compareTo(a.dibuatPada);
  }

  int _sortByLastActivityNewest(Order a, Order b) {
    DateTime lastActivity(Order order) =>
        order.completedAt ?? order.updatedAt ?? order.dibuatPada;

    final activityCompare = lastActivity(b).compareTo(lastActivity(a));
    if (activityCompare != 0) return activityCompare;
    return b.jadwalPerbaikan.compareTo(a.jadwalPerbaikan);
  }

  Widget _buildOrderList(List<Order> orders, {required bool isUpcoming}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        color: primaryColor,
        backgroundColor: white,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // ✅ agar RefreshIndicator tetap bisa dipicu
          child: Container(
            height:
                MediaQuery.of(context).size.height * 0.7, // ✅ agar bisa scroll
            width: double.infinity,
            color: backgroundGray,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: lightGray.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isUpcoming ? Icons.schedule : Icons.history,
                              size: 48,
                              color: primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isUpcoming
                                ? 'Belum Ada Pesanan'
                                : 'Belum Ada Riwayat',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isUpcoming
                                ? 'Yuk, cari layanan dan buat pesanan pertamamu!'
                                : 'Riwayat pesananmu akan tampil di sini setelah selesai.',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: primaryColor,
      backgroundColor: white,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(), // ✅ agar bisa tarik refresh meskipun sedikit
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          widget.bottomNavigationClearance +
              MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(order: orders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  static const Color mutedColor = Color(0xFF6B7D87);

  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'awaiting_payment':
        return const Color(0xFFC0266D);
      case 'pending':
        return const Color(0xFFB76E00);
      case 'accepted':
      case 'quote_proposed':
      case 'quote_revision_requested':
        return const Color(0xFF2563EB);
      case 'quote_accepted':
        return const Color(0xFF16835D);
      case 'ready_to_start':
        return const Color(0xFF0F766E);
      case 'work_in_progress':
        return const Color(0xFF7C3AED);
      case 'completion_submitted':
        return const Color(0xFFB76E00);
      case 'refund:submitted':
      case 'refund:awaiting_worker_response':
      case 'refund:more_evidence_required':
      case 'refund:rework_offered':
        return const Color(0xFFB76E00);
      case 'refund:under_review':
      case 'refund:approved':
      case 'refund:awaiting_refund_destination':
      case 'refund:approved_manual':
      case 'refund:processing':
        return const Color(0xFF2563EB);
      case 'refund:rework_in_progress':
        return const Color(0xFF7C3AED);
      case 'warranty:under_review':
      case 'warranty:awaiting_worker_response':
      case 'warranty:more_evidence_required':
        return const Color(0xFFB76E00);
      case 'warranty:repair_scheduled':
      case 'warranty:customer_confirmation':
        return const Color(0xFF2563EB);
      case 'warranty:repair_in_progress':
        return const Color(0xFF7C3AED);
      case 'warranty:escalated':
        return const Color(0xFFB42318);
      case 'refund:refunded':
        return const Color(0xFF16835D);
      case 'refund:failed':
        return const Color(0xFFB42318);
      case 'completed':
      case 'quote_rejected':
        return const Color(0xFF16835D);
      case 'cancelled':
      case 'worker_acceptance_expired':
        return const Color(0xFFB42318);
      default:
        return mutedColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'awaiting_payment':
        return Icons.payments_rounded;
      case 'pending':
        return Icons.access_time_rounded;
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
      case 'warranty:under_review':
        return Icons.manage_search_rounded;
      case 'warranty:more_evidence_required':
        return Icons.add_photo_alternate_outlined;
      case 'warranty:awaiting_worker_response':
        return Icons.hourglass_top_rounded;
      case 'warranty:repair_scheduled':
        return Icons.event_available_outlined;
      case 'warranty:repair_in_progress':
        return Icons.home_repair_service_outlined;
      case 'warranty:customer_confirmation':
        return Icons.fact_check_outlined;
      case 'warranty:escalated':
        return Icons.gpp_maybe_outlined;
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
      case 'quote_rejected':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'worker_acceptance_expired':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'awaiting_payment':
        return 'Menunggu Pembayaran';
      case 'pending':
        return 'Menunggu Konfirmasi';
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
        return 'Perlu Konfirmasi Anda';
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
      case 'warranty:under_review':
        return 'Klaim Garansi Ditinjau';
      case 'warranty:more_evidence_required':
        return 'Lengkapi Bukti Garansi';
      case 'warranty:awaiting_worker_response':
        return 'Menunggu Tanggapan Worker';
      case 'warranty:repair_scheduled':
        return 'Perbaikan Garansi Dijadwalkan';
      case 'warranty:repair_in_progress':
        return 'Perbaikan Garansi Berjalan';
      case 'warranty:customer_confirmation':
        return 'Konfirmasi Perbaikan Garansi';
      case 'warranty:escalated':
        return 'Garansi Diperiksa Admin';
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
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'quote_rejected':
        return 'Survei Selesai • Penawaran Ditolak';
      case 'worker_acceptance_expired':
        return 'Worker Tidak Merespons';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Future<void> _showReviewDialog(BuildContext context, Order order) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();
    final submitted = await showOrderReviewSheet(
      context: context,
      serviceName: order.serviceName,
      workerName: order.workerName,
      onSubmit: (rating, comment) async {
        final token = auth.token;
        if (token == null) throw Exception('Sesi login telah berakhir.');
        try {
          await apiService.submitReview(
            token: token,
            orderId: order.id,
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
    if (submitted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim!')));
      final parentState = context
          .findAncestorStateOfType<_CustomerOrdersPageState>();
      await parentState?._loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canReview =
        order.status == 'completed' && (order.hasBeenReviewed == false);
    final baseDisplayStatus = effectiveCustomerOrderListStatus(
      orderStatus: order.status,
      refundStatus: order.refundStatus,
    );
    const activeWarrantyStatuses = {
      'under_review',
      'more_evidence_required',
      'awaiting_worker_response',
      'repair_scheduled',
      'repair_in_progress',
      'customer_confirmation',
      'escalated',
    };
    final displayStatus =
        !baseDisplayStatus.startsWith('refund:') &&
            activeWarrantyStatuses.contains(order.warrantyStatus)
        ? 'warranty:${order.warrantyStatus}'
        : baseDisplayStatus;
    final warrantyExpiry =
        order.warrantyExpiresAt ??
        order.completionConfirmedAt?.add(const Duration(days: 7)) ??
        order.completedAt?.add(const Duration(days: 7));
    final hasActiveWarranty =
        order.status == 'completed' &&
        warrantyExpiry != null &&
        warrantyExpiry.isAfter(DateTime.now());

    return OrderSummaryCard(
      order: order,
      status: OrderSummaryStatus(
        label: _statusText(displayStatus),
        color: _statusColor(displayStatus),
        icon: _statusIcon(displayStatus),
      ),
      onTap: () => _openOrderDetail(context),
      action: canReview
          ? OrderSummaryAction(
              label: 'Beri Ulasan',
              icon: Icons.star_outline_rounded,
              onPressed: () => _showReviewDialog(context, order),
              foregroundColor: const Color(0xFF9A6700),
              backgroundColor: const Color(0xFFFFF5D9),
            )
          : null,
      supportingLabel: hasActiveWarranty
          ? 'Garansi aktif • ${_warrantyRemaining(warrantyExpiry)}'
          : null,
    );
  }

  Future<void> _openOrderDetail(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerOrderDetailPage(initialOrder: order),
      ),
    );
    if (!context.mounted) return;
    // Listener Firestore dapat ditolak oleh rules. Selalu ambil ulang daftar
    // dari API agar order completed berpindah dari aktif ke riwayat.
    await context
        .findAncestorStateOfType<_CustomerOrdersPageState>()
        ?._loadOrders();
  }

  String _warrantyRemaining(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'berakhir';
    if (remaining.inDays > 0) return '${remaining.inDays} hari';
    return '${remaining.inHours} jam';
  }
}
