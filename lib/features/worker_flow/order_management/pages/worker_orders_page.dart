// Tetap sama: import
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Antrean'),
            Tab(text: 'History'),
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
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada pesanan.'));
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
                  ].contains(o.status),
                )
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(queuedOrders),
                _buildOrderList(historyOrders),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Text('Tidak ada pesanan di kategori ini.'),
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
        return _OrderCard(order: orders[index], onRefresh: _loadOrders);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onRefresh;

  const _OrderCard({required this.order, required this.onRefresh});

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
            await apiService.sendQuote(
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
                    child: Text(
                      order.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
