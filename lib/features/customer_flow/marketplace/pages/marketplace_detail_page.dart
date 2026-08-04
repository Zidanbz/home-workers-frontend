import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/customer_flow/booking/pages/booking_page.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';

class CustomerServiceDetailPage extends StatefulWidget {
  final String serviceId;
  final Future<Service> Function(String serviceId)? loadService;

  const CustomerServiceDetailPage({
    super.key,
    required this.serviceId,
    this.loadService,
  });

  @override
  State<CustomerServiceDetailPage> createState() =>
      _CustomerServiceDetailPageState();
}

class _CustomerServiceDetailPageState extends State<CustomerServiceDetailPage> {
  late Future<Service> _serviceDetailFuture;

  @override
  void initState() {
    super.initState();
    _serviceDetailFuture =
        widget.loadService?.call(widget.serviceId) ??
        ApiService().getServiceById(widget.serviceId);
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Service>(
        future: _serviceDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                ApiService.readableError(
                  snapshot.error,
                  action: 'Gagal memuat detail layanan',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Layanan tidak ditemukan.'));
          }

          final service = snapshot.data!;
          final workerInfo = service.workerInfo;
          final servicePhotos = _servicePhotoUrls(service);
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
                      _buildServiceHeader(service, servicePhotos),
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
                      _buildPhotoGallery(servicePhotos),
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
    final avatarUrl = workerInfo['avatarUrl']?.toString().trim() ?? '';
    final hasValidAvatar = avatarUrl.isNotEmpty && avatarUrl != 'null';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: hasValidAvatar
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: !hasValidAvatar
                      ? Icon(Icons.person, size: 32, color: Colors.grey[600])
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerInfo['nama'] ?? 'Nama Worker',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1A374D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${workerInfo['rating']?.toStringAsFixed(1) ?? '0.0'} • ${workerInfo['totalReviews'] ?? 0} ulasan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

  Widget _buildServiceHeader(Service service, List<String> servicePhotos) {
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
      priceValue = formatCurrency.format(service.harga);
    }

    return Row(
      children: [
        _buildMainServicePhoto(servicePhotos),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.namaLayanan,
                key: const ValueKey('service-detail-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A374D),
                ),
              ),
              const SizedBox(height: 6),
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

  List<String> _servicePhotoUrls(Service service) {
    final photos = <String>[];
    final candidates = <dynamic>[service.fotoUtamaUrl, ...service.photoUrls];
    for (final value in candidates) {
      if (value is! String) continue;
      final candidate = value.trim();
      final uri = Uri.tryParse(candidate);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) continue;
      if (uri.host == 'placehold.co' || uri.host == 'via.placeholder.com') {
        continue;
      }
      if (!photos.contains(candidate)) photos.add(candidate);
    }
    return photos;
  }

  Widget _buildMainServicePhoto(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      return _photoFallback(width: 80, height: 80);
    }

    return Semantics(
      button: true,
      label: 'Buka foto utama layanan',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('service-main-photo'),
          onTap: () => _openPhotoViewer(photoUrls, 0),
          child: Stack(
            children: [
              Image.network(
                photoUrls.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _photoFallback(width: 80, height: 80),
              ),
              const Positioned(
                right: 5,
                bottom: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xB3000000),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.zoom_in_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      return const Text(
        'Foto layanan belum tersedia.',
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
            child: Semantics(
              button: true,
              label: 'Buka foto layanan ${index + 1}',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('service-gallery-photo-$index'),
                  onTap: () => _openPhotoViewer(photoUrls, index),
                  child: Image.network(
                    photoUrls[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _photoFallback(width: 100, height: 100),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _photoFallback({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[500]),
    );
  }

  void _openPhotoViewer(List<String> photoUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ServicePhotoViewerPage(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
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

class _ServicePhotoViewerPage extends StatefulWidget {
  const _ServicePhotoViewerPage({
    required this.photoUrls,
    required this.initialIndex,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<_ServicePhotoViewerPage> createState() =>
      _ServicePhotoViewerPageState();
}

class _ServicePhotoViewerPageState extends State<_ServicePhotoViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('service-photo-viewer'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photoUrls.length}',
          key: const ValueKey('service-photo-counter'),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                widget.photoUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Foto tidak dapat dimuat.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
