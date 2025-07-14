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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Detail Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
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
                      _buildServiceHeader(service),
                      const SizedBox(height: 24),
                      _buildInfoRow(Icons.category_outlined, service.category),
                      const SizedBox(height: 8),
                      // _buildInfoRow(
                      //   Icons.location_on_outlined,
                      //   'Makassar, BTP',
                      // ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader(Service service) {
    final postDate = DateFormat('dd.MM.yyyy').format(service.dibuatPada);

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
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                ).format(service.harga),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
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
          child: const Icon(
            Icons.cleaning_services_outlined,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildPhotoGallery(List<dynamic> photoUrls) {
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
    return Container(
      padding: const EdgeInsets.all(20).copyWith(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            backgroundColor: const Color(0xFF1E232C),
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
