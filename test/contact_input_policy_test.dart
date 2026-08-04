import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/utils/contact_input_policy.dart';

void main() {
  test('accepts common Indonesian WhatsApp formats', () {
    expect(validateIndonesianWhatsApp('0812-3456-7890'), isNull);
    expect(validateIndonesianWhatsApp('+62 812 3456 7890'), isNull);
    expect(validateIndonesianWhatsApp('6281234567890'), isNull);
  });

  test('rejects invalid and non-Indonesian numbers', () {
    expect(validateIndonesianWhatsApp(''), isNotNull);
    expect(validateIndonesianWhatsApp('0215551234'), isNotNull);
    expect(validateIndonesianWhatsApp('+14155552671'), isNotNull);
  });
}
