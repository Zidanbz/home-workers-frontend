import 'package:flutter/material.dart';

import 'worker_dashboard_overview.dart';

class WorkerReviewSection extends StatelessWidget {
  const WorkerReviewSection({super.key, required this.reviews});

  final List<dynamic> reviews;

  static const _navy = Color(0xFF12364D);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final validReviews = reviews
        .whereType<Map>()
        .map((review) => Map<String, dynamic>.from(review))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkerDashboardSectionTitle(
          icon: Icons.reviews_outlined,
          title: 'Ulasan terbaru',
          subtitle: 'Masukan terbaru dari pelanggan Anda.',
        ),
        const SizedBox(height: 14),
        if (validReviews.isEmpty)
          _buildEmptyState()
        else ...[
          _buildSummary(validReviews),
          const SizedBox(height: 12),
          ...validReviews.take(3).map(_buildReviewCard),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('worker-reviews-empty'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAED)),
      ),
      child: const Row(
        children: [
          Icon(Icons.star_outline_rounded, color: Color(0xFF90A0AA), size: 30),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada ulasan',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ulasan akan muncul setelah pelanggan menyelesaikan pesanan.',
                  style: TextStyle(
                    color: Color(0xFF6B7B87),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Map<String, dynamic>> validReviews) {
    final average =
        validReviews.fold<double>(
          0,
          (sum, review) => sum + _asDouble(review['rating']),
        ) /
        validReviews.length;

    return Container(
      key: const ValueKey('worker-reviews-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE3A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rounded, color: _amber, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${validReviews.length} ulasan terbaru',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ..._buildStars(average, size: 16),
                    const SizedBox(width: 7),
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final customerName = _safeText(review['customerName'], 'Pelanggan');
    final comment = _safeText(review['comment'], 'Tidak ada komentar.');
    final rating = _asDouble(review['rating']);
    final avatarUrl = _safeHttpsUrl(review['customerAvatarUrl']);
    final verified = review['verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D12364D),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(avatarUrl),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 5),
                          const Tooltip(
                            message: 'Pesanan terverifikasi',
                            child: Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF00875A),
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ..._buildStars(rating, size: 14),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _formatDate(review['createdAt']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF82919B),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            comment,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF43515A),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    const fallback = ColoredBox(
      color: Color(0xFFE7EEF1),
      child: Center(
        child: Icon(Icons.person_rounded, color: Color(0xFF78909C), size: 24),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 42,
        child: avatarUrl == null
            ? fallback
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  List<Widget> _buildStars(double rating, {required double size}) {
    return List.generate(5, (index) {
      final icon = index + 1 <= rating
          ? Icons.star_rounded
          : index < rating
          ? Icons.star_half_rounded
          : Icons.star_outline_rounded;
      return Icon(icon, color: _amber, size: size);
    });
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble().clamp(0, 5).toDouble();
    return (double.tryParse(value?.toString() ?? '') ?? 0)
        .clamp(0, 5)
        .toDouble();
  }

  String? _safeHttpsUrl(dynamic value) {
    final uri = Uri.tryParse(value?.toString().trim() ?? '');
    return uri?.scheme == 'https' && uri?.host.isNotEmpty == true
        ? uri.toString()
        : null;
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value != null) {
      date = DateTime.tryParse(value.toString());
    }
    if (date == null) return 'Tanggal tidak tersedia';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
