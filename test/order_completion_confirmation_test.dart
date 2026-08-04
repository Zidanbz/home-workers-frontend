import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/models/payment_invoice_model.dart';
import 'package:home_workers_fe/core/models/refund_model.dart';
import 'package:home_workers_fe/core/models/warranty_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/customer_flow/orders/pages/customer_order_detail_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this.events) : super(initializeOnCreate: false);

  final List<String> events;

  @override
  String? get token => 'token-lama';

  @override
  Future<String?> refreshAccessToken() async {
    events.add('refresh-token');
    return 'token-baru';
  }
}

class _FakeApiService extends ApiService {
  _FakeApiService(this.order, this.events);

  final Order order;
  final List<String> events;
  bool confirmationCommitted = false;

  @override
  Future<Order> getOrderById({
    required String token,
    required String orderId,
  }) async {
    if (confirmationCommitted) {
      // Mensimulasikan GET setelah PUT gagal/terlambat. Status lokal tidak
      // boleh kembali ke completion_submitted setelah transaksi sudah commit.
      throw Exception('sinkronisasi detail terlambat');
    }
    return order;
  }

  @override
  Future<RefundRequest?> getOrderRefund({
    required String token,
    required String orderId,
  }) async {
    return null;
  }

  @override
  Future<List<PaymentInvoice>> getOrderInvoices({
    required String token,
    required String orderId,
  }) async {
    return const [];
  }

  @override
  Future<OrderWarranty> getOrderWarranty({
    required String token,
    required String orderId,
  }) async {
    throw Exception('garansi belum tersedia');
  }

  @override
  Future<OrderCompletionConfirmation> confirmOrderCompletion({
    required String token,
    required String orderId,
  }) async {
    events.add('confirm:$token');
    confirmationCommitted = true;
    return OrderCompletionConfirmation(
      alreadyCompleted: false,
      status: 'completed',
      workerAmount: 80000,
      completedAt: DateTime(2026, 8, 4, 22),
      payoutAvailableAt: DateTime(2026, 8, 4, 22),
      payoutStatus: 'released',
    );
  }

  @override
  Future<void> submitReview({
    required String token,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    events.add('review:$token:$rating:$comment');
  }
}

Order _completionSubmittedOrder() {
  return Order(
    id: 'order-1',
    status: 'completion_submitted',
    jadwalPerbaikan: DateTime(2026, 8, 4, 18),
    dibuatPada: DateTime(2026, 8, 4, 16),
    serviceName: 'Servis AC',
    customerName: 'Customer',
    customerAddress: 'Makassar',
    customerId: 'customer-1',
    category: 'Elektronik',
    serviceType: 'fixed',
    workerName: 'Worker',
    workerId: 'worker-1',
    quotedPrice: 100000,
    hasBeenReviewed: false,
    paymentStatus: 'paid',
    workStartSubmission: WorkStartSubmission(
      startedAt: DateTime(2026, 8, 4, 19),
      beforeEvidence: const [
        CompletionEvidence(
          url: 'https://example.test/before',
          originalName: 'before.jpg',
          contentType: 'image/jpeg',
          size: 100,
        ),
      ],
    ),
    completionSubmission: CompletionSubmission(
      note: 'Pekerjaan sudah selesai dan telah diuji.',
      submittedAt: DateTime(2026, 8, 4, 21),
      afterEvidence: const [
        CompletionEvidence(
          url: 'https://example.test/after',
          originalName: 'after.jpg',
          contentType: 'image/jpeg',
          size: 100,
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.invalid/api');
    await initializeDateFormatting('id_ID');
  });

  testWidgets(
    'konfirmasi memakai token baru dan status tetap completed saat GET gagal',
    (tester) async {
      // Sama dengan lebar logis emulator pada laporan regresi (328 px).
      tester.view.physicalSize = const Size(656, 1492);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final events = <String>[];
      final order = _completionSubmittedOrder();
      final api = _FakeApiService(order, events);
      final auth = _FakeAuthProvider(events);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            home: CustomerOrderDetailPage(
              initialOrder: order,
              apiService: api,
              enableRealtime: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.text('Konfirmasi Pekerjaan Selesai');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi pekerjaan selesai?'), findsOneWidget);
      await tester.tap(find.text('Ya, Konfirmasi'));
      await tester.pumpAndSettle();

      expect(events, ['refresh-token', 'confirm:token-baru']);
      expect(find.text('Konfirmasi Pekerjaan Selesai'), findsNothing);
      expect(
        find.text(
          'Pekerjaan selesai. Pendapatan langsung masuk ke saldo Worker.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('detail riwayat menampilkan dan mengirim tombol rating', (
    tester,
  ) async {
    final events = <String>[];
    final order = _completionSubmittedOrder().copyWith(status: 'completed');
    final api = _FakeApiService(order, events);
    final auth = _FakeAuthProvider(events);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: CustomerOrderDetailPage(
            initialOrder: order,
            apiService: api,
            enableRealtime: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('detail-review-button'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('review-star-5')));
    await tester.enterText(find.byType(TextField), 'Pekerjaan sangat rapi');
    await tester.tap(find.byKey(const ValueKey('submit-review-button')));
    await tester.pumpAndSettle();

    expect(events, ['review:token-lama:5:Pekerjaan sangat rapi']);
    expect(find.byKey(const ValueKey('detail-review-button')), findsNothing);
    expect(find.text('Terima kasih, ulasan berhasil dikirim.'), findsOneWidget);
  });
}
