import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/costumer_flow/orders/pages/customer_order_detail_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/state/auth_provider.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      // ✅ Tunggu dulu hasil Future-nya
      final future = _apiService.getMyOrdersCustomer(
        authProvider.token!,
        asWorker: false,
      );

      // ✅ Baru assign ke state
      setState(() {
        _ordersFuture = future;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerChatListPage(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Mendatang'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allOrders = snapshot.data ?? [];

            final ongoingOrders = allOrders
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
                  ].contains(o.status),
                )
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(ongoingOrders, isUpcoming: true),
                _buildOrderList(historyOrders, isUpcoming: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required bool isUpcoming}) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        color: Colors.white, // Tambahkan agar tidak terlihat transparan
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/empty.png', // Bisa juga pakai icon bawaan
                  // height: 120,
                  // color: Colors.deepPurple.withOpacity(0.4),
                ),
                const SizedBox(height: 20),
                //   Text(
                //     isUpcoming ? 'Belum ada jadwal pesanan' : 'Belum ada riwayat',
                //     style: const TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.black87,
                //     ),
                //   ),
                //   const SizedBox(height: 8),
                //   Text(
                //     isUpcoming
                //         ? 'Yuk, cari layanan dan buat pesanan!'
                //         : 'Riwayat pesananmu akan tampil di sini.',
                //     style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                //     textAlign: TextAlign.center,
                //   ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: orders[index]);
      },
    );
  }
}

// Widget terpisah untuk kartu pesanan customer
// Lanjutkan dari kode kamu sebelumnya, hanya bagian _OrderCard yang diperbarui:
class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'quote_proposed':
      case 'work_in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'quote_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'quote_proposed':
        return Icons.request_quote;
      case 'work_in_progress':
        return Icons.build_circle_outlined;
      case 'completed':
        return Icons.verified;
      case 'cancelled':
      case 'quote_rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Disetujui';
      case 'quote_proposed':
        return 'Penawaran Diajukan';
      case 'work_in_progress':
        return 'Dalam Pengerjaan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'quote_rejected':
        return 'Penawaran Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canReview = order.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header status
          Container(
            decoration: BoxDecoration(
              color: _statusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _statusIcon(order.status),
                  color: _statusColor(order.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusText(order.status),
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                    'id_ID',
                  ).format(order.jadwalPerbaikan),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.serviceName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kategori: ${order.category}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'EEEE, d MMM yyyy • HH:mm',
                        'id_ID',
                      ).format(order.jadwalPerbaikan),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tombol aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canReview)
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigasi ke beri ulasan
                        },
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Beri Ulasan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade50,
                          foregroundColor: Colors.amber.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (canReview) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerOrderDetailPage(order: order),
                          ),
                        );
                        // TODO: Navigasi ke detail pesanan
                      },
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Lihat Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
