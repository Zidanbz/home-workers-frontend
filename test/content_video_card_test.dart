import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';
import 'package:home_workers_fe/shared_widgets/content_video_card.dart';

const video = ContentVideo(
  id: 'video-1',
  title: 'Tips Menggunakan Aplikasi',
  description: 'Panduan singkat untuk Worker.',
  videoId: '-jPkJ478RJ8',
  category: 'tips_trik',
  audience: 'worker',
  sortOrder: 0,
);

void main() {
  testWidgets('kartu video memuat player inline secara lazy setelah ditekan', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var playerBuildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: ContentVideoCard(
                video: video,
                playerBuilder: (_) {
                  playerBuildCount += 1;
                  return const ColoredBox(
                    key: ValueKey('fake-youtube-player'),
                    color: Colors.black,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tips Menggunakan Aplikasi'), findsOneWidget);
    expect(find.text('Tips & Trik'), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-youtube-player')), findsNothing);
    expect(playerBuildCount, 0);
    expect(
      find.bySemanticsLabel(
        'Putar Tips Menggunakan Aplikasi di dalam aplikasi. '
        'Panduan singkat untuk Worker.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('content-video-thumbnail')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fake-youtube-player')), findsOneWidget);
    expect(playerBuildCount, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('kartu video tidak overflow pada layar kecil dan teks besar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.35),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ContentVideoCard(
                  video: video,
                  playerBuilder: (_) => const ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
