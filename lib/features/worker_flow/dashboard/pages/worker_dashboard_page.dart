import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/chat/pages/chat_list_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/features/worker_flow/wallet/worker_wallet_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/state/auth_provider.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  final ApiService _apiService = ApiService();
  Future<Map<String, dynamic>>? _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _summaryFuture = _apiService.getDashboardSummary(authProvider.token!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, userName: user.nama),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 24),

                      // Gunakan FutureBuilder untuk menampilkan data ringkasan
                      FutureBuilder<Map<String, dynamic>>(
                        future: _summaryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              heightFactor: 5,
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Gagal memuat data: ${snapshot.error}',
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text('Tidak ada data ringkasan.'),
                            );
                          }

                          final summaryData = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActionCards(summaryData),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                "Daftar Pesanan Selesai",
                                () {},
                              ),
                              const SizedBox(height: 16),
                              _buildCompletedOrdersList(
                                summaryData['completedOrdersCount'] ?? 0,
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader("Daftar Review", () {}),
                              const SizedBox(height: 16),
                              _buildReviewList(),
                            ],
                          );
                        },
                      ),
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

  // WIDGET UNTUK BAGIAN HEADER
  Widget _buildHeader(BuildContext context, {required String userName}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PERUBAHAN UTAMA: Tampilkan nama pengguna asli ---
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Makassar',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    // Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkerWalletPage(),
                  ),
                );
              },
              // Ganti ikon agar lebih sesuai
              icon: const Icon(Icons.account_balance_wallet_outlined)
            ),
            IconButton(
                            onPressed: () {
                // --- PERUBAHAN UTAMA ---
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ChatListPage()),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ],
        ),
      ],
    );
  }

  // WIDGET UNTUK SEARCH BAR
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF3A3F51),
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // WIDGET UNTUK 3 KARTU AKSI UTAMA
  Widget _buildActionCards(Map<String, dynamic> summary) {
    int pendingOrders = summary['pendingOrdersCount'] ?? 0;

    return Column(
      children: [
        Card(
          color: const Color(0xFFFFD465),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Tampilkan jumlah pesanan baru
                      if (pendingOrders > 0)
                        Text(
                          '$pendingOrders pesanan baru menunggu',
                          style: const TextStyle(fontSize: 14),
                        )
                      else
                        const Text(
                          'Tidak ada pesanan baru',
                          style: TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 30),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          // ... (UI untuk kartu Kelola Pekerjaan & Peta Pesanan)
        ),
      ],
    );
  }

  // WIDGET UNTUK JUDUL SEPERTI "Daftar Pesanan Selesai"
  Widget _buildSectionHeader(String title, VoidCallback onViewMore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: onViewMore,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  // WIDGET UNTUK LIST HORIZONTAL PESANAN SELESAI
  Widget _buildCompletedOrdersList(int completedCount) {
    // Untuk saat ini, kita hanya menampilkan totalnya di satu kartu
    // Nantinya bisa dipecah per kategori jika backend mendukung
    final categories = [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Total Selesai',
        'count': completedCount,
      },
      {
        'icon': Icons.construction,
        'title': 'Perbaikan & Konstruksi',
        'count': 0,
      }, // Contoh
      {
        'icon': Icons.computer,
        'title': 'Bantuan Komputer',
        'count': 0,
      }, // Contoh
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: Colors.blue,
                  size: 30,
                ),
                const Spacer(),
                Text(
                  category['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${category['count']} Selesai',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET UNTUK LIST REVIEW
  Widget _buildReviewList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=11',
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KaiB', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '22 Jul',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < 4 ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'KaiB was amazing with our cats!! 😼😽 This was our first time using a pet-sitting service, so we were naturally quite anxious. We took a chance on Kai and completely lucked out!...',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Read More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
