// lib/features/customer_flow/dashboard/pages/customer_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/models/category_model.dart';
import 'package:home_workers_fe/core/models/performer_model.dart';
import 'package:home_workers_fe/features/customer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/category_services_page.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/pages/marketplace_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/state/auth_provider.dart';

class CustomerDashboardPage extends StatefulWidget {
  // Callback ke MainPage untuk pindah ke tab Orders
  final VoidCallback onNavigateToOrders;

  const CustomerDashboardPage({super.key, required this.onNavigateToOrders});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;

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
    setState(() {
      _dashboardFuture = _apiService.getCustomerDashboardSummary();
    });
    // Tunggu future selesai supaya RefreshIndicator berhenti setelah data baru didapat
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(
        0xFF1A374D,
      ), // gelap di belakang header lengkung
      body: SafeArea(
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                              padding: const EdgeInsets.symmetric(vertical: 80),
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
                              .where((p) => p.rating >= 4.5 && p.rating <= 5.0)
                              .toList()
                            ..sort((a, b) => b.rating.compareTo(a.rating));
                      final List<Performer> bestPerformers = filteredAndSorted
                          .take(5)
                          .toList();

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
        // ruang bawah cukup besar supaya user merasa bisa scroll "lewat" bottom nav
        bottom: MediaQuery.of(context).padding.bottom + 140,
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
        // safeAreaBottom + extra agar jelas bisa scroll sampai bawah
        bottom: MediaQuery.of(context).padding.bottom + 140,
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
        const SizedBox(height: 24),

        _buildSectionHeader("Best Performers", () {
          // TODO: implement "lihat semua performer"
        }),
        const SizedBox(height: 16),
        _buildPerformerList(bestPerformers),

        // ruang ekstra akhir (opsional, keamanan ganda)
        const SizedBox(height: 24),
      ],
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
      child: Column(
        children: [
          // Penyedia Jasa
          _ActionCard(
            key: _marketplaceKey,
            title: 'Penyedia Jasa',
            color: const Color(0xFFFFD465),
            icon: Icons.person_search_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MarketplacePage(),
                ),
              );
            },
            fontSize: _getResponsiveFontSize(context, 18),
            iconSize: _getResponsiveSpacing(context, 30),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),

          // Row 2
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  key: _ordersKey,
                  title: 'Riwayat Pesanan',
                  color: const Color(0xFF3A3F51),
                  icon: Icons.work_history_outlined,
                  textColor: Colors.white,
                  onTap: widget.onNavigateToOrders, // callback ke MainPage
                  fontSize: _getResponsiveFontSize(context, 16),
                  iconSize: _getResponsiveSpacing(context, 28),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 16)),
              Expanded(
                child: _ActionCard(
                  title: 'Cari Disekitar',
                  color: const Color(0xFFFE6E6E),
                  icon: Icons.location_on_outlined,
                  textColor: Colors.white,
                  onTap: () {
                    _showComingSoonDialog(context);
                  },
                  fontSize: _getResponsiveFontSize(context, 16),
                  iconSize: _getResponsiveSpacing(context, 28),
                ),
              ),
            ],
          ),
        ],
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

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 50,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fitur ini sedang dikembangkan dan akan segera tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE6E6E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Oke',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Action Card
// ---------------------------------------------------------------------------
class _ActionCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Color textColor;
  final VoidCallback onTap;
  final double? fontSize;
  final double? iconSize;

  const _ActionCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    this.textColor = Colors.black,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final baseFont = fontSize ?? 18;
        final baseIcon = iconSize ?? 30;
        final adjustedFont = isCompact ? (baseFont - 2) : baseFont;
        final adjustedIcon = isCompact ? (baseIcon - 4) : baseIcon;
        final padding = isCompact
            ? const EdgeInsets.all(14.0)
            : const EdgeInsets.all(20.0);

        Widget iconChip() {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: adjustedIcon, color: textColor),
          );
        }

        Widget titleText() {
          return Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: adjustedFont,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          );
        }

        return Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: padding,
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleText(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: iconChip(),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: titleText()),
                        iconChip(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
