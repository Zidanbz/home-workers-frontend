import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/auth/pages/select_role_page.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    double textScale = 1,
    bool googleRegistration = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SelectRolePage(googleRegistration: googleRegistration),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('menampilkan pilihan Customer, Worker, dan login', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Apa yang ingin\nAnda lakukan?'), findsOneWidget);
    expect(find.text('Saya butuh bantuan'), findsOneWidget);
    expect(find.text('Saya ingin menawarkan jasa'), findsOneWidget);
    expect(find.byKey(const Key('customer-role-card')), findsOneWidget);
    expect(find.byKey(const Key('worker-role-card')), findsOneWidget);
    expect(find.byKey(const Key('select-role-login-button')), findsOneWidget);
  });

  testWidgets(
    'mode registrasi Google memberi konteks dan menyembunyikan login',
    (tester) async {
      await pumpPage(tester, googleRegistration: true);

      expect(find.text('Pilih peran untuk\nakun Anda'), findsOneWidget);
      expect(find.byKey(const Key('google-registration-note')), findsOneWidget);
      expect(find.byKey(const Key('select-role-login-button')), findsNothing);
    },
  );

  testWidgets(
    'layout layar kecil dan text scaling dapat di-scroll tanpa overflow',
    (tester) async {
      await pumpPage(tester, size: const Size(320, 568), textScale: 1.35);

      expect(find.byKey(const Key('select-role-scroll-view')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('select-role-login-button')),
        220,
        scrollable: find.descendant(
          of: find.byKey(const Key('select-role-scroll-view')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('select-role-login-button')), findsOneWidget);
    },
  );
}
