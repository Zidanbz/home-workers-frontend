// lib/features/customer_flow/dashboard/pages/customer_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_workers_fe/core/models/category_model.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';
import 'package:home_workers_fe/core/models/performer_model.dart';
import 'package:home_workers_fe/features/customer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/category_services_page.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/marketplace_page.dart';
import 'package:home_workers_fe/features/customer_flow/dashboard/widgets/customer_quick_actions.dart';
import 'package:home_workers_fe/features/customer_flow/dashboard/utils/customer_dashboard_layout.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/shared_widgets/content_video_section.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/state/auth_provider.dart';

class CustomerDashboardPage extends StatefulWidget {
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToNearbyWorkers;
  final double bottomNavigationClearance;

  const CustomerDashboardPage({
    super.key,
    required this.onNavigateToOrders,
    required this.onNavigateToNearbyWorkers,
    this.bottomNavigationClearance = 0,
  });

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;
  Future<List<ContentVideo>>? _contentVideosFuture;

  // Global keys for feature showcase
  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();
  final GlobalKey _marketplaceKey = GlobalKey();
  final GlobalKey _ordersKey = GlobalKey();

  // Helper method untuk responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.85; // Layar kecil
    } else if (screenWidth < 400) {
      return baseSize * 0.9; // Layar medium-small
    } else if (screenWidth > 600) {
      return baseSize * 1.1; // Layar besar
    }
    return baseSize; // Layar normal
  }

  // Helper method untuk responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSpacing * 0.8;
    } else if (screenWidth > 600) {
      return baseSpacing * 1.2;
    }
    return baseSpacing;
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _apiService.getCustomerDashboardSummary();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _contentVideosFuture = token == null
        ? Future.value(const <ContentVideo>[])
        : _apiService.getContentVideos(token);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAddressHintIfNeeded();
    });
  }

  Future<void> _showAddressHintIfNeeded() async {
    // Wait a bit more for UI to be fully ready
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.showAddressHintIfNeeded(context);
  }

  Future<void> _refreshDashboard() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final dashboardFuture = _apiService.getCustomerDashboardSummary();
    final contentVideosFuture = token == null
        ? Future.value(const <ContentVideo>[])
        : _apiService.getContentVideos(token);
    setState(() {
      _dashboardFuture = dashboardFuture;
      _contentVideosFuture = contentVideosFuture;
    });
    // Konten tambahan tidak boleh membuat refresh dashboard utama gagal.
    await dashboardFuture;
    try {
      await contentVideosFuture;
    } catch (_) {
      // FutureBuilder video menyembunyikan section jika request gagal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF12364D), Color(0xFF006879), Color(0xFF00968D)],
              stops: [0, 0.56, 1],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: _buildHeader(context, userName: user?.nama ?? 'Guest'),
                ),

                // KONTEN SCROLLABLE
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshDashboard,
                      // NOTE: kita taruh FutureBuilder langsung sebagai child dari RefreshIndicator
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _dashboardFuture,
                        builder: (context, snapshot) {
                          // --- LOADING STATE ---
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildScrollablePlaceholder(
                              context,
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          // --- ERROR STATE ---
                          if (snapshot.hasError) {
                            return _buildScrollablePlaceholder(
                              context,
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 80,
                                  ),
                                  child: Text(
                                    ApiService.readableError(
                                      snapshot.error,
                                      action: 'Gagal memuat data dashboard',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // --- NO DATA STATE ---
                          if (!snapshot.hasData) {
                            return _buildScrollablePlaceholder(
                              context,
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: Text('Tidak ada data.'),
                                ),
                              ),
                            );
                          }

                          // --- DATA STATE ---
                          final summaryData = snapshot.data!;
                          final List<Category> topCategories =
                              (summaryData['topCategories'] as List)
                                  .map((c) => Category.fromJson(c))
                                  .toList();
                          final List<Performer> allPerformers =
                              (summaryData['bestPerformers'] as List)
                                  .map((p) => Performer.fromJson(p))
                                  .toList();
                          // Filter rating 4.5–5.0, sort descending, take max 5
                          final List<Performer> filteredAndSorted =
                              allPerformers
                                  .where(
                                    (p) => p.rating >= 4.5 && p.rating <= 5.0,
                                  )
                                  .toList()
                                ..sort((a, b) => b.rating.compareTo(a.rating));
                          final List<Performer> bestPerformers =
                              filteredAndSorted.take(5).toList();

                          return _buildScrollableContent(
                            context,
                            topCategories: topCategories,
                            bestPerformers: bestPerformers,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membungkus konten kosong/placeholder ke ListView agar tetap scrollable
  Widget _buildScrollablePlaceholder(BuildContext context, Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: _bottomContentInset(context),
      ),
      children: [child],
    );
  }

  /// Konten utama yang benar-benar tampil saat data ada.
  Widget _buildScrollableContent(
    BuildContext context, {
    required List<Category> topCategories,
    required List<Performer> bestPerformers,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 0,
        left: 0,
        right: 0,
        bottom: _bottomContentInset(context),
      ),
      children: [
        // Action cards sudah punya padding internal sendiri
        _buildActionCards(),
        const SizedBox(height: 24),

        _buildSectionHeader("Kategori Teratas", () {
          // TODO: implement "lihat semua kategori" jika diperlukan
        }),
        const SizedBox(height: 16),
        _buildCategoryList(topCategories),

        _buildContentVideos(),

        _buildSectionHeader("Best Performers", () {
          // TODO: implement "lihat semua performer"
        }),
        const SizedBox(height: 16),
        _buildPerformerList(bestPerformers),
      ],
    );
  }

  Widget _buildContentVideos() {
    return FutureBuilder<List<ContentVideo>>(
      future: _contentVideosFuture,
      builder: (context, snapshot) {
        final videos = snapshot.data ?? const <ContentVideo>[];
        if (snapshot.hasError || videos.isEmpty) {
          return const SizedBox(height: 24);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            _getResponsiveSpacing(context, 20),
            28,
            _getResponsiveSpacing(context, 20),
            28,
          ),
          child: ContentVideoSection(videos: videos),
        );
      },
    );
  }

  double _bottomContentInset(BuildContext context) {
    return customerDashboardBottomInset(
      bottomNavigationClearance: widget.bottomNavigationClearance,
      safeAreaBottom: MediaQuery.viewPaddingOf(context).bottom,
    );
  }

  // ----------------------------------------------------
  // UI BUILDERS
  // ----------------------------------------------------

  Widget _buildHeader(BuildContext context, {required String userName}) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final avatarUrl = user?.avatarUrl?.trim() ?? '';
        final bool hasAvatar = avatarUrl.isNotEmpty;

        return Row(
          children: [
            CircleAvatar(
              radius: _getResponsiveSpacing(context, 20),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: !hasAvatar
                  ? Icon(
                      Icons.person,
                      size: _getResponsiveSpacing(context, 24),
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: _getResponsiveSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _getResponsiveFontSize(context, 12),
                    ),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              key: _notificationKey,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: _getResponsiveSpacing(context, 24),
              ),
            ),
            IconButton(
              key: _chatKey,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerChatListPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: _getResponsiveSpacing(context, 24),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSpacing(context, 20.0),
      ),
      child: CustomerQuickActions(
        marketplaceKey: _marketplaceKey,
        ordersKey: _ordersKey,
        onMarketplaceTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MarketplacePage()),
          );
        },
        onOrdersTap: widget.onNavigateToOrders,
        onNearbyTap: widget.onNavigateToNearbyWorkers,
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewMore) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSpacing(context, 20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          // IconButton(
          //   onPressed: onViewMore,
          //   // icon: const Icon(Icons.arrow_forward, color: Colors.grey),
          // ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSpacing(context, 20.0),
        ),
        child: Text(
          'Belum ada kategori.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: _getResponsiveFontSize(context, 14),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360 ? 130.0 : 150.0;

    return SizedBox(
      height: _getResponsiveSpacing(context, 130),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: _getResponsiveSpacing(context, 20.0)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryServicesPage(categoryName: category.name),
                ),
              );
            },
            child: Container(
              width: cardWidth,
              margin: EdgeInsets.only(
                right: _getResponsiveSpacing(context, 16),
              ),
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: Colors.deepPurple,
                    size: _getResponsiveSpacing(context, 30),
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 8)),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformerList(List<Performer> performers) {
    if (performers.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSpacing(context, 20.0),
        ),
        child: Text(
          'Belum ada performer.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: _getResponsiveFontSize(context, 14),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 360
        ? 130.0
        : (screenWidth < 400 ? 140.0 : 150.0);

    return SizedBox(
      height: _getResponsiveSpacing(context, 200),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: _getResponsiveSpacing(context, 20.0)),
        itemCount: performers.length,
        itemBuilder: (context, index) {
          final performer = performers[index];
          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: _getResponsiveSpacing(context, 16)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: performer.avatarUrl.isEmpty
                        ? _buildPerformerImageFallback()
                        : Image.network(
                            performer.avatarUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                _buildPerformerImageFallback(),
                          ),
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 8)),
                Text(
                  performer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: _getResponsiveSpacing(context, 16),
                    ),
                    SizedBox(width: _getResponsiveSpacing(context, 4)),
                    Text(
                      performer.rating.toString(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: _getResponsiveFontSize(context, 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformerImageFallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: _getResponsiveSpacing(context, 40),
        color: Colors.grey,
      ),
    );
  }
}
