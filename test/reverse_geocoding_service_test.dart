import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:home_workers_fe/core/services/reverse_geocoding_service.dart';

void main() {
  test('membentuk alamat Indonesia dari placemark perangkat', () async {
    Locale? requestedLocale;
    final service = ReverseGeocodingService(
      resolver: (latitude, longitude, {locale}) async {
        requestedLocale = locale;
        return const [
          Placemark(
            street: 'Jalan Boulevard',
            subLocality: 'Panakkukang',
            locality: 'Makassar',
            administrativeArea: 'Sulawesi Selatan',
            postalCode: '90231',
            country: 'Indonesia',
          ),
        ];
      },
    );

    final address = await service.resolve(
      latitude: -5.147665,
      longitude: 119.432732,
    );

    expect(
      address,
      'Jalan Boulevard, Panakkukang, Makassar, Sulawesi Selatan, 90231, '
      'Indonesia',
    );
    expect(requestedLocale, const Locale('id', 'ID'));
  });

  test('tidak memanggil geocoder untuk koordinat yang tidak valid', () async {
    var requestCount = 0;
    final service = ReverseGeocodingService(
      resolver: (latitude, longitude, {locale}) async {
        requestCount++;
        return const [];
      },
    );

    expect(await service.resolve(latitude: 0, longitude: 0), isNull);
    expect(await service.resolve(latitude: -91, longitude: 119), isNull);
    expect(requestCount, 0);
  });

  test('menghapus komponen alamat yang duplikat', () async {
    final service = ReverseGeocodingService(
      resolver: (latitude, longitude, {locale}) async => const [
        Placemark(
          street: 'Makassar',
          locality: 'makassar',
          administrativeArea: 'Sulawesi Selatan',
        ),
      ],
    );

    expect(
      await service.resolve(latitude: -5.147665, longitude: 119.432732),
      'Makassar, Sulawesi Selatan',
    );
  });

  test('fallback koordinat konsisten saat alamat tidak ditemukan', () {
    expect(
      ReverseGeocodingService.coordinateFallback(
        latitude: -5.147665,
        longitude: 119.432732,
      ),
      'Titik -5.14766, 119.43273',
    );
  });
}
