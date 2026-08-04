DateTime? _parseWarrantyDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  if (value is Map && value['_seconds'] is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      (value['_seconds'] as num).toInt() * 1000,
    ).toLocal();
  }
  return null;
}

class WarrantyEvidence {
  final String? originalName;
  final String? contentType;
  final int? size;
  final String? url;

  const WarrantyEvidence({
    this.originalName,
    this.contentType,
    this.size,
    this.url,
  });

  factory WarrantyEvidence.fromJson(Map<String, dynamic> json) {
    return WarrantyEvidence(
      originalName: json['originalName']?.toString(),
      contentType: json['contentType']?.toString(),
      size: (json['size'] as num?)?.toInt(),
      url: json['url']?.toString(),
    );
  }
}

class WarrantyEligibility {
  final bool eligible;
  final String? reason;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int claimCount;
  final int maxClaims;

  const WarrantyEligibility({
    required this.eligible,
    this.reason,
    this.startedAt,
    this.expiresAt,
    this.claimCount = 0,
    this.maxClaims = 2,
  });

  factory WarrantyEligibility.fromJson(Map<String, dynamic> json) {
    return WarrantyEligibility(
      eligible: json['eligible'] == true,
      reason: json['reason']?.toString(),
      startedAt: _parseWarrantyDate(json['startedAt']),
      expiresAt: _parseWarrantyDate(json['expiresAt']),
      claimCount: (json['claimCount'] as num?)?.toInt() ?? 0,
      maxClaims: (json['maxClaims'] as num?)?.toInt() ?? 2,
    );
  }

  Duration get remaining {
    final expiry = expiresAt;
    if (expiry == null) return Duration.zero;
    final value = expiry.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }
}

class WarrantyRepair {
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final String? note;
  final List<WarrantyEvidence> beforeEvidence;
  final List<WarrantyEvidence> afterEvidence;

  const WarrantyRepair({
    this.startedAt,
    this.submittedAt,
    this.note,
    this.beforeEvidence = const [],
    this.afterEvidence = const [],
  });

  factory WarrantyRepair.fromJson(Map<String, dynamic> json) {
    List<WarrantyEvidence> parseEvidence(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map(
            (item) =>
                WarrantyEvidence.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }

    return WarrantyRepair(
      startedAt: _parseWarrantyDate(json['startedAt']),
      submittedAt: _parseWarrantyDate(json['submittedAt']),
      note: json['note']?.toString(),
      beforeEvidence: parseEvidence(json['beforeEvidence']),
      afterEvidence: parseEvidence(json['afterEvidence']),
    );
  }
}

class WarrantyClaim {
  final String id;
  final String orderId;
  final String status;
  final String issueType;
  final String description;
  final DateTime? preferredVisitAt;
  final DateTime? warrantyExpiresAt;
  final DateTime? workerResponseDeadlineAt;
  final DateTime? confirmationDeadlineAt;
  final List<WarrantyEvidence> customerEvidence;
  final List<WarrantyEvidence> additionalEvidence;
  final Map<String, dynamic>? workerResponse;
  final Map<String, dynamic>? adminDecision;
  final Map<String, dynamic>? customerConfirmation;
  final WarrantyRepair? repair;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const WarrantyClaim({
    required this.id,
    required this.orderId,
    required this.status,
    required this.issueType,
    required this.description,
    this.preferredVisitAt,
    this.warrantyExpiresAt,
    this.workerResponseDeadlineAt,
    this.confirmationDeadlineAt,
    this.customerEvidence = const [],
    this.additionalEvidence = const [],
    this.workerResponse,
    this.adminDecision,
    this.customerConfirmation,
    this.repair,
    this.createdAt,
    this.resolvedAt,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) {
    List<WarrantyEvidence> parseEvidence(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map(
            (item) =>
                WarrantyEvidence.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }

    return WarrantyClaim(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'under_review',
      issueType: json['issueType']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      preferredVisitAt: _parseWarrantyDate(json['preferredVisitAt']),
      warrantyExpiresAt: _parseWarrantyDate(json['warrantyExpiresAt']),
      workerResponseDeadlineAt: _parseWarrantyDate(
        json['workerResponseDeadlineAt'],
      ),
      confirmationDeadlineAt: _parseWarrantyDate(
        json['confirmationDeadlineAt'],
      ),
      customerEvidence: parseEvidence(json['customerEvidence']),
      additionalEvidence: parseEvidence(json['additionalEvidence']),
      workerResponse: json['workerResponse'] is Map
          ? Map<String, dynamic>.from(json['workerResponse'])
          : null,
      adminDecision: json['adminDecision'] is Map
          ? Map<String, dynamic>.from(json['adminDecision'])
          : null,
      customerConfirmation: json['customerConfirmation'] is Map
          ? Map<String, dynamic>.from(json['customerConfirmation'])
          : null,
      repair: json['repair'] is Map
          ? WarrantyRepair.fromJson(Map<String, dynamic>.from(json['repair']))
          : null,
      createdAt: _parseWarrantyDate(json['createdAt']),
      resolvedAt: _parseWarrantyDate(json['resolvedAt']),
    );
  }

  bool get isActive => {
    'under_review',
    'more_evidence_required',
    'awaiting_worker_response',
    'repair_scheduled',
    'repair_in_progress',
    'customer_confirmation',
    'escalated',
  }.contains(status);

  String get statusLabel {
    const labels = {
      'under_review': 'Ditinjau Admin',
      'more_evidence_required': 'Perlu Bukti Tambahan',
      'awaiting_worker_response': 'Menunggu Tanggapan Worker',
      'repair_scheduled': 'Perbaikan Dijadwalkan',
      'repair_in_progress': 'Perbaikan Berlangsung',
      'customer_confirmation': 'Menunggu Konfirmasi Anda',
      'escalated': 'Diperiksa Lebih Lanjut',
      'resolved': 'Garansi Selesai',
      'rejected': 'Klaim Ditolak',
    };
    return labels[status] ?? status;
  }
}

class OrderWarranty {
  final WarrantyEligibility eligibility;
  final WarrantyClaim? claim;

  const OrderWarranty({required this.eligibility, this.claim});

  factory OrderWarranty.fromJson(Map<String, dynamic> json) {
    return OrderWarranty(
      eligibility: WarrantyEligibility.fromJson(
        json['eligibility'] is Map
            ? Map<String, dynamic>.from(json['eligibility'])
            : const {},
      ),
      claim: json['claim'] is Map
          ? WarrantyClaim.fromJson(Map<String, dynamic>.from(json['claim']))
          : null,
    );
  }
}
