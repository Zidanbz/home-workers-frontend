import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/state/auth_provider.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Order> _orderFuture;
  bool _isProcessing = false; // State untuk loading pada tombol aksi

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _orderFuture = _apiService.getOrderById(
          token: authProvider.token!,
          orderId: widget.orderId,
        );
      });
    }
  }

  // --- FUNGSI BARU UNTUK MENERIMA PESANAN ---
  Future<void> _handleAcceptOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Authentication failed.');

      await _apiService.acceptOrder(token: token, orderId: widget.orderId);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Pesanan berhasil diterima.'),
        ),
      );

      // Refresh halaman untuk menampilkan status baru
      _loadOrderDetails();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal menerima pesanan: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Detail pesanan tidak ditemukan.'));
          }

          final order = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadOrderDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('Informasi Customer'),
                _buildInfoCard(
                  children: [
                    _buildInfoRow(Icons.person_outline, order.customerName),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      order.customerAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Detail Layanan'),
                _buildInfoCard(
                  children: [
                    _buildInfoRow(Icons.work_outline, order.serviceName),
                    _buildInfoRow(Icons.schedule, order.formattedSchedule),
                    _buildInfoRow(
                      Icons.receipt_long_outlined,
                      'Status: ${order.status}',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // --- PERUBAHAN UTAMA: Tampilkan tombol aksi berdasarkan status ---
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildActionButtons(order),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BARU UNTUK TOMBOL AKSI ---
  Widget _buildActionButtons(Order order) {
    // Tampilkan tombol hanya jika statusnya 'pending'
    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implementasi logika tolak pesanan
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Terima Pesanan'),
            ),
          ),
        ],
      );
    }
    // TODO: Tambahkan tombol lain untuk status yang berbeda,
    // misalnya tombol "Ajukan Penawaran" jika status 'accepted' dan tipe 'survey'.

    // Jika status bukan 'pending', tidak ada tombol aksi yang ditampilkan.
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
