import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/order_model.dart';

class CustomerOrderDetailPage extends StatelessWidget {
  final Order order;

  const CustomerOrderDetailPage({super.key, required this.order});

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

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        order.jadwalPerbaikan.hour == 0 && order.jadwalPerbaikan.minute == 0;
    final formattedDate = isMidnight
        ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(order.jadwalPerbaikan)
        : DateFormat(
            'EEEE, d MMM yyyy • HH:mm',
            'id_ID',
          ).format(order.jadwalPerbaikan);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 Status
            Container(
              decoration: BoxDecoration(
                color: _statusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _statusIcon(order.status),
                    color: _statusColor(order.status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _statusColor(order.status),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'd MMM yyyy',
                      'id_ID',
                    ).format(order.jadwalPerbaikan),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🧰 Layanan
            Text(
              order.serviceName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Kategori: ${order.category}',
              style: const TextStyle(color: Colors.grey),
            ),

            const Divider(height: 32),

            // 🗓 Jadwal
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            // 📍 Lokasi
            if (order.lokasi != null && order.lokasi!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.lokasi!)),
                ],
              ),

            const SizedBox(height: 24),

            // 🧾 Deskripsi
            const Text(
              'Deskripsi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              order.workerDescription ?? '-',
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 24),

            // 👤 Worker Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dikerjakan oleh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (order.workerName != null && order.workerName!.isNotEmpty)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            (order.workerAvatar != null &&
                                order.workerAvatar!.isNotEmpty)
                            ? NetworkImage(order.workerAvatar!)
                            : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.workerName!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final apiService = ApiService();

                          try {
                            final chatId = await apiService.createChat(
                              token: auth.token!,
                              recipientId: order.workerId!,
                            );

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  chatId: chatId,
                                  name: order.workerName ?? '',
                                  avatarUrl: order.workerAvatar ?? '',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal membuka chat: $e'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Chat'),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Belum ada worker yang ditugaskan.',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // 🧾 Tombol aksi
            if (order.status == 'completed')
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigasi ke beri ulasan
                },
                icon: const Icon(Icons.reviews),
                label: const Text('Beri Ulasan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            if (order.status == 'pending')
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Batalkan pesanan
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Batalkan Pesanan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
