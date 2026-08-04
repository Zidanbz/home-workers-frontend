import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

typedef PlacemarkResolver =
    Future<List<Placemark>> Function(
      double latitude,
      double longitude, {
      Locale? locale,
    });

class ReverseGeocodingService {
  ReverseGeocodingService({PlacemarkResolver? resolver})
    : _resolver = resolver ?? _resolveWithPlatformGeocoder;

  static final Geocoding _geocoding = Geocoding();
  final PlacemarkResolver _resolver;

  Future<String?> resolve({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      return null;
    }

    try {
      final placemarks = await _resolver(
        latitude,
        longitude,
        locale: const Locale('id', 'ID'),
      ).timeout(const Duration(seconds: 15));
      if (placemarks.isEmpty) return null;

      return _formatPlacemark(placemarks.first);
    } on TimeoutException {
      return null;
    } catch (_) {
      // Geocoder perangkat dapat tidak tersedia atau terkena rate limit.
      // Pemanggil tetap menyimpan koordinat dan memakai fallback yang aman.
      return null;
    }
  }

  static Future<List<Placemark>> _resolveWithPlatformGeocoder(
    double latitude,
    double longitude, {
    Locale? locale,
  }) {
    return _geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
      locale: locale,
    );
  }

  static String? _formatPlacemark(Placemark placemark) {
    final street = placemark.street?.trim();
    final components = <String?>[
      if (street == null || street.isEmpty) placemark.name,
      street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];

    final uniqueComponents = <String>[];
    final normalizedComponents = <String>{};
    for (final component in components) {
      final value = component?.trim();
      if (value == null || value.isEmpty) continue;
      if (normalizedComponents.add(value.toLowerCase())) {
        uniqueComponents.add(value);
      }
    }

    return uniqueComponents.isEmpty ? null : uniqueComponents.join(', ');
  }

  static String coordinateFallback({
    required double latitude,
    required double longitude,
  }) {
    return 'Titik ${latitude.toStringAsFixed(5)}, '
        '${longitude.toStringAsFixed(5)}';
  }
}
