import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/register_customer_page.dart';
import 'package:home_workers_fe/features/auth/pages/register_worker_page.dart';
import 'package:provider/provider.dart';
// TODO: Impor halaman registrasi customer dan worker Anda nanti
// import 'register_customer_page.dart';
// import 'register_worker_page.dart';

class SelectRolePage extends StatelessWidget {
  const SelectRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E232C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih Peran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E232C),
              ),
            ),
            const Spacer(),
            // Kartu untuk Customer
            _RoleCard(
              title: 'Mencari spesialis',
              description:
                  'Untuk membuat semua jenis pesanan dan untuk mencari seorang penyedia jasa',
              imagePath: 'assets/costumer.png', // Ganti dengan path aset Anda
              onTap: () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).showLoginPage();
                // TODO: Navigasi ke halaman registrasi Customer
                 Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterCustomerPage()));
                print('Navigasi ke Registrasi Customer');
              },
            ),
            const SizedBox(height: 24),
            // Kartu untuk Worker
            _RoleCard(
              title: 'Saya ingin mencari pekerjaan',
              description:
                  'Cari dan selesaikan pesanan di bidang keahlian Anda',
              imagePath: 'assets/worker.png', // Ganti dengan path aset Anda
              onTap: () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).showLoginPage();
                // TODO: Navigasi ke halaman registrasi Worker
                 Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterWorkerPage()));
                print('Navigasi ke Registrasi Worker');
              },
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudah punya akun?',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8391A1)),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false)
                        .showLoginPage();
                  },
                  child: const Text(
                    'Login sekarang!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E232C),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// Widget terpisah untuk kartu pilihan peran
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Image.asset(imagePath, width: 80, height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
