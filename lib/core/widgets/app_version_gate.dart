import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:home_workers_fe/core/models/app_version_policy.dart';
import 'package:home_workers_fe/core/services/app_version_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AppBuildNumberLoader = Future<int> Function();
typedef AppExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<int> _loadBuildNumber() async {
  final info = await PackageInfo.fromPlatform();
  final build = int.tryParse(info.buildNumber);
  if (build == null || build < 1) {
    throw const FormatException('Build aplikasi tidak valid.');
  }
  return build;
}

Future<bool> _launchExternalUrl(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({
    super.key,
    required this.child,
    this.versionRepository,
    this.buildNumberLoader,
    this.platformOverride,
    this.externalUrlLauncher,
    this.removeNativeSplash,
  });

  final Widget child;
  final AppVersionPolicyRepository? versionRepository;
  final AppBuildNumberLoader? buildNumberLoader;
  final String? platformOverride;
  final AppExternalUrlLauncher? externalUrlLauncher;
  final VoidCallback? removeNativeSplash;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  bool _loading = true;
  bool _forceUpdate = false;
  String _message = AppVersionPolicy.defaultMessage;
  String _storeUrl = AppVersionPolicy.defaultStoreUrl;

  bool _splashRemovedForBlock = false;
  late final AppVersionPolicyRepository _versionRepository;

  void _removeSplashForForceScreen() {
    if (_splashRemovedForBlock) return;
    _splashRemovedForBlock = true;
    final removeSplash = widget.removeNativeSplash;
    if (removeSplash != null) {
      removeSplash();
    } else {
      // preserve() menahan frame pertama. Menunggu post-frame callback di sini
      // dapat membuat layar wajib update selamanya tertutup native splash.
      FlutterNativeSplash.remove();
    }
  }

  @override
  void initState() {
    super.initState();
    _versionRepository = widget.versionRepository ?? AppVersionService();
    _evaluateVersion();
  }

  Future<void> _evaluateVersion() async {
    final platform =
        widget.platformOverride ?? (Platform.isAndroid ? 'android' : 'other');
    if (platform != 'android') {
      _applyAllowed();
      return;
    }

    AppVersionPolicy? cachedPolicy;
    int? currentBuild;
    try {
      currentBuild = await (widget.buildNumberLoader ?? _loadBuildNumber)();
      cachedPolicy = await _versionRepository.readCachedPolicy();

      if (cachedPolicy != null) {
        _applyPolicy(cachedPolicy, currentBuild);
      }

      final freshPolicy = await _versionRepository.fetchPolicy(
        platform: platform,
        currentBuild: currentBuild,
      );
      try {
        await _versionRepository.savePolicy(freshPolicy);
      } catch (_) {
        // Policy fresh tetap dipakai walaupun cache lokal gagal ditulis.
      }
      _applyPolicy(freshPolicy, currentBuild);
    } catch (_) {
      if (cachedPolicy != null && currentBuild != null) {
        _applyPolicy(cachedPolicy, currentBuild);
      } else {
        _applyAllowed();
      }
    }
  }

  void _applyPolicy(AppVersionPolicy policy, int currentBuild) {
    if (!mounted) return;
    final blocked = policy.requiresUpdate(currentBuild);
    setState(() {
      _message = policy.message;
      _storeUrl = policy.storeUrl;
      _forceUpdate = blocked;
      _loading = false;
    });
    if (blocked) _removeSplashForForceScreen();
  }

  void _applyAllowed() {
    if (!mounted) return;
    setState(() {
      _forceUpdate = false;
      _loading = false;
    });
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_storeUrl);
    try {
      final opened = await (widget.externalUrlLauncher ?? _launchExternalUrl)(
        uri,
      );
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka Play Store.')),
    );
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
