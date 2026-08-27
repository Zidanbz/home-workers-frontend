import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/worker_flow/wallet/worker_withdraw_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
  });

  test('withdrawal e-wallet mengirim kontrak tujuan yang lengkap', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'message': 'OK', 'data': null}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await http.runWithClient(
      () => ApiService().requestWithdraw(
        token: 'firebase-token',
        amount: 50000,
        destinationType: 'ewallet',
        institutionName: 'DANA',
        accountNumber: '08290192833',
        accountName: 'Budi Santoso',
      ),
      () => client,
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/wallet/me/withdraw');
    expect(capturedRequest.headers['authorization'], 'Bearer firebase-token');
    expect(jsonDecode(capturedRequest.body), {
      'amount': 50000,
      'destination': {
        'type': 'ewallet',
        'provider': 'DANA',
        'accountNumber': '08290192833',
        'accountName': 'Budi Santoso',
      },
    });
  });

  test('penolakan backend tidak diubah menjadi error koneksi', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'success': false,
          'message': 'Validation Error',
          'errors': [
            'Bank/provider, account number, and account name are required.',
          ],
        }),
        400,
        headers: {'content-type': 'application/json'},
      ),
    );

    final request = http.runWithClient(
      () => ApiService().requestWithdraw(
        token: 'firebase-token',
        amount: 50000,
        destinationType: 'bank',
        institutionName: '',
        accountNumber: '',
        accountName: '',
      ),
      () => client,
    );

    await expectLater(
      request,
      throwsA(
        isA<AppException>().having(
          (error) => error.toString(),
          'message',
          'Bank/provider, nomor tujuan, dan nama pemilik wajib diisi.',
        ),
      ),
    );
  });

  test(
    'kegagalan transport tetap ditampilkan sebagai masalah koneksi',
    () async {
      final client = MockClient(
        (request) async => throw http.ClientException('connection refused'),
      );

      final request = http.runWithClient(
        () => ApiService().requestWithdraw(
          token: 'firebase-token',
          amount: 50000,
          destinationType: 'bank',
          institutionName: 'BCA',
          accountNumber: '1234567890',
          accountName: 'Budi Santoso',
        ),
        () => client,
      );

      await expectLater(
        request,
        throwsA(
          isA<AppException>().having(
            (error) => error.toString(),
            'message',
            'Gagal terhubung ke server. Periksa koneksi internet Anda.',
          ),
        ),
      );
    },
  );

  testWidgets('form meminta seluruh data tujuan withdrawal', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(initializeOnCreate: false),
        child: const MaterialApp(home: WorkerWithdrawPage()),
      ),
    );

    expect(find.text('Nama Bank'), findsOneWidget);
    expect(find.text('Nomor Rekening Bank'), findsOneWidget);
    expect(find.text('Nama Pemilik'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('E-Wallet').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Provider E-Wallet'), findsOneWidget);
    expect(find.text('Nomor E-Wallet'), findsOneWidget);
  });
}
