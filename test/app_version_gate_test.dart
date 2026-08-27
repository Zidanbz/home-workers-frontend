import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/app_version_policy.dart';
import 'package:home_workers_fe/core/services/app_version_service.dart';
import 'package:home_workers_fe/core/widgets/app_version_gate.dart';

class _FakeVersionRepository implements AppVersionPolicyRepository {
  _FakeVersionRepository({
    this.cachedPolicy,
    this.freshPolicy,
    this.fetchFuture,
    this.error,
  });

  final AppVersionPolicy? cachedPolicy;
  final AppVersionPolicy? freshPolicy;
  final Future<AppVersionPolicy>? fetchFuture;
  final Object? error;
  AppVersionPolicy? savedPolicy;

  @override
  Future<AppVersionPolicy?> readCachedPolicy() async => cachedPolicy;

  @override
  Future<AppVersionPolicy> fetchPolicy({
    required String platform,
    required int currentBuild,
  }) async {
    if (error != null) throw error!;
    if (fetchFuture != null) return fetchFuture!;
    return freshPolicy!;
  }

  @override
  Future<void> savePolicy(AppVersionPolicy policy) async {
    savedPolicy = policy;
  }
}

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.homeworkers.app';

AppVersionPolicy _policy({required int minimumBuild}) {
  return AppVersionPolicy(
    platform: 'android',
    minimumBuild: minimumBuild,
    latestBuild: minimumBuild,
    minimumVersion: '1.0.11',
    message: 'Pembaruan keamanan wajib.',
    storeUrl: _storeUrl,
  );
}

void main() {
  testWidgets('build lama diblokir oleh policy backend', (tester) async {
    final repository = _FakeVersionRepository(
      freshPolicy: _policy(minimumBuild: 25),
    );
    var splashRemovalCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionGate(
          versionRepository: repository,
          buildNumberLoader: () async => 24,
          platformOverride: 'android',
          removeNativeSplash: () => splashRemovalCount++,
          child: const Text('Aplikasi utama'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui aplikasi'), findsOneWidget);
    expect(find.text('Pembaruan keamanan wajib.'), findsOneWidget);
    expect(find.text('Aplikasi utama'), findsNothing);
    expect(repository.savedPolicy?.minimumBuild, 25);
    expect(splashRemovalCount, 1);
  });

  testWidgets('policy cache tetap memblokir saat backend gagal', (
    tester,
  ) async {
    final repository = _FakeVersionRepository(
      cachedPolicy: _policy(minimumBuild: 25),
      error: Exception('offline'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionGate(
          versionRepository: repository,
          buildNumberLoader: () async => 24,
          platformOverride: 'android',
          removeNativeSplash: () {},
          child: const Text('Aplikasi utama'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui aplikasi'), findsOneWidget);
    expect(find.text('Aplikasi utama'), findsNothing);
  });

  testWidgets('tanpa cache aplikasi tetap terbuka ketika backend gagal', (
    tester,
  ) async {
    final repository = _FakeVersionRepository(error: Exception('offline'));

    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionGate(
          versionRepository: repository,
          buildNumberLoader: () async => 24,
          platformOverride: 'android',
          removeNativeSplash: () {},
          child: const Text('Aplikasi utama'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aplikasi utama'), findsOneWidget);
    expect(find.text('Perbarui aplikasi'), findsNothing);
  });

  testWidgets('cache yang mengizinkan tidak menunggu respons jaringan', (
    tester,
  ) async {
    final pendingFetch = Completer<AppVersionPolicy>();
    final repository = _FakeVersionRepository(
      cachedPolicy: _policy(minimumBuild: 24),
      fetchFuture: pendingFetch.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionGate(
          versionRepository: repository,
          buildNumberLoader: () async => 24,
          platformOverride: 'android',
          removeNativeSplash: () {},
          child: const Text('Aplikasi utama'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Aplikasi utama'), findsOneWidget);

    pendingFetch.complete(_policy(minimumBuild: 24));
    await tester.pumpAndSettle();
  });
}
