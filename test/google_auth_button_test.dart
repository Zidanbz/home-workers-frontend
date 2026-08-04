import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/widgets/google_auth_button.dart';

void main() {
  Widget buildButton({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GoogleAuthButton(
              label: 'Lanjutkan dengan Google',
              onPressed: onPressed,
              isLoading: isLoading,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan logo dan label Google', (tester) async {
    var pressed = false;
    await tester.pumpWidget(buildButton(onPressed: () => pressed = true));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    expect(pressed, isTrue);
  });

  testWidgets('loading menjaga tombol dan mencegah klik ganda', (tester) async {
    var pressCount = 0;
    await tester.pumpWidget(
      buildButton(onPressed: () => pressCount++, isLoading: true),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsNothing);

    await tester.tap(find.byType(OutlinedButton));
    expect(pressCount, 0);
  });
}
