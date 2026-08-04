class OperationalLocation {
  const OperationalLocation({
    required this.areaLabel,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
  });

  final String areaLabel;
  final double latitude;
  final double longitude;
  final int serviceRadiusKm;

  factory OperationalLocation.fromWorkerProfile(Map<String, dynamic> json) {
    final rawLocation = json['operationalLocation'];
    final location = rawLocation is Map
        ? Map<String, dynamic>.from(rawLocation)
        : const <String, dynamic>{};

    double parseCoordinate(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return OperationalLocation(
      areaLabel: json['operationalAreaLabel']?.toString().trim() ?? '',
      latitude: parseCoordinate(location['latitude'] ?? location['_latitude']),
      longitude: parseCoordinate(
        location['longitude'] ?? location['_longitude'],
      ),
      serviceRadiusKm:
          int.tryParse(json['serviceRadiusKm']?.toString() ?? '') ?? 10,
    );
  }

  bool get isValid {
    return areaLabel.isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}
