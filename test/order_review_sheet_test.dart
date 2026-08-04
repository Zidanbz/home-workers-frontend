import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/customer_flow/orders/widgets/order_review_sheet.dart';

void main() {
  testWidgets('requires a star and submits the selected rating', (
    tester,
  ) async {
    int? submittedRating;
    String? submittedComment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showOrderReviewSheet(
                context: context,
                serviceName: 'Servis AC',
                workerName: 'Budi',
                onSubmit: (rating, comment) async {
                  submittedRating = rating;
                  submittedComment = comment;
                },
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    final submitButton = find.byKey(const ValueKey('submit-review-button'));
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('review-star-5')));
    await tester.enterText(find.byType(TextField), 'Pekerjaan rapi');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(submittedRating, 5);
    expect(submittedComment, 'Pekerjaan rapi');
    expect(find.text('Bagaimana hasil pekerjaannya?'), findsNothing);
  });
}
