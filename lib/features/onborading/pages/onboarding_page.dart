import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/auth/pages/select_role_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Fungsi untuk menandai bahwa onboarding telah selesai
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    // Navigasi ke halaman Pilih Peran setelah onboarding selesai
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SelectRolePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Tombol Skip
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: const [
                _OnboardingContent(
                  imagePath: 'assets/sp1.png', // Ganti dengan path aset Anda
                  title: 'Ahli Perbaikan Profesional Siap Membantu.',
                ),
                _OnboardingContent(
                  imagePath: 'assets/sp2.png', // Ganti dengan path aset Anda
                  title: 'Pesan Layanan Mudah, Langsung dari Genggaman.',
                ),
                _OnboardingContent(
                  imagePath: 'assets/sp1.png', // Ganti dengan path aset Anda
                  title: 'Solusi Terpercaya untuk Semua Kebutuhan Servis Anda.',
                ),
              ],
            ),
          ),
          // Indikator halaman (titik-titik)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF1E232C)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          // Tombol Navigasi
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _completeOnboarding();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E232C),
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 80),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget terpisah untuk konten halaman onboarding
class _OnboardingContent extends StatelessWidget {
  final String imagePath;
  final String title;
  const _OnboardingContent({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 120,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 240,
              height: 240,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E232C),
          ),
        ),
      ],
    );
  }
}
