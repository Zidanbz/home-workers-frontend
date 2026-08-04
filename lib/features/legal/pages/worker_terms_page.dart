import 'package:flutter/material.dart';

import '../../../core/legal/worker_terms.dart';

class WorkerTermsPage extends StatelessWidget {
  const WorkerTermsPage({super.key});

  static const Color _primary = Color(0xFF163B52);
  static const Color _accent = Color(0xFF0F8B78);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        title: const Text(
          'Syarat & Ketentuan Worker',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 14),
                  Text(
                    WorkerTerms.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Versi ${WorkerTerms.version}\n'
                    'Berlaku mulai ${WorkerTerms.effectiveDate}',
                    style: TextStyle(
                      color: Color(0xFFD6E8EF),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              WorkerTerms.introduction,
              style: TextStyle(
                color: Color(0xFF40545F),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < WorkerTerms.sections.length; index++)
              _TermsSectionCard(
                number: index + 1,
                section: WorkerTerms.sections[index],
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F4EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB8DED3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: _accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dengan melanjutkan registrasi, Anda menyatakan telah '
                      'membaca, memahami, dan menyetujui dokumen versi ini.',
                      style: TextStyle(
                        color: Color(0xFF24584E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Saya Sudah Membaca',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSectionCard extends StatelessWidget {
  const _TermsSectionCard({required this.number, required this.section});

  final int number;
  final WorkerTermsSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4F4EF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: WorkerTermsPage._accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      color: WorkerTermsPage._primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final paragraph in section.paragraphs) ...[
            Text(
              paragraph,
              style: const TextStyle(
                color: Color(0xFF40545F),
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 9),
          ],
          for (final point in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: WorkerTermsPage._accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFF40545F),
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
