import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/snapPayment_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/order_model.dart';

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

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
      case 'quote_proposed':
        return const Color(0xFF2196F3);
      case 'quote_accepted':
        return const Color(0xFF4CAF50);
      case 'work_in_progress':
        return const Color(0xFF9C27B0);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'quote_rejected':
        return const Color(0xFFF44336);
      default:
        return CustomerOrderDetailPage.lightGray;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'quote_proposed':
        return Icons.request_quote_rounded;
      case 'quote_accepted':
        return Icons.payment_rounded;
      case 'work_in_progress':
        return Icons.build_circle_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'quote_rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
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
      case 'quote_accepted':
        return 'Siap Bayar';
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

  Future<void> _handlePayment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);
    try {
      final paymentData = await _apiService.startPaymentForQuote(
        token: auth.token!,
        orderId: _order.id,
      );
      final snapToken = paymentData['snapToken'];
      final snapRedirectUrl =
          "https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken";

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
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Chat'),
                ),
              ],
            )
          : const Text('Belum ada worker yang ditugaskan.'),
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

  Widget _buildActionButtons() {
    if (_order.status == 'quote_proposed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => _respondToQuote('accept'),
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
            onPressed: () => _respondToQuote('reject'),
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
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Bayar Sekarang'),
        ),
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
