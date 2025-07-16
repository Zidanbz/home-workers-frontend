import 'package:intl/intl.dart';

class Order {
  final String id;
  final String status;
  final DateTime jadwalPerbaikan;
  final DateTime dibuatPada;
  final String customerId;
  final String category;
  final String serviceName;
  final String customerName;
  final String customerAddress;
  final String serviceType;
final bool hasBeenReviewed;
  final String? lokasi;
  final String? workerDescription;
  final String? workerName;
  final String? workerId;
  final String? workerAvatar;
  final num? quotedPrice;

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
    required this.serviceType,
    this.lokasi,
    this.workerDescription,
    this.workerName,
    this.workerId,
    this.workerAvatar,
    this.quotedPrice,
    required this.hasBeenReviewed,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parseFirestoreTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Map && timestamp['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      }
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
      serviceType: json['tipeLayanan'] ?? '',
      lokasi: json['lokasi'] ?? '',
      workerDescription: json['workerDescription'] ?? '',
      workerName: json['workerName'] ?? '',
      workerId: json['workerId'] ?? '',
      workerAvatar: json['workerAvatar'] ?? '',
      quotedPrice: json['quotedPrice'] != null
          ? num.tryParse(json['quotedPrice'].toString())
          : null,
          hasBeenReviewed: json['hasBeenReviewed'] ?? false,
    );
  }

  String get formattedSchedule {
    return DateFormat('EEEE, dd MMM, HH:mm', 'id_ID').format(jadwalPerbaikan);
  }

  String get timeAgo {
    final difference = DateTime.now().difference(dibuatPada);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
