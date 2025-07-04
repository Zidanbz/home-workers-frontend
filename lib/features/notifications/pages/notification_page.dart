import 'package:flutter/material.dart';

// Model data tiruan untuk satu notifikasi
class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Data tiruan untuk ditampilkan di list
  final List<NotificationItem> _notifications = [
    NotificationItem(
      icon: Icons.campaign_outlined,
      iconColor: Colors.blue,
      title: 'Promo Spesial Akhir Pekan! 🎉',
      body:
          'Dapatkan diskon 20% untuk semua layanan kebersihan. Pesan sekarang!',
      time: '1 jam lalu',
    ),
    NotificationItem(
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      title: 'Layanan Disetujui!',
      body:
          'Layanan Anda "Pembersihan Apartemen" telah disetujui dan kini aktif di marketplace.',
      time: '3 jam lalu',
    ),
    NotificationItem(
      icon: Icons.receipt_long_outlined,
      iconColor: Colors.deepPurple,
      title: 'Pesanan Baru',
      body:
          'Anda menerima pesanan baru untuk "Perbaikan Saluran Air" dari Siti Customer.',
      time: 'Kemarin',
    ),
    NotificationItem(
      icon: Icons.cancel_outlined,
      iconColor: Colors.red,
      title: 'Layanan Ditolak',
      body:
          'Layanan Anda "Instalasi Listrik Kompleks" ditolak. Silakan periksa detailnya.',
      time: '2 hari lalu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
        separatorBuilder: (context, index) => const Divider(),
      ),
    );
  }

  // Widget untuk satu kartu notifikasi
  Widget _buildNotificationCard(NotificationItem notification) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: notification.iconColor.withOpacity(0.1),
        child: Icon(notification.icon, color: notification.iconColor, size: 28),
      ),
      title: Text(
        notification.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(notification.body),
      ),
      trailing: Text(
        notification.time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        // TODO: Tambahkan logika navigasi saat notifikasi di-klik
        // (misal: ke halaman detail order atau halaman promo)
      },
    );
  }
}
