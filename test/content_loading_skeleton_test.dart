import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/shared_widgets/content_loading_skeleton.dart';

void main() {
  testWidgets('skeleton list tetap scrollable untuk pull-to-refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ContentLoadingSkeleton(itemCount: 2)),
      ),
    );

    expect(
      find.byKey(const ValueKey('content-loading-skeleton')),
      findsOneWidget,
    );
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets('skeleton menghormati preferensi disable animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ContentLoadingSkeleton(
              variant: ContentSkeletonVariant.dashboard,
              scrollable: false,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('content-loading-skeleton')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
