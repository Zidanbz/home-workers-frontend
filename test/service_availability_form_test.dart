import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/availability_model.dart';
import 'package:home_workers_fe/features/worker_flow/service_management/utils/service_availability_form.dart';

void main() {
  test('prefills persisted slots using canonical Indonesian day names', () {
    final selection = buildServiceAvailabilitySelection([
      Availability(
        day: 'senin',
        slots: const ['Pagi 09.00 - 11.00', 'Sore 16.00 - 18.00'],
      ),
      Availability(day: 'Selasa', slots: const ['Siang 12.00 - 15.00']),
    ]);

    expect(
      selection['Senin'],
      containsAll(['Pagi 09.00 - 11.00', 'Sore 16.00 - 18.00']),
    );
    expect(selection['Selasa'], {'Siang 12.00 - 15.00'});
    expect(selection['Rabu'], isEmpty);
  });

  test('unchanged prefilled availability is recognized as unchanged', () {
    final saved = [
      Availability(day: 'Senin', slots: const ['Pagi 09.00 - 11.00']),
    ];
    final selection = buildServiceAvailabilitySelection(saved);

    expect(serviceAvailabilityMatches(saved, selection), isTrue);

    selection['Senin']!.add('Siang 12.00 - 15.00');
    expect(serviceAvailabilityMatches(saved, selection), isFalse);
  });

  test('retains unknown legacy days so unrelated edits do not erase them', () {
    final saved = [
      Availability(day: 'Hari Khusus', slots: const ['08:00 - 10:00']),
    ];
    final selection = buildServiceAvailabilitySelection(saved);

    expect(selection['Hari Khusus'], {'08:00 - 10:00'});
    expect(serviceAvailabilityMatches(saved, selection), isTrue);
  });
}
