import 'package:flutter/material.dart';

class WorkerProfilePage extends StatelessWidget {
  final Map<String, dynamic> workerInfo;

  const WorkerProfilePage({super.key, required this.workerInfo});

  @override
  Widget build(BuildContext context) {
    final experience = workerInfo['experience'] ?? 3; // tahun pengalaman
    final rating = workerInfo['rating'] ?? 5.0;
    final totalReviews = workerInfo['totalReviews'] ?? 122;
    final totalOrders = workerInfo['totalOrders'] ?? 155;
    final bio = workerInfo['bio'] ?? 'Deskripsi belum tersedia.';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Penyedia Jasa'),
          actions: const [
            Icon(Icons.notifications_none),
            SizedBox(width: 12),
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 12),
            Icon(Icons.share),
            SizedBox(width: 12),
            Icon(Icons.info_outline, color: Colors.red),
            SizedBox(width: 12),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(workerInfo, experience),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.yellow,
              tabs: [
                Tab(text: 'Profil'),
                Tab(text: 'Ulasan tentang pekerja'),
                Tab(text: 'Ulasan pelanggan'),
              ],
            ),
            const SizedBox(height: 16),
            _buildRatingCard(rating, totalReviews, totalOrders),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 24),
            _buildCompanyDescription(bio),
            const SizedBox(height: 24),
            // _buildTawarkanButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> info, int experience) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(info['avatarUrl'] ?? ''),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info['nama'] ?? 'Nama Worker',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$experience Tahun Pengalaman',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingCard(double rating, int ulasan, int selesai) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Profesionalisme ⭐⭐⭐⭐⭐'),
                  Text('Ketepatan Waktu ⭐⭐⭐⭐⭐'),
                  Text('Skala Waktu ⭐⭐⭐⭐⭐'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$ulasan Ulasan',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 24),
              Text(
                '$selesai Pesanan Selesai',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kontak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: const [
              Icon(Icons.mail_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kontak penyedia jasa hanya dapat dilihat oleh pelanggannya. Jika Anda tertarik dengan layanan ini, ajukan pesanan kepadanya.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDescription(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tentang Perusahaan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(bio, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

//   Widget _buildTawarkanButton(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () {
//         Navigator.pop(context); // atau lanjut ke BookingPage lagi
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF1E232C),
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//       child: const Text(
//         'Tawarkan Pekerjaan',
//         style: TextStyle(fontSize: 16),
//       ),
//     );
//   }
// }
