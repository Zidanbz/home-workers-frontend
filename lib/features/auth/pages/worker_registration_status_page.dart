import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:provider/provider.dart';

class WorkerRegistrationStatusPage extends StatelessWidget {
  const WorkerRegistrationStatusPage({
    super.key,
    this.status = 'pending',
    this.rejectionReason,
  });

  final String status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final isRejected = status.toLowerCase() == 'rejected';
    final color = isRejected ? Colors.red.shade700 : const Color(0xFF1A374D);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRejected
                          ? Icons.cancel_outlined
                          : Icons.hourglass_top_rounded,
                      color: color,
                      size: 72,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isRejected
                          ? 'Registrasi Worker Ditolak'
                          : 'Registrasi Sedang Diverifikasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E232C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRejected
                          ? 'Dokumen Anda belum dapat disetujui. Periksa alasan berikut atau hubungi Admin.'
                          : 'Admin sedang memeriksa identitas, dokumen KTP, dan data keahlian Anda. Akses Worker akan terbuka setelah akun disetujui.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        height: 1.5,
                      ),
                    ),
                    if (isRejected &&
                        rejectionReason != null &&
                        rejectionReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Text(
                          rejectionReason!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (_) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Kembali ke Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
