import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/customer_flow/booking/utils/booking_location_policy.dart';

void main() {
  group('isValidBookingLocationCoordinates', () {
    test('menerima koordinat lokasi yang valid', () {
      expect(isValidBookingLocationCoordinates(-5.147665, 119.432732), isTrue);
    });

    test('menolak koordinat kosong, nol, atau di luar batas bumi', () {
      expect(isValidBookingLocationCoordinates(null, 119.432732), isFalse);
      expect(isValidBookingLocationCoordinates(-5.147665, null), isFalse);
      expect(isValidBookingLocationCoordinates(0, 0), isFalse);
      expect(isValidBookingLocationCoordinates(-91, 119.432732), isFalse);
      expect(isValidBookingLocationCoordinates(-5.147665, 181), isFalse);
    });
  });
}
