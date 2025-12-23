import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureShowcase {
  static const String _keyFeatureHints = 'feature_hints_shown';

  // Feature IDs untuk tracking
  static const String featureBookmark = 'bookmark';
  static const String featureVoucher = 'voucher';
  static const String featureChat = 'chat';
  static const String featureNotification = 'notification';
  static const String featureSearch = 'search';
  static const String featureFilter = 'filter';
  static const String featureProfile = 'profile';
  static const String featureOrders = 'orders';

  /// Check if feature hint should be shown
  static Future<bool> shouldShowFeatureHint(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownFeatures = prefs.getStringList(_keyFeatureHints) ?? [];
    return !shownFeatures.contains(featureId);
  }

  /// Mark feature hint as shown
  static Future<void> markFeatureHintShown(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownFeatures = prefs.getStringList(_keyFeatureHints) ?? [];
    if (!shownFeatures.contains(featureId)) {
      shownFeatures.add(featureId);
      await prefs.setStringList(_keyFeatureHints, shownFeatures);
    }
  }

  /// Show feature tooltip
  static Future<void> showFeatureTooltip({
    required BuildContext context,
    required String featureId,
    required String title,
    required String description,
    required GlobalKey targetKey,
    TooltipPosition position = TooltipPosition.bottom,
    VoidCallback? onNext,
  }) async {
    if (!await shouldShowFeatureHint(featureId)) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (context) => FeatureTooltipOverlay(
          targetKey: targetKey,
          title: title,
          description: description,
          position: position,
          onNext: () {
            Navigator.of(context).pop();
            onNext?.call();
          },
          onSkip: () {
            Navigator.of(context).pop();
          },
        ),
      );

      await markFeatureHintShown(featureId);
    }
  }

  /// Show feature showcase sequence
  static Future<void> showFeatureSequence({
    required BuildContext context,
    required List<FeatureStep> steps,
  }) async {
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (await shouldShowFeatureHint(step.featureId)) {
        if (context.mounted) {
          await showFeatureTooltip(
            context: context,
            featureId: step.featureId,
            title: step.title,
            description: step.description,
            targetKey: step.targetKey,
            position: step.position,
            onNext: i < steps.length - 1 ? () {} : null,
          );
        }
      }
    }
  }
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

class FeatureTooltipOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TooltipPosition position;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const FeatureTooltipOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.position,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<FeatureTooltipOverlay> createState() => _FeatureTooltipOverlayState();
}

class _FeatureTooltipOverlayState extends State<FeatureTooltipOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Smooth fade in without bounce
// _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
//   CurvedAnimation(parent: _animationController, curve: Curves.linear),
// );



    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // No pulse animation - keep it static
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

WidgetsBinding.instance.addPostFrameCallback((_) {
  Future.delayed(const Duration(milliseconds: 50), () {
    _getTargetRect();
    _animationController.forward();
    setState(() {});
  });
});
}

  void _getTargetRect() {
    final RenderBox? renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);

        _targetRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );

    }
  }

  // void _startPulseAnimation() {
  //   _animationController.repeat(reverse: true);
  // }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dark overlay
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // Highlight circle around target
              if (_targetRect != null)
                Positioned(
                  left: _targetRect!.left - 8,
                  top: _targetRect!.top - 8,
                  child: Container(
                    width: _targetRect!.width + 16,
                    height: _targetRect!.height + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

              // Tooltip
              if (_targetRect != null)
                Positioned(
                  left: _getTooltipLeft(),
                  top: _getTooltipTop(),
                  child: FadeTransition(
  opacity: _fadeAnimation,
  child: _buildTooltip(),
),
                ),
            ],
          ),
        );
      },
    );
  }

  double _getTooltipLeft() {
    if (_targetRect == null) return 0;

    final screenWidth = MediaQuery.of(context).size.width;
    double left;

    switch (widget.position) {
      case TooltipPosition.left:
        left = _targetRect!.left - 320;
        break;
      case TooltipPosition.right:
        left = _targetRect!.right + 20;
        break;
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        left = (_targetRect!.left + _targetRect!.width / 2) - 150;
        break;
    }

    // Clamp left to keep tooltip fully visible within screen
    left = left.clamp(16.0, screenWidth - 300 - 16.0);

    return left;
  }

  double _getTooltipTop() {
    if (_targetRect == null) return 0;

    final screenHeight = MediaQuery.of(context).size.height;
    double top;

    switch (widget.position) {
      case TooltipPosition.top:
        top = _targetRect!.top - 180;
        break;
      case TooltipPosition.bottom:
        top = _targetRect!.bottom + 20;
        break;
      case TooltipPosition.left:
      case TooltipPosition.right:
        top = (_targetRect!.top + _targetRect!.height / 2) - 90;
        break;
    }

    // Clamp top to keep tooltip fully visible within screen
    top = top.clamp(16.0, screenHeight - 180 - 16.0);

    return top;
  }

  Widget _buildTooltip() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6C63FF), const Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.close, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: const Text('Lewati'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget untuk menandai elemen yang bisa di-showcase
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

// Predefined feature descriptions
class FeatureDescriptions {
  static const Map<String, Map<String, String>> descriptions = {
    FeatureShowcase.featureBookmark: {
      'title': 'Bookmark Layanan',
      'description':
          'Simpan layanan favorit Anda untuk akses cepat di kemudian hari. Tap ikon bookmark untuk menyimpan!',
    },
    FeatureShowcase.featureVoucher: {
      'title': 'Voucher Diskon',
      'description':
          'Gunakan voucher untuk mendapatkan diskon menarik. Pilih voucher sebelum melakukan pembayaran!',
    },
    FeatureShowcase.featureChat: {
      'title': 'Chat dengan Worker',
      'description':
          'Komunikasi langsung dengan worker untuk membahas detail pekerjaan sebelum booking.',
    },
    FeatureShowcase.featureNotification: {
      'title': 'Notifikasi',
      'description':
          'Dapatkan update terbaru tentang pesanan, promo, dan informasi penting lainnya.',
    },
    FeatureShowcase.featureSearch: {
      'title': 'Pencarian Layanan',
      'description':
          'Cari layanan yang Anda butuhkan dengan mudah menggunakan kata kunci atau kategori.',
    },
    FeatureShowcase.featureFilter: {
      'title': 'Filter & Sorting',
      'description':
          'Saring layanan berdasarkan harga, rating, atau kategori untuk menemukan yang terbaik.',
    },
    FeatureShowcase.featureProfile: {
      'title': 'Profil Anda',
      'description':
          'Kelola informasi pribadi, alamat, dan pengaturan akun Anda di sini.',
    },
    FeatureShowcase.featureOrders: {
      'title': 'Riwayat Pesanan',
      'description':
          'Lihat semua pesanan Anda, status terkini, dan berikan rating untuk layanan yang sudah selesai.',
    },
  };

  static String getTitle(String featureId) {
    return descriptions[featureId]?['title'] ?? 'Fitur Baru';
  }

  static String getDescription(String featureId) {
    return descriptions[featureId]?['description'] ??
        'Fitur baru yang dapat membantu Anda.';
  }
}
