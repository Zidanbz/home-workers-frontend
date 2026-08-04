import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

DateTime? _parseOptionalDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Map && value['_seconds'] != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      (value['_seconds'] as num).toInt() * 1000,
    ).toLocal();
  }
  if (value is DateTime) return value.isUtc ? value.toLocal() : value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : (parsed.isUtc ? parsed.toLocal() : parsed);
  }
  return null;
}

class OrderCompletionConfirmation {
  final bool alreadyCompleted;
  final String status;
  final num? workerAmount;
  final DateTime? completedAt;
  final DateTime? payoutAvailableAt;
  final String payoutStatus;

  const OrderCompletionConfirmation({
    required this.alreadyCompleted,
    required this.status,
    required this.workerAmount,
    required this.completedAt,
    required this.payoutAvailableAt,
    required this.payoutStatus,
  });

  factory OrderCompletionConfirmation.fromJson(Map<String, dynamic> json) {
    return OrderCompletionConfirmation(
      alreadyCompleted: json['alreadyCompleted'] == true,
      // Endpoint lama belum mengirim field status. HTTP 200 dari endpoint ini
      // tetap berarti transaksi completion sudah commit secara atomik.
      status: json['status']?.toString() ?? 'completed',
      workerAmount: json['workerAmount'] as num?,
      completedAt: _parseOptionalDateTime(
        json['completedAt'] ?? json['completionConfirmedAt'],
      ),
      payoutAvailableAt: _parseOptionalDateTime(json['payoutAvailableAt']),
      payoutStatus: json['payoutStatus']?.toString() ?? 'released',
    );
  }
}

class CompletionEvidence {
  final String? url;
  final String originalName;
  final String contentType;
  final int size;

  const CompletionEvidence({
    required this.url,
    required this.originalName,
    required this.contentType,
    required this.size,
  });

  factory CompletionEvidence.fromJson(Map<String, dynamic> json) {
    return CompletionEvidence(
      url: json['url']?.toString(),
      originalName: json['originalName']?.toString() ?? 'Bukti pekerjaan',
      contentType: json['contentType']?.toString() ?? 'image/jpeg',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkStartSubmission {
  final DateTime? startedAt;
  final List<CompletionEvidence> beforeEvidence;

  const WorkStartSubmission({
    required this.startedAt,
    required this.beforeEvidence,
  });

  factory WorkStartSubmission.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['beforeEvidence'];
    return WorkStartSubmission(
      startedAt: _parseOptionalDateTime(json['startedAt']),
      beforeEvidence: rawEvidence is List
          ? rawEvidence
                .whereType<Map>()
                .map(
                  (item) => CompletionEvidence.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class CompletionSubmission {
  final String note;
  final DateTime? submittedAt;
  final List<CompletionEvidence> afterEvidence;

  const CompletionSubmission({
    required this.note,
    required this.submittedAt,
    required this.afterEvidence,
  });

  // Alias sementara agar widget lama tetap kompatibel selama migrasi.
  List<CompletionEvidence> get evidence => afterEvidence;

  factory CompletionSubmission.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['afterEvidence'] ?? json['evidence'];
    return CompletionSubmission(
      note: json['note']?.toString() ?? '',
      submittedAt: _parseOptionalDateTime(json['submittedAt']),
      afterEvidence: rawEvidence is List
          ? rawEvidence
                .whereType<Map>()
                .map(
                  (item) => CompletionEvidence.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

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
  final String? customerContact;
  final String serviceType;
  final bool hasBeenReviewed;
  final String? workerDescription;
  final String? workerName;
  final String? workerId;
  final String? workerAvatar;
  final num? quotedPrice;
  final LatLng? coordinates; // Koordinat untuk peta
  final String? paymentStatus;
  final String? finalPaymentStatus;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final WorkStartSubmission? workStartSubmission;
  final CompletionSubmission? completionSubmission;
  final DateTime? completionConfirmedAt;
  final String? payoutStatus;
  final num? payoutAmount;
  final String? refundStatus;
  final String? disputeStatus;
  final DateTime? payoutAvailableAt;
  final DateTime? workerAcceptanceStartedAt;
  final DateTime? workerAcceptanceDeadlineAt;
  final DateTime? workerAcceptedAt;
  final DateTime? acceptanceExpiredAt;
  final String? workerAcceptanceState;
  final String? warrantyStatus;
  final DateTime? warrantyStartedAt;
  final DateTime? warrantyExpiresAt;
  final String? activeWarrantyClaimId;
  final int warrantyClaimCount;

  Order({
    required this.id,
    required this.status,
    required this.jadwalPerbaikan,
    required this.dibuatPada,
    required this.serviceName,
    required this.customerName,
    required this.customerAddress,
    this.customerContact,
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
    this.paymentStatus,
    this.finalPaymentStatus,
    this.completedAt,
    this.updatedAt,
    this.workStartSubmission,
    this.completionSubmission,
    this.completionConfirmedAt,
    this.payoutStatus,
    this.payoutAmount,
    this.refundStatus,
    this.disputeStatus,
    this.payoutAvailableAt,
    this.workerAcceptanceStartedAt,
    this.workerAcceptanceDeadlineAt,
    this.workerAcceptedAt,
    this.acceptanceExpiredAt,
    this.workerAcceptanceState,
    this.warrantyStatus,
    this.warrantyStartedAt,
    this.warrantyExpiresAt,
    this.activeWarrantyClaimId,
    this.warrantyClaimCount = 0,
  });

  Order copyWith({
    String? id,
    String? status,
    DateTime? jadwalPerbaikan,
    DateTime? dibuatPada,
    String? customerId,
    String? category,
    String? serviceName,
    String? customerName,
    String? customerAddress,
    String? customerContact,
    String? serviceType,
    bool? hasBeenReviewed,
    String? workerDescription,
    String? workerName,
    String? workerId,
    String? workerAvatar,
    num? quotedPrice,
    LatLng? coordinates,
    String? paymentStatus,
    String? finalPaymentStatus,
    DateTime? completedAt,
    DateTime? updatedAt,
    WorkStartSubmission? workStartSubmission,
    CompletionSubmission? completionSubmission,
    DateTime? completionConfirmedAt,
    String? payoutStatus,
    num? payoutAmount,
    String? refundStatus,
    String? disputeStatus,
    DateTime? payoutAvailableAt,
    DateTime? workerAcceptanceStartedAt,
    DateTime? workerAcceptanceDeadlineAt,
    DateTime? workerAcceptedAt,
    DateTime? acceptanceExpiredAt,
    String? workerAcceptanceState,
    String? warrantyStatus,
    DateTime? warrantyStartedAt,
    DateTime? warrantyExpiresAt,
    String? activeWarrantyClaimId,
    int? warrantyClaimCount,
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      jadwalPerbaikan: jadwalPerbaikan ?? this.jadwalPerbaikan,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      serviceName: serviceName ?? this.serviceName,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerContact: customerContact ?? this.customerContact,
      customerId: customerId ?? this.customerId,
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      workerDescription: workerDescription ?? this.workerDescription,
      workerName: workerName ?? this.workerName,
      workerId: workerId ?? this.workerId,
      workerAvatar: workerAvatar ?? this.workerAvatar,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      hasBeenReviewed: hasBeenReviewed ?? this.hasBeenReviewed,
      coordinates: coordinates ?? this.coordinates,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      finalPaymentStatus: finalPaymentStatus ?? this.finalPaymentStatus,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workStartSubmission: workStartSubmission ?? this.workStartSubmission,
      completionSubmission: completionSubmission ?? this.completionSubmission,
      completionConfirmedAt:
          completionConfirmedAt ?? this.completionConfirmedAt,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      disputeStatus: disputeStatus ?? this.disputeStatus,
      payoutAvailableAt: payoutAvailableAt ?? this.payoutAvailableAt,
      workerAcceptanceStartedAt:
          workerAcceptanceStartedAt ?? this.workerAcceptanceStartedAt,
      workerAcceptanceDeadlineAt:
          workerAcceptanceDeadlineAt ?? this.workerAcceptanceDeadlineAt,
      workerAcceptedAt: workerAcceptedAt ?? this.workerAcceptedAt,
      acceptanceExpiredAt: acceptanceExpiredAt ?? this.acceptanceExpiredAt,
      workerAcceptanceState:
          workerAcceptanceState ?? this.workerAcceptanceState,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      warrantyStartedAt: warrantyStartedAt ?? this.warrantyStartedAt,
      warrantyExpiresAt: warrantyExpiresAt ?? this.warrantyExpiresAt,
      activeWarrantyClaimId:
          activeWarrantyClaimId ?? this.activeWarrantyClaimId,
      warrantyClaimCount: warrantyClaimCount ?? this.warrantyClaimCount,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing Timestamp
    DateTime parseFirestoreTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Map && timestamp['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      }
      if (timestamp is DateTime) {
        return timestamp.isUtc ? timestamp.toLocal() : timestamp;
      }
      if (timestamp is String) {
        final parsed = DateTime.tryParse(timestamp);
        if (parsed == null) return DateTime.now();
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
      return DateTime.now();
    }

    DateTime? parseOptionalTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Map && timestamp['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      }
      if (timestamp is DateTime) {
        return timestamp.isUtc ? timestamp.toLocal() : timestamp;
      }
      if (timestamp is String) {
        final parsed = DateTime.tryParse(timestamp);
        return parsed == null
            ? null
            : (parsed.isUtc ? parsed.toLocal() : parsed);
      }
      return null;
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
          debugPrint('Gagal parsing koordinat dari GeoPoint Map: $e');
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
          debugPrint('Gagal parsing koordinat dari String: $e');
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
      customerContact: json['customerContact']?.toString(),
      category: json['category'] ?? 'lainnya',
      serviceType: json['serviceType'] ?? json['tipeLayanan'] ?? 'lainnya',
      quotedPrice: parsePrice(
        json['harga'] ??
            json['serviceHarga'] ??
            json['price'] ??
            json['proposedPrice'] ??
            json['quotedPrice'],
      ),
      customerId: json['customerId'] ?? '',
      workerId: json['workerId'],
      workerName: json['workerName'],
      workerDescription: json['workerDescription'],
      hasBeenReviewed: json['hasBeenReviewed'] ?? false,
      workerAvatar: json['workerAvatar'],
      jadwalPerbaikan: parseFirestoreTimestamp(json['jadwalPerbaikan']),
      dibuatPada: parseFirestoreTimestamp(json['dibuatPada']),
      paymentStatus: json['paymentStatus'],
      finalPaymentStatus: json['finalPaymentStatus'],
      completedAt: parseOptionalTimestamp(json['completedAt']),
      updatedAt: parseOptionalTimestamp(json['updatedAt']),
      workStartSubmission: json['workStartSubmission'] is Map
          ? WorkStartSubmission.fromJson(
              Map<String, dynamic>.from(json['workStartSubmission']),
            )
          : null,
      completionSubmission: json['completionSubmission'] is Map
          ? CompletionSubmission.fromJson(
              Map<String, dynamic>.from(json['completionSubmission']),
            )
          : null,
      completionConfirmedAt: parseOptionalTimestamp(
        json['completionConfirmedAt'],
      ),
      payoutStatus: json['payoutStatus']?.toString(),
      payoutAmount: parsePrice(json['payoutAmount']),
      refundStatus: json['refundStatus']?.toString(),
      disputeStatus: json['disputeStatus']?.toString(),
      payoutAvailableAt: parseOptionalTimestamp(json['payoutAvailableAt']),
      workerAcceptanceStartedAt: parseOptionalTimestamp(
        json['workerAcceptanceStartedAt'],
      ),
      workerAcceptanceDeadlineAt: parseOptionalTimestamp(
        json['workerAcceptanceDeadlineAt'],
      ),
      workerAcceptedAt: parseOptionalTimestamp(json['workerAcceptedAt']),
      acceptanceExpiredAt: parseOptionalTimestamp(json['acceptanceExpiredAt']),
      workerAcceptanceState: json['workerAcceptanceState']?.toString(),
      warrantyStatus: json['warrantyStatus']?.toString(),
      warrantyStartedAt: parseOptionalTimestamp(json['warrantyStartedAt']),
      warrantyExpiresAt: parseOptionalTimestamp(json['warrantyExpiresAt']),
      activeWarrantyClaimId: json['activeWarrantyClaimId']?.toString(),
      warrantyClaimCount: (json['warrantyClaimCount'] as num?)?.toInt() ?? 0,
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
