import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/auth/policies/password_reset_copy.dart';

void main() {
  test(
    'konfirmasi reset bersifat kondisional dan tidak memastikan akun ada',
    () {
      final message = buildPasswordResetConfirmation(' User@Example.com ');

      expect(message, contains('Jika "user@example.com" terdaftar'));
      expect(message, contains('akan dikirim'));
      expect(message, isNot(contains('telah dikirim')));
    },
  );
}
