import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/firebase_env_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('sandbox memakai Firebase howek-dev pada iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final options = AppFirebaseOptions.forAppEnv('sandbox');

    expect(options.projectId, 'howek-dev');
    expect(options.appId, '1:132125085396:ios:45e86576494f1b87017541');
    expect(options.iosBundleId, 'com.homeworkers.app');
    expect(AppFirebaseOptions.projectIdFor('sandbox'), 'howek-dev');
  });

  test('production tetap memakai Firebase home-workers-fa5cd pada iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final options = AppFirebaseOptions.forAppEnv('prod');

    expect(options.projectId, 'home-workers-fa5cd');
    expect(options.appId, '1:891691718664:ios:577b7321221d4cc81459bd');
    expect(options.iosBundleId, 'com.homeworkers.app');
    expect(AppFirebaseOptions.projectIdFor('prod'), 'home-workers-fa5cd');
  });
}
