import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  bool _isProcessing = false;
  GoogleMapController? _mapController;

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

  Future<void> _handleRejectOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menolak pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final token = authProvider.token!;
        await _apiService.rejectOrder(token: token, orderId: widget.orderId);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Pesanan berhasil ditolak.'),
          ),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Gagal menolak pesanan: ${e.toString().replaceAll("Exception: ", "")}',
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleAcceptOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isProcessing = true);

    try {
      final token = authProvider.token!;
      await _apiService.acceptOrder(token: token, orderId: widget.orderId);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Pesanan berhasil diterima.'),
        ),
      );
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSendQuote(Order order) async {
    final TextEditingController priceController = TextEditingController();

    final result = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajukan Penawaran'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Harga yang ditawarkan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = num.tryParse(priceController.text);
              if (price != null) {
                Navigator.pop(context, price);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token!;
        await _apiService.proposeQuote(
          token: token,
          orderId: order.id,
          proposedPrice: result,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Penawaran berhasil dikirim.'),
          ),
        );
        _loadOrderDetails(); // Refresh
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal mengirim penawaran: $e'),
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  /// Generic status updater with snackbars & refresh
  Future<void> _handleUpdateStatus(String orderId, String newStatus) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    setState(() => _isProcessing = true);

    try {
      await _apiService.updateOrderStatus(
        token: token,
        orderId: orderId,
        newStatus: newStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Status berhasil diperbarui.'),
        ),
      );
      _loadOrderDetails();
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal memperbarui status: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Pop-up konfirmasi untuk menyelesaikan pekerjaan (umum, dipakai fixed & lainnya)
  Future<void> _confirmAndCompleteOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: const Text('Apakah pekerjaan sudah benar-benar selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleUpdateStatus(orderId, 'completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A374D),
        iconTheme: const IconThemeData(
          color:
              Colors.white, // <-- TAMBAHKAN INI UNTUK MEMBUAT PANAH JADI PUTIH
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
          debugPrint('Status: ${order.status}');
          debugPrint('ServiceType: ${order.serviceType}');

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
                _buildMapView(order),
                const SizedBox(height: 24),
                _buildSectionTitle('Detail Layanan'),
                _buildInfoCard(
                  children: [
                    _buildInfoRow(Icons.work_outline, order.serviceName),
                    _buildInfoRow(Icons.schedule, order.formattedSchedule),
                    _buildInfoRow(
                      Icons.receipt_long_outlined,
                      'Status: ${_getFormattedStatus(order.status)}',
                    ),
                    _buildInfoRow(
                      Icons.category_outlined,
                      'Tipe: ${order.serviceType}',
                    ),
                    if (order.status == 'quote_proposed')
                      _buildInfoRow(
                        Icons.monetization_on_outlined,
                        'Penawaran: Rp ${order.quotedPrice}',
                      ),
                  ],
                ),
                const SizedBox(height: 40),
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

  Widget _buildMapView(Order order) {
    if (order.coordinates == null) {
      return const SizedBox.shrink();
    }

    final LatLng position = order.coordinates!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionTitle('Lokasi Pengerjaan'),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 16.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('orderLocation'),
                  position: position,
                  infoWindow: InfoWindow(
                    title: order.customerName,
                    snippet: order.customerAddress,
                  ),
                ),
              },
              zoomControlsEnabled: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Order order) {
    // 1. STATUS: pending => tampilkan Tolak / Terima
    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleRejectOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A374D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Terima Pesanan'),
            ),
          ),
        ],
      );
    }

    // 2. SURVEY: accepted || quote_proposed => Ajukan / Ubah Penawaran
    if ((order.status == 'accepted' || order.status == 'quote_proposed') &&
        order.serviceType == 'survey') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.attach_money),
        label: Text(
          order.status == 'quote_proposed'
              ? 'Ubah Penawaran'
              : 'Ajukan Penawaran',
        ),
        onPressed: () => _handleSendQuote(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 3. FIXED: accepted => langsung tampilkan tombol Selesaikan Pekerjaan (dengan konfirmasi)
    //    (Jika kamu ingin ada status "work_in_progress" di alur fixed, ubah logika ini)
    if (order.serviceType == 'fixed' && order.status == 'accepted') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('Selesaikan Pekerjaan'),
        onPressed: () => _confirmAndCompleteOrder(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 4. SURVEY: quote_accepted => bisa Mulai Pengerjaan
    if (order.status == 'quote_accepted') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Mulai Pengerjaan'),
        onPressed: () => _handleUpdateStatus(order.id, 'work_in_progress'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 5. work_in_progress => tombol Selesaikan Pekerjaan (umum)
    if (order.status == 'work_in_progress') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.check_circle),
        label: const Text('Selesaikan Pekerjaan'),
        onPressed: () => _confirmAndCompleteOrder(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A374D),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
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
          Icon(icon, color: const Color(0xFF1A374D), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _getFormattedStatus(String status) {
    switch (status) {
      case 'quote_proposed':
        return 'Penawaran diajukan';
      case 'quote_rejected':
        return 'Penawaran ditolak';
      case 'quote_accepted':
        return 'Penawaran diterima';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Diterima';
      case 'work_in_progress':
        return 'Sedang Dikerjakan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }
}
