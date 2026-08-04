import 'package:flutter/material.dart';

class FeatureShowcase {
  static const String featureBookmark = 'bookmark';
  static const String featureVoucher = 'voucher';
  static const String featureChat = 'chat';
  static const String featureNotification = 'notification';
  static const String featureSearch = 'search';
  static const String featureFilter = 'filter';
  static const String featureProfile = 'profile';
  static const String featureOrders = 'orders';

  static Future<bool> shouldShowFeatureHint(String featureId) async => false;

  static Future<void> markFeatureHintShown(String featureId) async {}

  static Future<void> showFeatureTooltip({
    required BuildContext context,
    required String featureId,
    required String title,
    required String description,
    required GlobalKey targetKey,
    TooltipPosition position = TooltipPosition.bottom,
    VoidCallback? onNext,
  }) async {}

  static Future<void> showFeatureSequence({
    required BuildContext context,
    required List<FeatureStep> steps,
  }) async {}
}

class FeatureStep {
  final String featureId;
  final String title;
  final String description;
  final GlobalKey targetKey;
  final TooltipPosition position;

  FeatureStep({
    required this.featureId,
    required this.title,
    required this.description,
    required this.targetKey,
    this.position = TooltipPosition.bottom,
  });
}

enum TooltipPosition { top, bottom, left, right }

class ShowcaseWidget extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final String featureId;

  const ShowcaseWidget({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    required this.featureId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(key: showcaseKey, child: child);
  }
}

class FeatureDescriptions {
  static const Map<String, Map<String, String>> descriptions = {
    FeatureShowcase.featureBookmark: {
      'title': 'Bookmark Layanan',
      'description': 'Simpan layanan favorit Anda untuk akses cepat.',
    },
    FeatureShowcase.featureVoucher: {
      'title': 'Voucher Diskon',
      'description': 'Gunakan voucher untuk mendapatkan diskon.',
    },
    FeatureShowcase.featureChat: {
      'title': 'Chat dengan Worker',
      'description': 'Komunikasi langsung dengan worker.',
    },
    FeatureShowcase.featureNotification: {
      'title': 'Notifikasi',
      'description': 'Dapatkan update terbaru.',
    },
    FeatureShowcase.featureSearch: {
      'title': 'Pencarian Layanan',
      'description': 'Cari layanan yang Anda butuhkan.',
    },
    FeatureShowcase.featureFilter: {
      'title': 'Filter & Sorting',
      'description': 'Saring layanan untuk menemukan yang terbaik.',
    },
    FeatureShowcase.featureProfile: {
      'title': 'Profil Anda',
      'description': 'Kelola informasi pribadi dan alamat.',
    },
    FeatureShowcase.featureOrders: {
      'title': 'Riwayat Pesanan',
      'description': 'Lihat semua pesanan Anda.',
    },
  };

  static String getTitle(String featureId) {
    return descriptions[featureId]?['title'] ?? 'Fitur';
  }

  static String getDescription(String featureId) {
    return descriptions[featureId]?['description'] ?? '';
  }
}
