import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';

void main() {
  test('mem-parsing konten video yang dikirim backend', () {
    final video = ContentVideo.fromJson({
      'id': 'video-1',
      'title': 'Tips Aman Bekerja',
      'description': 'Gunakan perlengkapan keselamatan.',
      'videoId': '-jPkJ478RJ8',
      'category': 'tips_trik',
      'audience': 'worker',
      'sortOrder': 5,
      'thumbnailUrl': 'https://evil.example/image.jpg',
    });

    expect(video.categoryLabel, 'Tips & Trik');
    expect(video.sortOrder, 5);
    expect(
      video.thumbnailUrl,
      'https://i.ytimg.com/vi/-jPkJ478RJ8/hqdefault.jpg',
    );
  });

  test('menolak ID YouTube yang tidak valid', () {
    expect(
      () => ContentVideo.fromJson({
        'id': 'video-1',
        'title': 'Video Tidak Valid',
        'videoId': '<script>',
      }),
      throwsFormatException,
    );
  });

  test('mempertahankan target audiens Customer dan semua pengguna', () {
    final customerVideo = ContentVideo.fromJson({
      'id': 'video-customer',
      'title': 'Tips Memesan Layanan',
      'videoId': '-jPkJ478RJ8',
      'audience': 'customer',
    });
    final sharedVideo = ContentVideo.fromJson({
      'id': 'video-shared',
      'title': 'Informasi Home Workers',
      'videoId': 'abcdefghijk',
      'audience': 'all',
    });

    expect(customerVideo.audience, 'customer');
    expect(sharedVideo.audience, 'all');
  });
}
