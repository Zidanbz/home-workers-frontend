import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'firebase_options.dart';

class AppFirebaseOptions {
  static FirebaseOptions forAppEnv(String appEnv) {
    final normalizedEnv = appEnv.toLowerCase();
    final isSandbox = normalizedEnv == 'sandbox';

    if (!isSandbox) {
      return DefaultFirebaseOptions.currentPlatform;
    }

    if (kIsWeb) {
      return DefaultFirebaseOptions.currentPlatform;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidSandbox;
      default:
        return DefaultFirebaseOptions.currentPlatform;
    }
  }

  static String projectIdFor(String appEnv) {
    final normalizedEnv = appEnv.toLowerCase();
    if (normalizedEnv == 'sandbox' &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      return androidSandbox.projectId;
    }
    return DefaultFirebaseOptions.currentPlatform.projectId;
  }

  static const FirebaseOptions androidSandbox = FirebaseOptions(
    apiKey: 'AIzaSyAtKZk2rjKe-43RMGCSwe2HaQqDjOl_uoc',
    appId: '1:132125085396:android:975700e2095b2e65017541',
    messagingSenderId: '132125085396',
    projectId: 'howek-dev',
    storageBucket: 'howek-dev.firebasestorage.app',
  );
}
