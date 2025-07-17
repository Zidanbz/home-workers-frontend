import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final String? workerDescription;
  final String? workerName;
  final String? workerId;
  final String? workerAvatar;
  final num? quotedPrice;
  final LatLng? coordinates; // Koordinat untuk peta

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
    this.workerDescription,
    this.workerName,
    this.workerId,
    this.workerAvatar,
    this.quotedPrice,
    required this.hasBeenReviewed,
    this.coordinates,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing Timestamp
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

    // Helper untuk parsing harga
    num? parsePrice(dynamic price) {
      if (price == null) return null;
      return num.tryParse(price.toString());
    }

    // Helper untuk parsing koordinat dari String
    LatLng? parseCoordinates(dynamic locationData) {
      // BARU: Prioritaskan parsing format Objek/Map dari GeoPoint
      if (locationData is Map &&
          locationData['_latitude'] != null &&
          locationData['_longitude'] != null) {
        try {
          return LatLng(locationData['_latitude'], locationData['_longitude']);
        } catch (e) {
          print('Gagal parsing koordinat dari GeoPoint Map: $e');
          return null;
        }
      }

      // LAMA: Tetap simpan parsing String untuk jaga-jaga jika ada data lama
      if (locationData is String) {
        try {
          final cleanedString = locationData
              .replaceAll(RegExp(r'[\[\]°]'), '')
              .trim();
          final parts = cleanedString.split(',');

          if (parts.length == 2) {
            final latString = parts[0].trim();
            double latitude = double.parse(latString.split(' ')[0]);
            if (latString.contains('S')) {
              latitude = -latitude;
            }

            final lonString = parts[1].trim();
            double longitude = double.parse(lonString.split(' ')[0]);
            if (lonString.contains('W')) {
              longitude = -longitude;
            }
            return LatLng(latitude, longitude);
          }
        } catch (e) {
          print('Gagal parsing koordinat dari String: $e');
          return null;
        }
      }

      // Jika format tidak dikenali, kembalikan null
      return null;
    }

    return Order(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      serviceName: json['serviceName'] ?? 'Layanan Tidak Diketahui',
      customerName: json['customerName'] ?? 'Customer Tidak Dikenal',
      customerAddress: json['customerAddress'] ?? 'Alamat Tidak Tersedia',
      category: json['category'] ?? 'lainnya',
      serviceType: json['serviceType'] ?? 'lainnya',
      quotedPrice: parsePrice(json['harga'] ?? json['serviceHarga']),
      customerId: json['customerId'] ?? '',
      workerId: json['workerId'],
      workerName: json['workerName'],
      workerDescription: json['workerDescription'],
      hasBeenReviewed: json['hasBeenReviewed'] ?? false,
      workerAvatar: json['workerAvatar'],
      jadwalPerbaikan: parseFirestoreTimestamp(json['jadwalPerbaikan']),
      dibuatPada: parseFirestoreTimestamp(json['dibuatPada']),
      coordinates: parseCoordinates(
        json['location'],
      ), // Ambil dari field 'location'
    );
  }

  // Getter methods
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
