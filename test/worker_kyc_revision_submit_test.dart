import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/kyc_revision_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/auth/pages/worker_kyc_revision_page.dart';
import 'package:provider/provider.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this.events, {this.hangOnLogout = false})
    : super(initializeOnCreate: false);

  final List<String> events;
  final bool hangOnLogout;

  @override
  String? get token => 'test-token';

  @override
  Future<void> logout() {
    events.add('logout');
    if (hangOnLogout) return Completer<void>().future;
    return Future<void>.value();
  }
}

class _FakeApiService extends ApiService {
  _FakeApiService(this.events);

  final List<String> events;

  @override
  Future<KycRevisionStatus> getMyKycRevision(String token) async {
    return const KycRevisionStatus(
      status: 'revision_required',
      canAccessApp: false,
      revisionCount: 1,
      review: KycReview(
        id: 'review-1',
        version: 1,
        status: 'revision_required',
        corrections: [
          KycCorrection(
            field: 'portfolio',
            reasonCode: 'INACCESSIBLE',
            note: '',
          ),
        ],
      ),
    );
  }

  @override
  Future<void> resubmitMyKycRevision({
    required String token,
    required int reviewVersion,
    File? ktpFile,
    File? selfieFile,
    String? portfolioLink,
  }) async {
    expect(portfolioLink, 'https://example.com/portfolio');
    events.add('submit');
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.invalid/api');
  });

  testWidgets('submit revisi sukses langsung kembali ke login', (tester) async {
    final events = <String>[];
    final auth = _FakeAuthProvider(events, hangOnLogout: true);
    final api = _FakeApiService(events);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(home: WorkerKycRevisionPage(apiService: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'https://example.com/portfolio',
    );
    await tester.tap(find.text('Kirim Perbaikan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(events, ['submit', 'logout']);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(WorkerKycRevisionPage), findsNothing);
  });

  testWidgets('tombol logout langsung kembali ke login', (tester) async {
    final events = <String>[];
    final auth = _FakeAuthProvider(events, hangOnLogout: true);
    final api = _FakeApiService(events);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(home: WorkerKycRevisionPage(apiService: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(events, ['logout']);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(WorkerKycRevisionPage), findsNothing);
  });
}
