import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/performer_model.dart';

void main() {
  test('performer memakai avatar publik dari kontrak dashboard baru', () {
    final performer = Performer.fromJson({
      'nama': 'Budisanto',
      'avatarUrl': 'https://cdn.example.test/avatar.jpg',
      'fotoDiriUrl': 'https://storage.example.test/selfie_encrypted.jpg',
      'rating': 5,
    });

    expect(performer.avatarUrl, 'https://cdn.example.test/avatar.jpg');
    expect(performer.rating, 5);
  });

  test('performer tidak memakai selfie KYC atau URL non-HTTPS', () {
    final kycOnly = Performer.fromJson({
      'nama': 'Worker',
      'fotoDiriUrl': 'https://storage.example.test/selfie_encrypted.jpg',
      'rating': 4.8,
    });
    final insecure = Performer.fromJson({
      'nama': 'Worker',
      'avatarUrl': 'http://example.test/avatar.jpg',
    });

    expect(kycOnly.avatarUrl, isEmpty);
    expect(insecure.avatarUrl, isEmpty);
  });
}
