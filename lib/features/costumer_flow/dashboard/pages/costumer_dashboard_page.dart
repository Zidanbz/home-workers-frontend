// Lokasi: lib/features/customer_flow/dashboard/pages/customer_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/models/category_model.dart';
import 'package:home_workers_fe/core/models/performer_model.dart';
import 'package:home_workers_fe/features/costumer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/category_services_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/marketplace_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/state/auth_provider.dart';

// ----------------------------------------------------

class CustomerDashboardPage extends StatefulWidget {
  // Callback untuk navigasi yang dikontrol oleh MainPage
  final VoidCallback onNavigateToOrders;

  const CustomerDashboardPage({super.key, required this.onNavigateToOrders});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _apiService.getCustomerDashboardSummary();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _apiService.getCustomerDashboardSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFF1A374D), // Background utama gelap
      body: SafeArea(
        bottom: false, // Agar background bisa sampai ke bawah
        child: Column(
          children: [
            // Bagian Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: _buildHeader(context, userName: user?.nama ?? 'Guest'),
            ),
            // Bagian Konten
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5), // Background konten terang
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: SingleChildScrollView(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            heightFactor: 10,
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Gagal memuat data: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Text('Tidak ada data.'));
                        }

                        final summaryData = snapshot.data!;
                        final List<Category> topCategories =
                            (summaryData['topCategories'] as List)
                                .map((c) => Category.fromJson(c))
                                .toList();
                        final List<Performer> bestPerformers =
                            (summaryData['bestPerformers'] as List)
                                .map((p) => Performer.fromJson(p))
                                .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActionCards(),
                            const SizedBox(height: 24),
                            _buildSectionHeader("Kategori Teratas", () {}),
                            const SizedBox(height: 16),
                            _buildCategoryList(topCategories),
                            const SizedBox(height: 24),
                            _buildSectionHeader("Best Performers", () {}),
                            const SizedBox(height: 16),
                            _buildPerformerList(bestPerformers),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required String userName}) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=49'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halo,',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CustomerChatListPage(),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Kartu Penyedia Jasa
          _ActionCard(
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
          ),
          const SizedBox(height: 16),
          // Dua kartu di bawah
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Riwayat Pesanan',
                  color: const Color(0xFF3A3F51),
                  icon: Icons.work_history_outlined,
                  textColor: Colors.white,
                  onTap:
                      widget.onNavigateToOrders, // Gunakan callback dari widget
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  title: 'Cari Disekitar',
                  color: const Color(0xFFFE6E6E),
                  icon: Icons.location_on_outlined,
                  textColor: Colors.white,
                  onTap: () {
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFE6E6E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'Oke',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: onViewMore,
            icon: const Icon(Icons.arrow_forward, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20.0),
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
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
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
                    category.icon, // tidak perlu mapping lagi, sudah di model
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    category.workerCount,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20.0),
        itemCount: performers.length,
        itemBuilder: (context, index) {
          final performer = performers[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      performer.avatarUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  performer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      performer.rating.toString(),
                      style: const TextStyle(color: Colors.grey),
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
}

// Widget helper untuk kartu aksi
class _ActionCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
