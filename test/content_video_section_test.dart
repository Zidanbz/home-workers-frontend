import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';
import 'package:home_workers_fe/shared_widgets/content_video_section.dart';

void main() {
  const videos = [
    ContentVideo(
      id: 'video-1',
      title: 'Tutorial Pertama',
      description: 'Panduan awal.',
      videoId: '-jPkJ478RJ8',
      category: 'tutorial',
      audience: 'all',
      sortOrder: 0,
    ),
    ContentVideo(
      id: 'video-2',
      title: 'Tips Kedua',
      description: 'Tips bekerja.',
      videoId: 'abcdefghijk',
      category: 'tips_trik',
      audience: 'worker',
      sortOrder: 1,
    ),
  ];

  testWidgets(
    'section lintas audiens memakai nama generik dan dapat mengganti video',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ContentVideoSection(
                videos: videos,
                videoCardBuilder: (video, key) => SizedBox(
                  key: key,
                  height: 180,
                  child: Text('Aktif: ${video.title}'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Video Pilihan'), findsOneWidget);
      expect(find.text('Aktif: Tutorial Pertama'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('content-video-option-video-2')),
      );
      await tester.pump();

      expect(find.text('Aktif: Tips Kedua'), findsOneWidget);
      expect(find.text('Aktif: Tutorial Pertama'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
