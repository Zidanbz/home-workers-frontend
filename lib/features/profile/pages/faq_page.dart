import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  static const Color _primaryColor = Color(0xFF1A374D);
  static const Color _bgColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    // Gunakan list typed agar tidak perlu cast dynamic.
    const faqItems = <_FaqItem>[
      _FaqItem(
        question: 'Apa itu Home Workers?',
        answer:
            'Home Workers adalah platform untuk menemukan dan memesan layanan perbaikan rumah.',
        icon: Icons.home_work_outlined,
      ),
      _FaqItem(
        question: 'Bagaimana cara memesan layanan?',
        answer:
            'Cari layanan yang Anda butuhkan, pilih jadwal, dan lakukan pembayaran melalui aplikasi.',
        icon: Icons.shopping_cart_outlined,
      ),
      _FaqItem(
        question: 'Apakah pembayaran aman?',
        answer:
            'Ya, pembayaran diproses melalui Midtrans dengan sistem keamanan terjamin.',
        icon: Icons.security_outlined,
      ),
      _FaqItem(
        question: 'Bagaimana cara menjadi pekerja?',
        answer:
            'Anda dapat mendaftar sebagai pekerja melalui menu registrasi dan melengkapi data KTP serta foto diri.',
        icon: Icons.person_add_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor.withOpacity(0.1), _bgColor],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Butuh Bantuan?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temukan jawaban untuk pertanyaan yang sering diajukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _primaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // FAQ List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faqItems.length,
                itemBuilder: (context, index) {
                  final item = faqItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            color: _primaryColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          item.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _primaryColor,
                          ),
                        ),
                        iconColor: _primaryColor,
                        collapsedIconColor: _primaryColor,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          20,
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _bgColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.answer,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: _primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent,
                      size: 32,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Masih butuh bantuan?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hubungi tim support kami untuk bantuan lebih lanjut',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implementasi Contact Support
                        // Contoh: Navigator.pushNamed(context, '/support');
                        // atau buka chat support internal.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hubungi Support',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Model sederhana untuk item FAQ.
class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}
