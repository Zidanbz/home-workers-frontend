import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/marketplace_detail_page.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/category_model.dart';
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Worker Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A374D),
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

                  // Sort services
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
    const fieldDecoration = InputDecoration(
      filled: true,
      fillColor: Color(0xFFF0F0F0),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF1A374D), width: 1.5),
      ),
      isDense: true,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Row untuk dropdown kategori dan sort
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: const Text('Kategori', style: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: CategoryData.getCategoryNames()
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CategoryData.getIconForCategory(cat),
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value ?? '');
                    _loadServices();
                  },
                  decoration: fieldDecoration.copyWith(
                    prefixIcon: const Icon(Icons.category, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedSort,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: const [
                    DropdownMenuItem(
                      value: 'default',
                      child: Text('Default', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'harga-asc',
                      child: Text('Termurah', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'harga-desc',
                      child: Text('Termahal', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'rating-desc',
                      child: Text('Rating ⭐', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSort = value ?? 'default');
                  },
                  decoration: fieldDecoration.copyWith(
                    prefixIcon: const Icon(Icons.sort, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Search field
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: const TextStyle(fontSize: 14),
            decoration: fieldDecoration.copyWith(
              hintText: 'Cari layanan...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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

  // METODE BARU untuk menentukan teks harga/biaya survei
  String _getDisplayPrice() {
    // Membuat formatter untuk mata uang Rupiah
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (service.tipeLayanan == 'survey') {
      // Jika tipe layanan adalah 'survey', format 'biayaSurvei'
      // Gunakan '?? 0' untuk menangani jika nilainya null
      final surveyCost = service.biayaSurvei ?? 0;
      return 'Biaya Survei: ${formatCurrency.format(surveyCost)}';
    } else {
      // Jika tidak, format 'harga' seperti biasa
      final price = service.harga ?? 0;
      return formatCurrency.format(price);
    }
  }

  IconData _getIconForCategory(String category) {
    return Category.getIconForCategoryString(category);
  }

  Color _getPriceColor() {
    return service.tipeLayanan == 'survey'
        ? Colors.orange.shade800
        : Colors.deepPurple;
  }

  String _getPaymentText() {
    // Diasumsikan metodePembayaran adalah List<String>
    if (service.metodePembayaran is List) {
      return (service.metodePembayaran as List).join(', ');
    }
    // Fallback jika datanya berupa String tunggal
    return service.metodePembayaran.toString();
  }

  IconData _getPaymentIcon() {
    // Cek jika 'cash' ada di dalam list atau string
    if (service.metodePembayaran.toString().toLowerCase().contains('cash')) {
      return Icons.money;
    }
    return Icons.credit_card;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: const Color(0xFFFFFFFF),
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
                    color: const Color(0xFFD9D9D9),
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
                              color: Color(0xFF1A374D),
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
                      _getDisplayPrice(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getPriceColor(),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Metode pembayaran
                    Row(
                      children: [
                        Icon(_getPaymentIcon(), size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getPaymentText(),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
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
