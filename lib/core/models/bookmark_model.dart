class Bookmark {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String serviceImageUrl;
  final int servicePrice;
  final String workerName;
  final String workerId;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.serviceImageUrl,
    required this.servicePrice,
    required this.workerName,
    required this.workerId,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      serviceImageUrl: json['serviceImageUrl'] ?? '',
      servicePrice: json['servicePrice'] ?? 0,
      workerName: json['workerName'] ?? '',
      workerId: json['workerId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'serviceImageUrl': serviceImageUrl,
      'servicePrice': servicePrice,
      'workerName': workerName,
      'workerId': workerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
