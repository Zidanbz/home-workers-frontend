class Address {
  final String id;
  final String label;
  final String fullAddress;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.latitude,
    this.longitude,
  });

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? lat;
    double? lng;

    if (location is Map<String, dynamic>) {
      lat = _asDouble(location['_latitude'] ?? location['latitude']);
      lng = _asDouble(location['_longitude'] ?? location['longitude']);
    }

    lat ??= _asDouble(json['latitude']);
    lng ??= _asDouble(json['longitude']);

    return Address(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Tanpa Label',
      fullAddress: json['fullAddress'] ?? 'Alamat tidak lengkap',
      latitude: lat,
      longitude: lng,
    );
  }
}
