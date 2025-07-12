// Lokasi: lib/features/customer_flow/marketplace/pages/marketplace_page.dart

import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/marketplace_detail_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Service>> _servicesFuture;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedSort = 'default';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _servicesFuture = _apiService.getAllApprovedServices(
        category: _selectedCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Worker Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
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
                MaterialPageRoute(
                  builder: (context) => const CustomerChatListPage(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadServices,
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: FutureBuilder<List<Service>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Belum ada layanan yang tersedia.'),
                    );
                  }

                  final allServices = snapshot.data!;
                  List<Service> filteredServices = allServices.where((service) {
                    return service.namaLayanan.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }).toList();

                  // Urutkan
                  if (_selectedSort == 'harga-asc') {
                    filteredServices.sort((a, b) => a.harga.compareTo(b.harga));
                  } else if (_selectedSort == 'harga-desc') {
                    filteredServices.sort((a, b) => b.harga.compareTo(a.harga));
                  } else if (_selectedSort == 'rating-desc') {
                    filteredServices.sort((a, b) {
                      final ratingA = a.workerInfo['rating'] ?? 0;
                      final ratingB = b.workerInfo['rating'] ?? 0;
                      return ratingB.compareTo(ratingA);
                    });
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      return _ServiceCard(service: filteredServices[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: const Text('Pilih Kategori'),
                  items: ['Kebersihan', 'Perbaikan', 'Home Improvement']
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? '');
                    _loadServices();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedSort,
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('Default')),
                  DropdownMenuItem(
                    value: 'harga-asc',
                    child: Text('Harga Termurah'),
                  ),
                  DropdownMenuItem(
                    value: 'harga-desc',
                    child: Text('Harga Tertinggi'),
                  ),
                  DropdownMenuItem(
                    value: 'rating-desc',
                    child: Text('Rating Tertinggi'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value ?? 'default';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari layanan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk kartu layanan di marketplace
class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'kebersihan':
        return Icons.cleaning_services_outlined;
      case 'perbaikan':
        return Icons.build_outlined;
      case 'home improvement':
        return Icons.cottage_outlined;
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
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CustomerServiceDetailPage(serviceId: service.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul dan Kategori
                    Row(
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
                        const SizedBox(width: 6),
                        Icon(
                          _getIconForCategory(service.category),
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.category,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Harga / Biaya Survey
                    Text(
                      service.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getPriceColor(),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Metode pembayaran dan tanggal berlaku
                    Row(
                      children: [
                        Icon(_getPaymentIcon(), size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Text(
                          _getPaymentText(),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          'Sampai: ${service.formattedExpiryDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
