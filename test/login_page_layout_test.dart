import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('login tetap scrollable dan footer aman dari navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(initializeOnCreate: false),
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              padding: EdgeInsets.only(bottom: 48),
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
            child: LoginPage(initializeFcm: false),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('login-scroll-view')), findsOneWidget);
    expect(find.byKey(const Key('login-form-card')), findsOneWidget);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('login-scroll-view')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    final footer = tester.getRect(
      find.byKey(const Key('login-register-footer')),
    );
    expect(footer.bottom, lessThanOrEqualTo(592));
    expect(find.text('Belum punya akun?'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form login tetap dapat digunakan saat keyboard terbuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(initializeOnCreate: false),
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              viewInsets: EdgeInsets.only(bottom: 280),
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
            child: LoginPage(initializeFcm: false),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('login-password-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-password-field')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-submit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
