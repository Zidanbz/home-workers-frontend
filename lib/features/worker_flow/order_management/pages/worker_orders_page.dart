import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../shared_widgets/order_summary_card.dart';
import '../../../../shared_widgets/content_loading_skeleton.dart';
import '../../../chat/pages/chat_detail_page.dart';
import 'order_detail_page.dart';

class WorkerOrdersPage extends StatefulWidget {
  final double bottomNavigationClearance;

  const WorkerOrdersPage({super.key, this.bottomNavigationClearance = 0});

  @override
  State<WorkerOrdersPage> createState() => _WorkerOrdersPageState();
}

class _WorkerOrdersPageState extends State<WorkerOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadOrders();
    _animationController.forward();
  }

  /// Memuat ulang daftar pesanan dari API dan memperbarui FutureBuilder.
  Future<List<Order>> _loadOrders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      final future = _apiService.getMyOrders(authProvider.token!);
      setState(() {
        _ordersFuture = future;
      });
      return future;
    }
    return Future.error('Anda tidak terautentikasi.');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTabBarView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A374D),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A374D), Color(0xFF2A4A5D)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan Saya',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kelola semua pesanan Anda',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A374D),
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: const Color(0xFF1A374D),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: _tabController.index == 0
                              ? const Color(0xFF1A374D)
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        const Text('Antrean'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 20,
                          color: _tabController.index == 1
                              ? const Color(0xFF1A374D)
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        const Text('Riwayat'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: _tabController.index == 2
                              ? const Color(0xFF1A374D)
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        const Text('Garansi'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: RefreshIndicator(
        // Tarik ke bawah untuk refresh
        onRefresh: () async {
          await _loadOrders();
        },
        color: const Color(0xFF1A374D),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(
                ApiService.readableError(
                  snapshot.error,
                  action: 'Gagal memuat pesanan',
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Pastikan tetap bisa tarik untuk refresh
              return _buildEmptyState();
            }

            final allOrders = snapshot.data!;
            final validOrders = allOrders
                .where((o) => o.status != 'awaiting_payment')
                .toList();

            final queuedOrders = validOrders.where((o) {
              return [
                'pending',
                'accepted',
                'quote_proposed',
                'quote_accepted',
                'ready_to_start',
                'work_in_progress',
                'completion_submitted',
              ].contains(o.status);
            }).toList();

            final historyOrders = validOrders.where((o) {
              return [
                'completed',
                'cancelled',
                'quote_rejected',
                'rejected',
                'worker_acceptance_expired',
              ].contains(o.status);
            }).toList();

            const activeWarrantyStatuses = {
              'under_review',
              'more_evidence_required',
              'awaiting_worker_response',
              'repair_scheduled',
              'repair_in_progress',
              'customer_confirmation',
              'escalated',
            };
            final warrantyOrders = validOrders
                .where((o) => activeWarrantyStatuses.contains(o.warrantyStatus))
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(queuedOrders, 'queue'),
                _buildOrderList(historyOrders, 'history'),
                _buildOrderList(warrantyOrders, 'warranty'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ContentLoadingSkeleton(
      itemCount: 3,
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        widget.bottomNavigationClearance +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops! Terjadi kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A374D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A374D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A374D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Color(0xFF1A374D),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Belum Ada Pesanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A374D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pesanan akan muncul di sini ketika ada pelanggan yang memesan layanan Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(List<Order> orders, String type) {
    if (orders.isEmpty) {
      // state kosong per-tab
      return LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        type == 'queue'
                            ? Icons.schedule
                            : type == 'warranty'
                            ? Icons.verified_user_outlined
                            : Icons.history,
                        size: 48,
                        color: const Color(0xFF1A374D).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'queue'
                          ? 'Tidak ada pesanan dalam antrean'
                          : type == 'warranty'
                          ? 'Tidak ada klaim garansi aktif'
                          : 'Belum ada riwayat pesanan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A374D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type == 'queue'
                          ? 'Pesanan baru akan muncul di sini'
                          : type == 'warranty'
                          ? 'Klaim yang membutuhkan tindakan akan muncul di sini'
                          : 'Riwayat pesanan yang selesai akan muncul di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        widget.bottomNavigationClearance +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _OrderCard(
                  order: orders[index],
                  onRefresh: () async {
                    await _loadOrders();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final Future<void> Function()? onRefresh;

  const _OrderCard({required this.order, this.onRefresh});

  bool _isCompletedStatus() {
    return order.status == 'completed' || order.status == 'done';
  }

  bool _isChatWindowOpen() {
    if (!_isCompletedStatus()) return false;
    final completedAt = order.completedAt;
    if (completedAt == null) return true;
    return DateTime.now().difference(completedAt) <= const Duration(days: 7);
  }

  Future<void> _handleAction(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    if (authProvider.token == null) return;
    final token = authProvider.token!;

    try {
      switch (order.status) {
        case 'pending':
          await apiService.acceptOrder(token: token, orderId: order.id);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Pesanan diterima.'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case 'accepted':
        case 'ready_to_start':
        case 'work_in_progress':
        case 'completion_submitted':
          final chatId = await apiService.createChat(
            token: token,
            recipientId: order.customerId,
          );
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: chatId,
                name: order.customerName,
                avatarUrl: '', // TODO: avatar customer jika ada
              ),
            ),
          );
          break;
        case 'completed':
        case 'done':
          if (!_isChatWindowOpen()) return;
          final completedChatId = await apiService.createChat(
            token: token,
            recipientId: order.customerId,
          );
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: completedChatId,
                name: order.customerName,
                avatarUrl: '',
              ),
            ),
          );
          break;

        case 'quote_proposed':
          final nominal = await showDialog<num>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Ajukan Harga'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Masukkan harga penawaran',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final value = num.tryParse(controller.text);
                      if (value != null) {
                        Navigator.pop(context, value);
                      }
                    },
                    child: const Text('Kirim'),
                  ),
                ],
              );
            },
          );

          if (nominal != null) {
            await apiService.proposeQuote(
              token: token,
              orderId: order.id,
              proposedPrice: nominal,
            );
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Penawaran dikirim.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        default:
          return;
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(e, action: 'Gagal memproses aksi pesanan'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Refresh daftar setelah aksi.
    if (onRefresh != null) await onRefresh!.call();
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    Color buttonForeground;
    String buttonText;
    IconData buttonIcon;
    VoidCallback? onPressed = () => _handleAction(context);
    const activeWarrantyStatuses = {
      'under_review',
      'more_evidence_required',
      'awaiting_worker_response',
      'repair_scheduled',
      'repair_in_progress',
      'customer_confirmation',
      'escalated',
    };
    final hasActiveWarranty = activeWarrantyStatuses.contains(
      order.warrantyStatus,
    );

    switch (order.status) {
      case 'pending':
        buttonColor = Colors.orange.shade100;
        buttonForeground = const Color(0xFF9A5B00);
        buttonText = 'Terima';
        buttonIcon = Icons.check_circle_outline_rounded;
        break;
      case 'accepted':
      case 'ready_to_start':
      case 'work_in_progress':
      case 'completion_submitted':
        buttonColor = Colors.blue.shade100;
        buttonForeground = const Color(0xFF175CD3);
        buttonText = order.status == 'completion_submitted'
            ? 'Chat Customer'
            : 'Tanya';
        buttonIcon = Icons.chat_bubble_outline_rounded;
        break;
      case 'quote_proposed':
        buttonColor = Colors.indigo.shade100;
        buttonForeground = const Color(0xFF4338CA);
        buttonText = 'Ajukan Harga';
        buttonIcon = Icons.request_quote_outlined;
        break;
      case 'completed':
      case 'done':
        final canChat = _isChatWindowOpen();
        if (canChat) {
          buttonColor = Colors.blue.shade100;
          buttonForeground = const Color(0xFF175CD3);
          buttonText = 'Chat';
          buttonIcon = Icons.chat_bubble_outline_rounded;
        } else {
          buttonColor = Colors.green.shade100;
          buttonForeground = const Color(0xFF16835D);
          buttonText = 'Selesai';
          buttonIcon = Icons.verified_rounded;
          onPressed = null;
        }
        break;
      case 'cancelled':
      case 'quote_rejected':
      case 'worker_acceptance_expired':
        buttonColor = Colors.red.shade100;
        buttonForeground = const Color(0xFFB42318);
        buttonText = order.status == 'worker_acceptance_expired'
            ? 'Waktu Habis'
            : 'Dibatalkan';
        buttonIcon = Icons.cancel_outlined;
        onPressed = null;
        break;
      default:
        buttonColor = Colors.grey.shade300;
        buttonForeground = const Color(0xFF6B7D87);
        buttonText = 'Status';
        buttonIcon = Icons.info_outline_rounded;
        onPressed = null;
    }

    if (hasActiveWarranty) {
      buttonColor = const Color(0xFFE8F7EF);
      buttonForeground = const Color(0xFF16835D);
      buttonText = 'Tindak Lanjut';
      buttonIcon = Icons.verified_user_outlined;
      onPressed = () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
        );
        if (onRefresh != null) await onRefresh!.call();
      };
    }

    final displayStatus = hasActiveWarranty
        ? 'warranty:${order.warrantyStatus}'
        : order.status;

    return OrderSummaryCard(
      order: order,
      status: OrderSummaryStatus(
        label: _statusLabel(displayStatus),
        color: _statusColor(displayStatus),
        icon: _statusIcon(displayStatus),
      ),
      onTap: () => _openOrderDetail(context),
      action: OrderSummaryAction(
        label: buttonText,
        icon: buttonIcon,
        onPressed: onPressed,
        foregroundColor: buttonForeground,
        backgroundColor: buttonColor,
      ),
      supportingLabel: hasActiveWarranty
          ? _warrantyLabel(order.warrantyStatus!)
          : 'Customer • ${order.customerName}',
      supportingIcon: hasActiveWarranty
          ? Icons.verified_user_outlined
          : Icons.person_outline_rounded,
      supportingColor: hasActiveWarranty
          ? const Color(0xFF16835D)
          : const Color(0xFF2B6478),
    );
  }

  Future<void> _openOrderDetail(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
    );
    if (changed == true || changed == null) {
      if (onRefresh != null) await onRefresh!.call();
    }
  }

  Color _statusColor(String status) {
    if (status.startsWith('warranty:')) {
      return status == 'warranty:escalated'
          ? const Color(0xFFB42318)
          : const Color(0xFF16835D);
    }
    switch (status) {
      case 'pending':
      case 'completion_submitted':
        return const Color(0xFFB76E00);
      case 'accepted':
      case 'quote_proposed':
      case 'quote_accepted':
        return const Color(0xFF2563EB);
      case 'ready_to_start':
        return const Color(0xFF0F766E);
      case 'work_in_progress':
        return const Color(0xFF7C3AED);
      case 'completed':
      case 'done':
        return const Color(0xFF16835D);
      case 'cancelled':
      case 'quote_rejected':
      case 'rejected':
      case 'worker_acceptance_expired':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF6B7D87);
    }
  }

  IconData _statusIcon(String status) {
    if (status.startsWith('warranty:')) {
      return Icons.verified_user_outlined;
    }
    switch (status) {
      case 'pending':
        return Icons.notifications_active_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'quote_proposed':
      case 'quote_accepted':
        return Icons.request_quote_outlined;
      case 'ready_to_start':
        return Icons.play_circle_outline_rounded;
      case 'work_in_progress':
        return Icons.handyman_outlined;
      case 'completion_submitted':
        return Icons.fact_check_outlined;
      case 'completed':
      case 'done':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'quote_rejected':
      case 'rejected':
      case 'worker_acceptance_expired':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    if (status.startsWith('warranty:')) {
      return _warrantyLabel(status.substring('warranty:'.length));
    }
    const labels = {
      'pending': 'Pesanan Baru',
      'accepted': 'Diterima',
      'quote_proposed': 'Menunggu Penawaran',
      'quote_accepted': 'Penawaran Disetujui',
      'ready_to_start': 'Siap Dimulai',
      'work_in_progress': 'Dalam Pengerjaan',
      'completion_submitted': 'Menunggu Konfirmasi',
      'completed': 'Selesai',
      'done': 'Selesai',
      'cancelled': 'Dibatalkan',
      'quote_rejected': 'Penawaran Ditolak',
      'rejected': 'Ditolak',
      'worker_acceptance_expired': 'Waktu Respons Habis',
    };
    return labels[status] ?? 'Status Pesanan';
  }

  String _warrantyLabel(String status) {
    const labels = {
      'under_review': 'Garansi ditinjau Admin',
      'more_evidence_required': 'Perlu bukti tambahan',
      'awaiting_worker_response': 'Perlu tanggapan Anda',
      'repair_scheduled': 'Perbaikan dijadwalkan',
      'repair_in_progress': 'Perbaikan berlangsung',
      'customer_confirmation': 'Menunggu Customer',
      'escalated': 'Diperiksa Admin',
    };
    return labels[status] ?? 'Klaim garansi';
  }
}
