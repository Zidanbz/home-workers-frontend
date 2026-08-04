import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/services/storage_service_page.dart';

void main() {
  test('error auth upload meminta pengguna memulihkan sesi', () {
    expect(
      servicePhotoUploadMessage('unauthenticated'),
      contains('logout lalu login kembali'),
    );
    expect(
      servicePhotoUploadMessage('unauthorized'),
      contains('logout lalu login kembali'),
    );
  });

  test('error jaringan upload tidak disamarkan sebagai error auth', () {
    expect(
      servicePhotoUploadMessage('retry-limit-exceeded'),
      contains('Periksa koneksi'),
    );
  });
}
