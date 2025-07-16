import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/booking_page.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';

class CustomerServiceDetailPage extends StatefulWidget {
  final String serviceId;
  const CustomerServiceDetailPage({super.key, required this.serviceId});

  @override
  State<CustomerServiceDetailPage> createState() =>
      _CustomerServiceDetailPageState();
}

class _CustomerServiceDetailPageState extends State<CustomerServiceDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Service> _serviceDetailFuture;

  @override
  void initState() {
    super.initState();
    _serviceDetailFuture = _apiService.getServiceById(widget.serviceId);
  }

  // METODE BANTU BARU untuk mendapatkan ikon kategori secara dinamis
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
      case 'home improvement':
        return Icons.cottage_outlined;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Detail Layanan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A374D),
        elevation: 0.5,
      ),
      body: FutureBuilder<Service>(
        future: _serviceDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Layanan tidak ditemukan.'));
          }

          final service = snapshot.data!;
          final workerInfo = service.workerInfo;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWorkerHeader(workerInfo),
                      const SizedBox(height: 16),
                      // PERUBAHAN UTAMA ADA DI DALAM METHOD DI BAWAH INI
                      _buildServiceHeader(service),
                      const SizedBox(height: 24),
                      _buildInfoRow(Icons.category_outlined, service.category),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.payment_outlined,
                        service.metodePembayaran.isNotEmpty
                            ? service.metodePembayaran.join(' & ')
                            : 'Metode belum tersedia',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Deskripsi Layanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A374D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.deskripsiLayanan,
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Foto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A374D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoGallery(service.photoUrls),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkerHeader(Map<String, dynamic> workerInfo) {
    // ... (Tidak ada perubahan di sini, biarkan seperti semula)
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFD9D9D9),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(
                workerInfo['avatarUrl'] ??
                    'https://i.pravatar.cc/150?u=${workerInfo['id']}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workerInfo['nama'] ?? 'Nama Worker',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A374D),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Navigasi ke halaman chat
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF1A374D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader(Service service) {
    final postDate = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(service.dibuatPada);

    // PERUBAHAN DI SINI: Tentukan label dan nilai harga berdasarkan tipe layanan
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String priceLabel;
    String priceValue;

    if (service.tipeLayanan == 'survey') {
      priceLabel = 'Biaya Survei';
      priceValue = formatCurrency.format(service.biayaSurvei ?? 0);
    } else {
      priceLabel = 'Harga Layanan';
      priceValue = formatCurrency.format(service.harga ?? 0);
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            service.fotoUtamaUrl.isNotEmpty
                ? service.fotoUtamaUrl
                : 'https://via.placeholder.com/80',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(width: 80, height: 80, color: Colors.grey[200]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Diposting: $postDate",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              // Menampilkan label harga
              Text(
                priceLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              // Menampilkan nilai harga
              Text(
                priceValue,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A374D),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          // Menggunakan ikon dinamis dari metode baru
          child: Icon(
            _getIconForCategory(service.category),
            color: const Color(0xFF1A374D),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    // ... (Tidak ada perubahan di sini, biarkan seperti semula)
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildPhotoGallery(List<dynamic> photoUrls) {
    // ... (Tidak ada perubahan di sini, biarkan seperti semula)
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrls[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(Service service) {
    // ... (Tidak ada perubahan di sini, sudah benar)
    return Container(
      padding: const EdgeInsets.all(20).copyWith(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookingPage(service: service),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A374D),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            service.tipeLayanan == 'survey'
                ? 'Buat Permintaan Survey'
                : 'Pesan Sekarang',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
