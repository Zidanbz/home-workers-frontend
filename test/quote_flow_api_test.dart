import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
  });

  test('persetujuan quote mengirim harga yang dilihat Customer', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'success': true, 'message': 'OK'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await http.runWithClient(
      () => ApiService().respondToQuote(
        token: 'firebase-token',
        orderId: 'order-survey',
        decision: 'accept',
        expectedPrice: 10000,
      ),
      () => client,
    );

    expect(capturedRequest.method, 'PUT');
    expect(capturedRequest.url.path, '/api/orders/order-survey/quote/respond');
    expect(jsonDecode(capturedRequest.body), {
      'decision': 'accept',
      'expectedPrice': 10000,
    });
  });

  test('konflik revisi quote tidak disamarkan sebagai error jaringan', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'success': false,
          'message':
              'Penawaran hanya dapat dibuat atau diubah sebelum disetujui Customer.',
        }),
        409,
        headers: {'content-type': 'application/json'},
      ),
    );

    final request = http.runWithClient(
      () => ApiService().proposeQuote(
        token: 'firebase-token',
        orderId: 'order-survey',
        proposedPrice: 20000,
      ),
      () => client,
    );

    await expectLater(
      request,
      throwsA(
        isA<AppException>().having(
          (error) => error.toString(),
          'message',
          'Penawaran hanya dapat dibuat atau diubah sebelum disetujui Customer.',
        ),
      ),
    );
  });

  test(
    'permintaan revisi harga mengirim snapshot quote yang dilihat',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'OK'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(
        () => ApiService().requestQuoteRevision(
          token: 'firebase-token',
          orderId: 'order-survey',
          reason: 'Harga material perlu diperiksa ulang.',
          expectedPrice: 100000,
          expectedRevision: 2,
        ),
        () => client,
      );

      expect(capturedRequest.method, 'PUT');
      expect(
        capturedRequest.url.path,
        '/api/orders/order-survey/quote/revision-request',
      );
      expect(jsonDecode(capturedRequest.body), {
        'reason': 'Harga material perlu diperiksa ulang.',
        'expectedPrice': 100000,
        'expectedRevision': 2,
      });
    },
  );
}
