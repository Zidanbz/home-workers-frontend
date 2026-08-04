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
      case TargetPlatform.iOS:
        return iosSandbox;
      default:
        return DefaultFirebaseOptions.currentPlatform;
    }
  }

  static String projectIdFor(String appEnv) {
    final normalizedEnv = appEnv.toLowerCase();
    if (normalizedEnv == 'sandbox' && !kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return androidSandbox.projectId;
        case TargetPlatform.iOS:
          return iosSandbox.projectId;
        default:
          break;
      }
    }
    return DefaultFirebaseOptions.currentPlatform.projectId;
  }

  static const FirebaseOptions androidSandbox = FirebaseOptions(
    apiKey: 'AIzaSyAtKZk2rjKe-43RMGCSwe2HaQqDjOl_uoc',
    appId: '1:132125085396:android:c5bc223718210931017541',
    messagingSenderId: '132125085396',
    projectId: 'howek-dev',
    storageBucket: 'howek-dev.firebasestorage.app',
  );

  static const FirebaseOptions iosSandbox = FirebaseOptions(
    apiKey: 'AIzaSyAvVOgHj9vjQt6a64YejH20ungAHuV3BSA',
    appId: '1:132125085396:ios:45e86576494f1b87017541',
    messagingSenderId: '132125085396',
    projectId: 'howek-dev',
    storageBucket: 'howek-dev.firebasestorage.app',
    iosBundleId: 'com.homeworkers.app',
  );
}
