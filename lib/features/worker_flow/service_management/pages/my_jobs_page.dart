// Lokasi: lib/features/worker_flow/service_management/pages/my_jobs_page.dart

import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/worker_flow/service_management/pages/edit_job_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';
import 'job_detail_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Gunakan FutureBuilder sebagai sumber data utama
  late Future<List<Service>> _myServicesFuture;

  // State untuk menyimpan query pencarian
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Panggil _loadServices sekali saat halaman dimuat
    _loadServices();

    // Tambahkan listener untuk memperbarui UI saat ada perubahan teks pencarian
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  // Fungsi ini sekarang hanya bertugas memicu pemanggilan API baru
  Future<void> _loadServices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      if (mounted) {
        setState(() {
          _myServicesFuture = _apiService.getMyServices(authProvider.token!);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Kelola Pekerjaan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.notifications_outlined),
        //   ),
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.chat_bubble_outline),
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchAndAddButtons(),
            const SizedBox(height: 24),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadServices,
                child: FutureBuilder<List<Service>>(
                  future: _myServicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Anda belum memiliki layanan.'),
                      );
                    }

                    // Lakukan filter langsung pada data dari snapshot
                    final allServices = snapshot.data!;
                    final filteredServices = allServices.where((service) {
                      return service.namaLayanan.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                    if (filteredServices.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada layanan yang cocok dengan pencarian.',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        return _JobCard(
                          service: filteredServices[index],
                          onActionComplete:
                              _loadServices, // Kirim fungsi refresh
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndAddButtons() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pekerjaan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const CreateEditJobPage(),
              ),
            );
            if (result == true) {
              _loadServices(); // Refresh setelah menambah
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E232C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final Service service;
  final VoidCallback onActionComplete;

  const _JobCard({required this.service, required this.onActionComplete});

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'kebersihan':
        return Icons.cleaning_services_outlined;
      case 'perbaikan':
        return Icons.build_outlined;
      case 'konstruksi':
        return Icons.construction_outlined;
      case 'layanan elektronik':
        return Icons.electrical_services_outlined;
      default:
        return Icons.work_outline;
    }
  }

  Color _getPriceColor() {
    return service.tipeLayanan == 'survey' ? Colors.orange : Colors.deepPurple;
  }

  String _getPaymentText() {
    return service.metodePembayaran == 'cash' ? 'Tunai' : 'Cashless';
  }

  IconData _getPaymentIcon() {
    return service.metodePembayaran == 'cash' ? Icons.money : Icons.credit_card;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => JobDetailPage(serviceId: service.id),
            ),
          );
          if (result == true) onActionComplete();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Foto
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service.fotoUtamaUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama & Kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.namaLayanan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForCategory(service.category),
                            color: Colors.deepPurple,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.category,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                    const SizedBox(height: 8),

                    // Harga atau biaya survei
                    Text(
                      service.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getPriceColor(),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Metode Pembayaran
                    Row(
                      children: [
                        Icon(_getPaymentIcon(), size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Text(
                          'Metode: ${_getPaymentText()}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Tanggal berlaku
                    Text(
                      'Berlaku s/d: ${service.formattedExpiryDate}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
