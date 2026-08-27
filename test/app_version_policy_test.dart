import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/app_version_policy.dart';
import 'package:home_workers_fe/core/services/app_version_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storeUrl =
      'https://play.google.com/store/apps/details?id=com.homeworkers.app';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('policy membandingkan build minimum dan build terbaru', () {
    final policy = AppVersionPolicy.fromJson({
      'platform': 'android',
      'minimumBuild': 25,
      'latestBuild': 26,
      'minimumVersion': '1.0.11',
      'message': 'Pembaruan wajib.',
      'storeUrl': storeUrl,
    });

    expect(policy.requiresUpdate(24), isTrue);
    expect(policy.requiresUpdate(25), isFalse);
    expect(policy.hasUpdate(25), isTrue);
    expect(policy.hasUpdate(26), isFalse);
  });

  test('URL selain Play Store resmi tidak dipercaya', () {
    final policy = AppVersionPolicy.fromJson({
      'platform': 'android',
      'minimumBuild': 0,
      'latestBuild': 0,
      'message': 'Update.',
      'storeUrl': 'https://example.com/app.apk',
    });

    expect(policy.storeUrl, AppVersionPolicy.defaultStoreUrl);
  });

  test(
    'service membaca endpoint publik dan menyimpan cache per environment',
    () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'platform': 'android',
              'minimumBuild': 25,
              'latestBuild': 26,
              'minimumVersion': '1.0.11',
              'message': 'Pembaruan wajib.',
              'storeUrl': storeUrl,
            },
          }),
          200,
        );
      });
      final service = AppVersionService(
        baseUrl: 'https://dev.example.com/api/',
        client: client,
      );

      final policy = await service.fetchPolicy(
        platform: 'android',
        currentBuild: 24,
      );
      await service.savePolicy(policy);

      expect(requestedUri.path, '/api/app/version-policy');
      expect(requestedUri.queryParameters['platform'], 'android');
      expect(requestedUri.queryParameters['build'], '24');
      expect((await service.readCachedPolicy())?.minimumBuild, 25);

      final otherEnvironment = AppVersionService(
        baseUrl: 'https://prod.example.com/api',
        client: client,
      );
      expect(await otherEnvironment.readCachedPolicy(), isNull);
    },
  );
}
