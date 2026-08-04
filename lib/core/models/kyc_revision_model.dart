class KycCorrection {
  final String field;
  final String reasonCode;
  final String note;

  const KycCorrection({
    required this.field,
    required this.reasonCode,
    required this.note,
  });

  factory KycCorrection.fromJson(Map<String, dynamic> json) => KycCorrection(
    field: json['field']?.toString() ?? '',
    reasonCode: json['reasonCode']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
  );
}

class KycReview {
  final String id;
  final int version;
  final String status;
  final List<KycCorrection> corrections;

  const KycReview({
    required this.id,
    required this.version,
    required this.status,
    required this.corrections,
  });

  factory KycReview.fromJson(Map<String, dynamic> json) => KycReview(
    id: json['id']?.toString() ?? '',
    version: int.tryParse(json['version']?.toString() ?? '') ?? 0,
    status: json['status']?.toString() ?? '',
    corrections: (json['corrections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => KycCorrection.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
  );
}

class KycRevisionStatus {
  final String status;
  final bool canAccessApp;
  final String? rejectionReason;
  final int revisionCount;
  final KycReview? review;

  const KycRevisionStatus({
    required this.status,
    required this.canAccessApp,
    required this.revisionCount,
    this.rejectionReason,
    this.review,
  });

  factory KycRevisionStatus.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'];
    return KycRevisionStatus(
      status: json['status']?.toString() ?? 'pending',
      canAccessApp: json['canAccessApp'] == true,
      rejectionReason: json['rejectionReason']?.toString(),
      revisionCount: int.tryParse(json['revisionCount']?.toString() ?? '') ?? 0,
      review: rawReview is Map
          ? KycReview.fromJson(Map<String, dynamic>.from(rawReview))
          : null,
    );
  }
}
