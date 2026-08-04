class RefundEvidence {
  final String? originalName;
  final String? contentType;
  final int? size;
  final String? url;

  const RefundEvidence({
    this.originalName,
    this.contentType,
    this.size,
    this.url,
  });

  factory RefundEvidence.fromJson(Map<String, dynamic> json) {
    return RefundEvidence(
      originalName: json['originalName']?.toString(),
      contentType: json['contentType']?.toString(),
      size: json['size'] is num ? (json['size'] as num).toInt() : null,
      url: json['url']?.toString(),
    );
  }
}

class RefundRequest {
  final String id;
  final String orderId;
  final String status;
  final String reasonCode;
  final String resolutionRequested;
  final String description;
  final String paymentTarget;
  final num requestedAmount;
  final num? approvedAmount;
  final List<RefundEvidence> customerEvidence;
  final Map<String, dynamic>? workerResponse;
  final Map<String, dynamic>? adminDecision;
  final String? evidenceRequestedFrom;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const RefundRequest({
    required this.id,
    required this.orderId,
    required this.status,
    required this.reasonCode,
    required this.resolutionRequested,
    required this.description,
    required this.paymentTarget,
    required this.requestedAmount,
    this.approvedAmount,
    this.customerEvidence = const [],
    this.workerResponse,
    this.adminDecision,
    this.evidenceRequestedFrom,
    this.createdAt,
    this.resolvedAt,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed?.toLocal();
      }
      if (value is Map && value['_seconds'] is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as num).toInt() * 1000,
        ).toLocal();
      }
      return null;
    }

    final rawEvidence = json['customerEvidence'];
    return RefundRequest(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'submitted',
      reasonCode: json['reasonCode']?.toString() ?? 'other',
      resolutionRequested: json['resolutionRequested']?.toString() ?? 'rework',
      description: json['description']?.toString() ?? '',
      paymentTarget: json['paymentTarget']?.toString() ?? 'initial',
      requestedAmount: json['requestedAmount'] is num
          ? json['requestedAmount'] as num
          : num.tryParse(json['requestedAmount']?.toString() ?? '') ?? 0,
      approvedAmount: json['approvedAmount'] is num
          ? json['approvedAmount'] as num
          : num.tryParse(json['approvedAmount']?.toString() ?? ''),
      customerEvidence: rawEvidence is List
          ? rawEvidence
                .whereType<Map>()
                .map(
                  (item) =>
                      RefundEvidence.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      workerResponse: json['workerResponse'] is Map
          ? Map<String, dynamic>.from(json['workerResponse'])
          : null,
      adminDecision: json['adminDecision'] is Map
          ? Map<String, dynamic>.from(json['adminDecision'])
          : null,
      evidenceRequestedFrom: json['evidenceRequestedFrom']?.toString(),
      createdAt: parseDate(json['createdAt']),
      resolvedAt: parseDate(json['resolvedAt']),
    );
  }

  bool get isActive => {
    'submitted',
    'awaiting_worker_response',
    'under_review',
    'more_evidence_required',
    'rework_offered',
    'rework_in_progress',
    'approved',
    'awaiting_refund_destination',
    'approved_manual',
    'processing',
    'failed',
  }.contains(status);

  String get statusLabel {
    const labels = {
      'submitted': 'Pengajuan terkirim',
      'awaiting_worker_response': 'Menunggu tanggapan Worker',
      'under_review': 'Sedang ditinjau Admin',
      'more_evidence_required': 'Perlu bukti tambahan',
      'rework_offered': 'Perbaikan ditawarkan',
      'rework_in_progress': 'Perbaikan sedang dilakukan',
      'approved': 'Refund disetujui',
      'awaiting_refund_destination': 'Lengkapi tujuan refund',
      'approved_manual': 'Menunggu transfer manual',
      'processing': 'Refund sedang diproses',
      'refunded': 'Refund selesai',
      'rejected': 'Pengajuan ditolak',
      'failed': 'Pemrosesan refund gagal',
    };
    return labels[status] ?? status;
  }
}
