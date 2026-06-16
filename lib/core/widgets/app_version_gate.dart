import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Harus sama dengan `applicationId` di android/app/build.gradle.kts
const String _androidPackageId = 'com.homeworkers.app';

/// Remote Config (Number): jika > 0, Android dengan buildNumber < nilai ini wajui update.
/// Build number = angka setelah `+` di pubspec, contoh 1.0.2+13 → 13.
const String _rcMinBuildAndroid = 'force_update_min_build_android';

/// Remote Config (String): opsional, mengganti teks penjelasan.
const String _rcUpdateMessage = 'force_update_message';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  bool _loading = true;
  bool _forceUpdate = false;
  String _message =
      'Versi aplikasi Anda sudah tidak didukung. Silakan perbarui di Play Store.';

  bool _splashRemovedForBlock = false;

  void _removeSplashForForceScreen() {
    if (_splashRemovedForBlock) return;
    _splashRemovedForBlock = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    _evaluateVersion();
  }

  Future<void> _evaluateVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await rc.setDefaults(const {
        _rcMinBuildAndroid: 0,
        _rcUpdateMessage: '',
      });

      await rc.fetchAndActivate();

      final minBuild = rc.getInt(_rcMinBuildAndroid);
      final remoteMsg = rc.getString(_rcUpdateMessage).trim();

      if (remoteMsg.isNotEmpty) {
        _message = remoteMsg;
      }

      final blocked =
          Platform.isAndroid && minBuild > 0 && currentBuild < minBuild;

      if (!mounted) return;
      setState(() {
        _forceUpdate = blocked;
        _loading = false;
      });

      if (blocked) {
        _removeSplashForForceScreen();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _forceUpdate = false;
        _loading = false;
      });
    }
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_androidPackageId',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (_forceUpdate) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Perbarui aplikasi',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _openPlayStore,
                    icon: const Icon(Icons.shop),
                    label: const Text('Buka Play Store'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
