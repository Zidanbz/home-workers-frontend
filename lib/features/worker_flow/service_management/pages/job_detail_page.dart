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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Detail Pekerjaan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
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
                _buildActionButtons(service),
                const SizedBox(height: 24),
                _buildServiceHeader(service),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Makassar, BTP',
                ), // Data dummy
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time_outlined,
                  '10:00 WITA',
                ), // Data dummy
                _buildInfoRow(
                  Icons.payment_outlined,
                  service.metodePembayaran.join(' & '),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  service.deskripsiLayanan,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPhotoGallery(service.photoUrls),
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
          child: _isDeleting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleDeleteService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE6E6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => CreateEditJobPage(service: service),
                ),
              );
              if (result == true) {
                _loadServiceDetails(); // Refresh halaman detail
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E232C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHeader(Service service) {
    final postDate = DateFormat('dd.MM.yyyy').format(service.dibuatPada);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    service.fotoUtamaUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Diposting: $postDate",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Harga: ${service.formattedPrice}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
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
    if (photoUrls.isEmpty) {
      return const Text(
        'Tidak ada foto tambahan.',
        style: TextStyle(color: Colors.grey),
      );
    }
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
}
