import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/operational_location_model.dart';

void main() {
  test('mem-parsing area operasional milik Worker', () {
    final location = OperationalLocation.fromWorkerProfile({
      'operationalAreaLabel': 'Panakkukang, Makassar',
      'serviceRadiusKm': 10,
      'operationalLocation': {'latitude': -5.147665, 'longitude': 119.432732},
    });

    expect(location.isValid, isTrue);
    expect(location.areaLabel, 'Panakkukang, Makassar');
    expect(location.serviceRadiusKm, 10);
  });

  test('koordinat 0,0 tidak dianggap area operasional valid', () {
    final location = OperationalLocation.fromWorkerProfile({
      'operationalAreaLabel': 'Alamat lama',
      'operationalLocation': {'latitude': 0, 'longitude': 0},
    });

    expect(location.isValid, isFalse);
  });
}
