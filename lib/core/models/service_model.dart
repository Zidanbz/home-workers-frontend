import 'package:home_workers_fe/core/models/availability_model.dart';
import 'package:intl/intl.dart';

class Service {
  final String id;
  final String namaLayanan;
  final String category;
  final int harga;
  final String fotoUtamaUrl;
  final String statusPersetujuan;
  final DateTime dibuatPada;
  final List<dynamic> photoUrls; // Galeri foto
  final List<dynamic> metodePembayaran; // Metode pembayaran
  final String deskripsiLayanan;
  final String? tipeLayanan;
  final num? biayaSurvei;
  final Map<String, dynamic> workerInfo;
  final List<Availability> availability;
  final String? catalogItemId;
  final String? catalogGroupId;
  final String? catalogAssetId;
  final int? taxonomyVersion;
  final double? distanceKm;
  final String? operationalAreaLabel;
  final bool isWithinServiceRadius;

  Service({
    required this.id,
    required this.namaLayanan,
    required this.category,
    required this.harga,
    required this.fotoUtamaUrl,
    required this.statusPersetujuan,
    required this.dibuatPada,
    required this.photoUrls,
    required this.metodePembayaran,
    required this.deskripsiLayanan,
    this.tipeLayanan,
    this.biayaSurvei,
    required this.workerInfo,
    required this.availability,
    this.catalogItemId,
    this.catalogGroupId,
    this.catalogAssetId,
    this.taxonomyVersion,
    this.distanceKm,
    this.operationalAreaLabel,
    this.isWithinServiceRadius = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final availabilityMap = json['availability'] as Map<String, dynamic>? ?? {};
    if (json['dibuatPada'] != null && json['dibuatPada']['_seconds'] != null) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(
        json['dibuatPada']['_seconds'] * 1000,
      );
    } else {
      parsedDate = DateTime.now();
    }

    final availabilityList = availabilityMap.entries.map((entry) {
      final day = entry.key;
      final slots = List<String>.from(entry.value ?? []);
      return Availability(day: day, slots: slots);
    }).toList();

    return Service(
      id: json['serviceId'] ?? json['id'] ?? '',
      namaLayanan: json['namaLayanan'] ?? 'Tanpa Nama',
      category: json['category'] ?? 'Lainnya',
      harga: json['harga'] ?? 0,
      fotoUtamaUrl:
          json['fotoUtamaUrl'] ??
          'https://placehold.co/100x100/EFEFEF/AAAAAA?text=No+Image',
      statusPersetujuan: json['statusPersetujuan'] ?? 'pending',
      dibuatPada: parsedDate,
      photoUrls: json['photoUrls'] ?? [],
      metodePembayaran: json['metodePembayaran'] ?? [],
      deskripsiLayanan: json['deskripsiLayanan'] ?? '',
      tipeLayanan: json['tipeLayanan'] ?? 'fixed',
      biayaSurvei: json['biayaSurvei'] ?? 0,
      workerInfo: json['workerInfo'] as Map<String, dynamic>? ?? {},
      availability: availabilityList,
      catalogItemId: json['catalogItemId']?.toString(),
      catalogGroupId: json['catalogGroupId']?.toString(),
      catalogAssetId: json['catalogAssetId']?.toString(),
      taxonomyVersion: int.tryParse(json['taxonomyVersion']?.toString() ?? ''),
      distanceKm: double.tryParse(json['distanceKm']?.toString() ?? ''),
      operationalAreaLabel: json['operationalAreaLabel']?.toString(),
      isWithinServiceRadius: json['isWithinServiceRadius'] == true,
    );
  }

  String get formattedExpiryDate {
    // Menambahkan 1 tahun dari tanggal dibuat sebagai contoh tanggal kedaluwarsa
    final expiry = dibuatPada.add(const Duration(days: 365));
    return DateFormat('dd.MM.yyyy').format(expiry);
  }

  String get formattedPrice {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatCurrency.format(harga);
  }
}
