import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/widgets/nearest_address_loading_overlay.dart';

void main() {
  testWidgets('loading alamat terlihat dan tetap rapi pada layar kecil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NearestAddressLoadingOverlay())),
    );

    expect(
      find.byKey(const ValueKey('nearest-address-loading')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat alamat tersimpan…'), findsOneWidget);
    expect(find.text('Menyiapkan pilihan lokasi Anda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
