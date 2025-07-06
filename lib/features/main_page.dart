// lib/features/main_page.dart - VERSI DIPERBAIKI

import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/dashboard/pages/costumer_dashboard_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/marketplace_page.dart';
import 'package:home_workers_fe/features/costumer_flow/orders/pages/customer_orders_page.dart';
import 'package:home_workers_fe/features/profile/pages/profile_page.dart';
import 'package:home_workers_fe/features/worker_flow/order_management/pages/worker_orders_page.dart';

// Impor halaman-halaman asli Anda
import 'worker_flow/dashboard/pages/worker_dashboard_page.dart';
import 'worker_flow/service_management/pages/my_jobs_page.dart';

// --- Halaman Placeholder (Ganti dengan halaman asli Anda nanti) ---
// Ini adalah halaman utama untuk Customer

// Halaman ini bisa digunakan bersama atau dibuat terpisah
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: const Center(child: Text('Orders Page')),
  );
}

// -----------------------------------------------------------------

class MainPage extends StatefulWidget {
  final String userRole;
  const MainPage({super.key, required this.userRole});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    void jumpToPage(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    // --- PERUBAHAN UTAMA: Isi _pages dengan halaman asli ---
    // Tentukan halaman mana yang akan ditampilkan berdasarkan role
    if (widget.userRole == 'WORKER') {
      _pages = [
        const WorkerDashboardPage(), // Halaman Home untuk Worker
        const MyJobsPage(), // Halaman Jobs untuk Worker
        const WorkerOrdersPage(), // Halaman Orders (bisa dibuat khusus worker)
        const ProfilePage(), // Halaman Profil
      ];
    } else {
      // Asumsikan default adalah Customer
      _pages = [
        CustomerDashboardPage(
          onNavigateToOrders: () => jumpToPage(2),
        ), // Halaman Home untuk Customer
        MarketplacePage(),
        const CustomerOrdersPage(), // Halaman Orders (bisa dibuat khusus customer)
        const ProfilePage(), // Halaman Profil
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body sekarang menampilkan halaman asli dari daftar _pages
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        // --- PERUBAHAN 2: Sesuaikan dengan desain (4 item) ---
        items: widget.userRole == 'WORKER'
            ? const [
                // Item untuk Worker
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                // Item untuk Customer
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Pekerja',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'Orders',
                ), // Sesuai desain
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
