class AppVersionPolicy {
  const AppVersionPolicy({
    required this.platform,
    required this.minimumBuild,
    required this.latestBuild,
    required this.minimumVersion,
    required this.message,
    required this.storeUrl,
  });

  static const String defaultStoreUrl =
      'https://play.google.com/store/apps/details?id=com.homeworkers.app';
  static const String defaultMessage =
      'Versi aplikasi Anda sudah tidak didukung. Silakan perbarui di Play Store.';

  final String platform;
  final int minimumBuild;
  final int latestBuild;
  final String minimumVersion;
  final String message;
  final String storeUrl;

  bool requiresUpdate(int currentBuild) {
    return minimumBuild > 0 && currentBuild < minimumBuild;
  }

  bool hasUpdate(int currentBuild) {
    return latestBuild > 0 && currentBuild < latestBuild;
  }

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    final platform = json['platform']?.toString().trim().toLowerCase() ?? '';
    final minimumBuild = _readBuild(json['minimumBuild']);
    final latestBuild = _readBuild(json['latestBuild']);
    final message = json['message']?.toString().trim() ?? '';
    final storeUrl = _safeStoreUrl(json['storeUrl']);

    if (platform != 'android') {
      throw const FormatException('Platform version policy tidak valid.');
    }

    return AppVersionPolicy(
      platform: platform,
      minimumBuild: minimumBuild,
      latestBuild: latestBuild > 0 && latestBuild < minimumBuild
          ? minimumBuild
          : latestBuild,
      minimumVersion: json['minimumVersion']?.toString().trim() ?? '',
      message: message.isEmpty ? defaultMessage : message,
      storeUrl: storeUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'minimumBuild': minimumBuild,
      'latestBuild': latestBuild,
      'minimumVersion': minimumVersion,
      'message': message,
      'storeUrl': storeUrl,
    };
  }

  static int _readBuild(dynamic value) {
    if (value is num && value != value.toInt()) {
      throw const FormatException('Build version policy tidak valid.');
    }
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0 || parsed > 2100000000) {
      throw const FormatException('Build version policy tidak valid.');
    }
    return parsed;
  }

  static String _safeStoreUrl(dynamic value) {
    final uri = Uri.tryParse(value?.toString().trim() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'play.google.com' ||
        uri.path != '/store/apps/details' ||
        uri.queryParameters['id'] != 'com.homeworkers.app') {
      return defaultStoreUrl;
    }
    return uri.toString();
  }
}
