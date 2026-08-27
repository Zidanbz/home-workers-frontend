import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/address_model.dart';
import 'package:home_workers_fe/core/models/service_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/controllers/marketplace_page_controller.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/marketplace_page.dart';
import 'package:provider/provider.dart';

class _AuthenticatedAuthProvider extends AuthProvider {
  _AuthenticatedAuthProvider() : super(initializeOnCreate: false);

  @override
  String? get token => 'customer-token';
}

class _NearbyApiService extends ApiService {
  String? requestedAddressId;

  @override
  Future<List<Service>> getAllApprovedServices({String? category}) async => [];

  @override
  Future<List<Address>> getMyAddresses(String token) async => [
    Address(
      id: 'alamat-rumah',
      label: 'Rumah',
      fullAddress: 'Makassar',
      latitude: -5.1477,
      longitude: 119.4327,
    ),
  ];

  @override
  Future<List<Service>> getNearbyApprovedServices({
    required String token,
    required String addressId,
  }) async {
    requestedAddressId = addressId;
    return [
      Service(
        id: 'service-nearby',
        namaLayanan: 'Servis Terdekat',
        category: 'Perbaikan',
        harga: 100000,
        fotoUtamaUrl: '',
        statusPersetujuan: 'approved',
        dibuatPada: DateTime(2026, 8, 14),
        photoUrls: const [],
        metodePembayaran: const ['QRIS'],
        deskripsiLayanan: 'Layanan pengujian',
        workerInfo: const {'nama': 'Worker Dekat', 'rating': 5},
        availability: const [],
        distanceKm: 1.2,
        operationalAreaLabel: 'Makassar',
        isWithinServiceRadius: true,
      ),
    ];
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
  });

  test('controller mempertahankan intent filter terdekat', () {
    final controller = MarketplacePageController();
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.showNearestServices();
    controller.showNearestServices();

    expect(controller.nearestRequestVersion, 2);
    expect(notifications, 2);
    controller.dispose();
  });

  testWidgets('intent dari Home mengaktifkan filter terdekat', (tester) async {
    final controller = MarketplacePageController();
    final apiService = _NearbyApiService();
    final authProvider = _AuthenticatedAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          home: MarketplacePage(controller: controller, apiService: apiService),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.showNearestServices();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(apiService.requestedAddressId, 'alamat-rumah');
    expect(find.text('1 layanan • Terdekat dari Rumah'), findsOneWidget);
    expect(find.text('Servis Terdekat'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('marketplace-distance-info')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    authProvider.dispose();
  });
}
