import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/services/google_auth_service.dart';

void main() {
  test('sandbox memakai Web OAuth client Firebase development', () {
    expect(
      GoogleAuthService.androidServerClientIdFor('sandbox'),
      '132125085396-984levalimj08hagnoh5i7j62e1h9q0a.apps.googleusercontent.com',
    );
  });

  test('production memakai Web OAuth client Firebase production', () {
    expect(
      GoogleAuthService.androidServerClientIdFor('prod'),
      '891691718664-4dvnlivp2uiqgdte9p3p1n0bkf9m80p7.apps.googleusercontent.com',
    );
  });
}
