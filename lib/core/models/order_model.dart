import 'package:home_workers_fe/core/models/category_model.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
  final String status;
  final DateTime jadwalPerbaikan;
  final DateTime dibuatPada;
  final String customerId;
  final String category;

  // Informasi tambahan yang kita dapat dari backend
  final String serviceName;
  final String customerName;
  final String customerAddress;

  Order({
    required this.id,
    required this.status,
    required this.jadwalPerbaikan,
    required this.dibuatPada,
    required this.serviceName,
    required this.customerName,
    required this.customerAddress,
    required this.customerId,
    required this.category,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing tanggal dari format Firestore dengan aman
    DateTime parseFirestoreTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      // Cek jika formatnya adalah Map dari Firestore
      if (timestamp is Map && timestamp['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      }
      // Fallback jika formatnya adalah String ISO
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final serviceInfo = json['serviceInfo'] as Map<String, dynamic>? ?? {};
    final customerInfo = json['customerInfo'] as Map<String, dynamic>? ?? {};

    return Order(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      jadwalPerbaikan: parseFirestoreTimestamp(json['jadwalPerbaikan']),
      dibuatPada: parseFirestoreTimestamp(json['dibuatPada']),
      serviceName: serviceInfo['namaLayanan'] ?? 'Layanan Tidak Diketahui',
      customerName: customerInfo['nama'] ?? 'Customer Tidak Dikenal',
      customerAddress: customerInfo['alamat'] ?? 'Alamat Tidak Tersedia',
      customerId: json['customerId'] ?? '',
      category: json['category'] ?? '',
    );
  }

  // Helper untuk format jadwal ke Bahasa Indonesia
  String get formattedSchedule {
    return DateFormat('EEEE, dd MMM, HH:mm', 'id_ID').format(jadwalPerbaikan);
  }

  // Helper untuk format waktu lalu
  String get timeAgo {
    final difference = DateTime.now().difference(dibuatPada);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
