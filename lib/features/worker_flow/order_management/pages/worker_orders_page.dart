import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../chat/pages/chat_detail_page.dart';
import 'order_detail_page.dart';

class WorkerOrdersPage extends StatefulWidget {
  const WorkerOrdersPage({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _loadOrders() {
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
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
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
        onRefresh: _loadOrders,
        color: const Color(0xFF1A374D),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final allOrders = snapshot.data!;
            final queuedOrders = allOrders
                .where(
                  (o) => [
                    'pending',
                    'accepted',
                    'quote_proposed',
                    'work_in_progress',
                  ].contains(o.status),
                )
                .toList();
            final historyOrders = allOrders
                .where(
                  (o) => [
                    'completed',
                    'cancelled',
                    'quote_rejected',
                    'rejected',
                  ].contains(o.status),
                )
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(queuedOrders, 'queue'),
                _buildOrderList(historyOrders, 'history'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A374D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A374D)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Memuat pesanan...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A374D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1A374D).withOpacity(0.1),
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
    );
  }

  Widget _buildOrderList(List<Order> orders, String type) {
    if (orders.isEmpty) {
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
                        color: const Color(0xFFD9D9D9).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        type == 'queue' ? Icons.schedule : Icons.history,
                        size: 48,
                        color: const Color(0xFF1A374D).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'queue'
                          ? 'Tidak ada pesanan dalam antrean'
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
      padding: const EdgeInsets.all(20),
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
                child: _OrderCard(order: orders[index], onRefresh: _loadOrders),
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
  final VoidCallback onRefresh;

  const _OrderCard({Key? key, required this.order, required this.onRefresh})
    : super(key: key);

  void _handleAction(BuildContext context) async {
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
        case 'work_in_progress':
          final chatId = await apiService.createChat(
            token: token,
            recipientId: order.customerId,
          );
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: chatId,
                name: order.customerName,
                avatarUrl: '', // TODO: Tambahkan avatar customer jika tersedia
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
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }

    onRefresh(); // Refresh setelah aksi
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    String buttonText;
    VoidCallback? onPressed = () => _handleAction(context);

    switch (order.status) {
      case 'pending':
        buttonColor = Colors.orange.shade100;
        buttonText = 'Terima';
        break;
      case 'accepted':
      case 'work_in_progress':
        buttonColor = Colors.blue.shade100;
        buttonText = 'Tanya';
        break;
      case 'quote_proposed':
        buttonColor = Colors.indigo.shade100;
        buttonText = 'Ajukan Harga';
        break;
      case 'completed':
        buttonColor = Colors.green.shade100;
        buttonText = 'Selesai';
        onPressed = null;
        break;
      case 'cancelled':
      case 'quote_rejected':
        buttonColor = Colors.red.shade100;
        buttonText = 'Dibatalkan';
        onPressed = null;
        break;
      default:
        buttonColor = Colors.grey.shade300;
        buttonText = 'Status';
        onPressed = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A374D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.serviceType == 'fixed'
                              ? 'Tipe Layanan: Fixed'
                              : 'Tipe Layanan: Survey',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(buttonText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customerAddress,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                order.formattedSchedule,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    order.timeAgo,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
