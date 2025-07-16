// lib/features/main_page.dart - VERSI FIXED OVERFLOW

import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/dashboard/pages/costumer_dashboard_page.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/pages/marketplace_page.dart';
import 'package:home_workers_fe/features/costumer_flow/orders/pages/customer_orders_page.dart';
import 'package:home_workers_fe/features/profile/pages/profile_page.dart';
import 'package:home_workers_fe/features/worker_flow/order_management/pages/worker_orders_page.dart';

// Impor halaman-halaman asli Anda
import 'worker_flow/dashboard/pages/worker_dashboard_page.dart';
import 'worker_flow/service_management/pages/my_jobs_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: const Center(child: Text('Orders Page')),
  );
}

class MainPage extends StatefulWidget {
  final String userRole;
  const MainPage({super.key, required this.userRole});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    void jumpToPage(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    if (widget.userRole == 'WORKER') {
      _pages = [
        const WorkerDashboardPage(),
        const MyJobsPage(),
        const WorkerOrdersPage(),
        const ProfilePage(),
      ];
    } else {
      _pages = [
        CustomerDashboardPage(onNavigateToOrders: () => jumpToPage(2)),
        MarketplacePage(),
        const CustomerOrdersPage(),
        const ProfilePage(),
      ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<NavItem> get _navItems {
    if (widget.userRole == 'WORKER') {
      return [
        NavItem(
          icon: Icons.home_rounded,
          activeIcon: Icons.home,
          label: 'Home',
          color: const Color(0xFF6C63FF),
        ),
        NavItem(
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          label: 'Jobs',
          color: const Color(0xFF00D4AA),
        ),
        NavItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: 'Orders',
          color: const Color(0xFFFF6B6B),
        ),
        NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
          color: const Color(0xFFFFB800),
        ),
      ];
    } else {
      return [
        NavItem(
          icon: Icons.home_rounded,
          activeIcon: Icons.home,
          label: 'Home',
          color: const Color(0xFF6C63FF),
        ),
        NavItem(
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          label: 'Pekerja',
          color: const Color(0xFF00D4AA),
        ),
        NavItem(
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag,
          label: 'Orders',
          color: const Color(0xFFFF6B6B),
        ),
        NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
          color: const Color(0xFFFFB800),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_navItems.length, (index) {
                  return Expanded(
                    child: _buildNavItem(index, _navItems[index]),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavItem item) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });

        // Haptic feedback untuk pengalaman yang lebih baik
        // HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected && _animationController.isAnimating
                ? _scaleAnimation.value
                : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container dengan animasi
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: isSelected ? item.color : Colors.grey.shade600,
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                  ),

                  const SizedBox(height: 1),

                  // Label dengan animasi
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 10.5 : 9.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? item.color : Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Indicator dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(top: 1),
                    height: 2,
                    width: isSelected ? 16 : 0,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Model untuk item navigasi
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
