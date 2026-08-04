import 'package:home_workers_fe/core/models/availability_model.dart';

const serviceAvailabilityDays = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Builds an editable copy of the persisted availability.
///
/// Every standard day is present so the form can render consistently. Legacy
/// or custom day keys are retained as well to prevent unrelated edits from
/// silently deleting data that the current UI cannot display.
Map<String, Set<String>> buildServiceAvailabilitySelection(
  Iterable<Availability> savedAvailability,
) {
  final selection = <String, Set<String>>{
    for (final day in serviceAvailabilityDays) day: <String>{},
  };

  for (final availability in savedAvailability) {
    final rawDay = availability.day.trim();
    if (rawDay.isEmpty) continue;
    final canonicalDay = serviceAvailabilityDays
        .where((day) => day.toLowerCase() == rawDay.toLowerCase())
        .firstOrNull;
    selection
        .putIfAbsent(canonicalDay ?? rawDay, () => <String>{})
        .addAll(availability.slots);
  }

  return selection;
}

Map<String, List<String>> serializeServiceAvailability(
  Map<String, Set<String>> selection,
) {
  return selection.map(
    (day, slots) => MapEntry(day, slots.toList(growable: false)),
  );
}

bool serviceAvailabilityMatches(
  Iterable<Availability> savedAvailability,
  Map<String, Set<String>> selection,
) {
  final saved = buildServiceAvailabilitySelection(savedAvailability);
  if (saved.length != selection.length) return false;

  for (final entry in saved.entries) {
    final currentSlots = selection[entry.key];
    if (currentSlots == null ||
        currentSlots.length != entry.value.length ||
        !currentSlots.containsAll(entry.value)) {
      return false;
    }
  }
  return true;
}
