import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/features/worker_flow/dashboard/widgets/worker_dashboard_overview.dart';
import 'package:home_workers_fe/features/worker_flow/dashboard/widgets/worker_review_section.dart';
import 'package:home_workers_fe/features/worker_flow/wallet/worker_wallet_page.dart';
import 'package:home_workers_fe/shared_widgets/content_loading_skeleton.dart';
import 'package:home_workers_fe/shared_widgets/content_video_section.dart';
import 'package:provider/provider.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key, this.bottomNavigationClearance = 0});

  final double bottomNavigationClearance;

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  static const _navy = Color(0xFF12364D);
  static const _teal = Color(0xFF00897B);
  static const _surface = Color(0xFFF5F7F8);

  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>>? _summaryFuture;
  Future<List<ContentVideo>>? _contentVideosFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null || token.isEmpty) {
      final summaryFuture = Future<Map<String, dynamic>>.error(
        Exception('Sesi Anda sudah berakhir. Silakan masuk kembali.'),
      );
      if (mounted) {
        setState(() {
          _summaryFuture = summaryFuture;
          _contentVideosFuture = Future.value(const <ContentVideo>[]);
        });
      }
      try {
        await summaryFuture;
      } catch (_) {
        // FutureBuilder menampilkan pesan sesi pada area konten.
      }
      return;
    }

    final summaryFuture = _apiService.getDashboardSummary(token);
    final contentVideosFuture = _apiService.getContentVideos(token);
    if (mounted) {
      setState(() {
        _summaryFuture = summaryFuture;
        _contentVideosFuture = contentVideosFuture;
      });
    }

    try {
      await summaryFuture;
    } catch (_) {
      // Error dashboard ditampilkan oleh FutureBuilder utama.
    }
    try {
      await contentVideosFuture;
    } catch (_) {
      // Konten tambahan tidak boleh menggagalkan dashboard utama.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: _navy,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: _navy,
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: _teal,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(
                        context,
                        name: user.nama,
                        avatarUrl: user.avatarUrl,
                      ),
                      _buildDashboardBody(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String name,
    required String? avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF006879), Color(0xFF00897B)],
          stops: [0, 0.62, 1],
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(avatarUrl),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name.trim().isEmpty ? 'Worker' : name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Mitra Home Workers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildHeaderAction(
            tooltip: 'Wallet',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WorkerWalletPage())),
          ),
          const SizedBox(width: 8),
          _buildHeaderAction(
            tooltip: 'Notifikasi',
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    final normalizedUrl = avatarUrl?.trim() ?? '';
    final uri = Uri.tryParse(normalizedUrl);
    final hasSafeAvatar =
        uri?.scheme == 'https' && uri?.host.isNotEmpty == true;
    const fallback = ColoredBox(
      color: Color(0xFFE8EFF2),
      child: Center(
        child: Icon(Icons.person_rounded, color: Color(0xFF607D8B), size: 28),
      ),
    );

    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2912364D),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: hasSafeAvatar
            ? Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _buildHeaderAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 43,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(BuildContext context) {
    final bottomInset =
        widget.bottomNavigationClearance.clamp(0, 300).toDouble() +
        MediaQuery.viewPaddingOf(context).bottom +
        24;

    return Container(
      key: const ValueKey('worker-dashboard-content'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoadingState();
          }
          if (snapshot.hasError) {
            return _buildErrorState(
              ApiService.readableError(
                snapshot.error,
                action: 'Gagal memuat dashboard',
              ),
            );
          }
          final summary = snapshot.data;
          if (summary == null) return _buildEmptyState();
          return _buildLoadedContent(summary);
        },
      ),
    );
  }

  Widget _buildLoadedContent(Map<String, dynamic> summary) {
    final rawWorker = summary['worker'];
    final worker = rawWorker is Map
        ? Map<String, dynamic>.from(rawWorker)
        : const <String, dynamic>{};
    final rawReviews = summary['reviews'];
    final reviews = rawReviews is List ? rawReviews : const <dynamic>[];
    final operationalArea = worker['operationalAreaLabel']?.toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkerDashboardOverview(
          pendingOrders: _asNonNegativeInt(summary['pendingOrdersCount']),
          acceptedOrders: _asNonNegativeInt(summary['acceptedOrdersCount']),
          completedOrders: _asNonNegativeInt(summary['completedOrdersCount']),
          rating: _asRating(summary['ratingAverage']),
          operationalArea: operationalArea,
        ),
        _buildContentVideos(),
        const SizedBox(height: 30),
        WorkerReviewSection(reviews: reviews),
      ],
    );
  }

  Widget _buildContentVideos() {
    return FutureBuilder<List<ContentVideo>>(
      future: _contentVideosFuture,
      builder: (context, snapshot) {
        final videos = snapshot.data ?? const <ContentVideo>[];
        if (snapshot.hasError || videos.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 30),
          child: ContentVideoSection(videos: videos),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const ContentLoadingSkeleton(
      variant: ContentSkeletonVariant.dashboard,
      scrollable: false,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFC62828),
            size: 38,
          ),
          const SizedBox(height: 12),
          const Text(
            'Dashboard belum dapat dimuat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8E2020),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9F4747),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EAED)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF78909C), size: 38),
          SizedBox(height: 10),
          Text(
            'Belum ada data aktivitas',
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  int _asNonNegativeInt(dynamic value) {
    final number = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return number < 0 ? 0 : number;
  }

  double _asRating(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return number.clamp(0, 5).toDouble();
  }
}
