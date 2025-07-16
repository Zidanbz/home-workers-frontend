import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/worker_flow/service_management/pages/edit_job_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';

class JobDetailPage extends StatefulWidget {
  final String serviceId;
  const JobDetailPage({super.key, required this.serviceId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Service> _serviceDetailFuture;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadServiceDetails();
  }

  void _loadServiceDetails() {
    setState(() {
      _serviceDetailFuture = _apiService.getServiceById(widget.serviceId);
    });
  }

  Future<void> _handleDeleteService() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus layanan ini? Tindakan ini tidak bisa dibatalkan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => navigator.pop(false),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => navigator.pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Authentication failed.');

      await _apiService.deleteService(
        token: token,
        serviceId: widget.serviceId,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Layanan berhasil dihapus.'),
        ),
      );

      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal menghapus layanan: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Detail Pekerjaan'),
        backgroundColor: const Color(0xFF1A374D), // Primary color
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceHeader(service),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.category_outlined, service.category),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, 'Makassar, BTP'),
                _buildInfoRow(Icons.access_time_outlined, '10:00 WITA'),
                _buildInfoRow(
                  Icons.payment_outlined,
                  service.metodePembayaran.join(' & '),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  service.deskripsiLayanan,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Foto Layanan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPhotoGallery(service.photoUrls),
                const SizedBox(height: 32),
                _buildActionButtons(service),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Service service) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isDeleting ? null : _handleDeleteService,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => CreateEditJobPage(service: service),
                ),
              );
              if (result == true) _loadServiceDetails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A374D), // Primary color
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHeader(Service service) {
    final postDate = DateFormat('dd MMM yyyy').format(service.dibuatPada);
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                service.fotoUtamaUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.namaLayanan,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A374D), // Primary color
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Diposting: $postDate",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Harga: ${service.formattedPrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A374D), // Primary color
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A374D), size: 20), // Primary color
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A374D),
              ), // Primary color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<dynamic> photoUrls) {
    if (photoUrls.isEmpty) {
      return const Text(
        'Tidak ada foto tambahan.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photoUrls[index],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
