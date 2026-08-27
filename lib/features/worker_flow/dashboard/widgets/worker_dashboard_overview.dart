import 'package:flutter/material.dart';

class WorkerDashboardOverview extends StatelessWidget {
  const WorkerDashboardOverview({
    super.key,
    required this.pendingOrders,
    required this.acceptedOrders,
    required this.completedOrders,
    required this.rating,
    this.operationalArea,
  });

  final int pendingOrders;
  final int acceptedOrders;
  final int completedOrders;
  final double rating;
  final String? operationalArea;

  static const _navy = Color(0xFF12364D);
  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final hasPendingOrders = pendingOrders > 0;
    final area = operationalArea?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('worker-pending-orders-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navy, Color(0xFF006879)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2412364D),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasPendingOrders
                      ? Icons.notifications_active_rounded
                      : Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPendingOrders
                          ? 'Pesanan perlu respons'
                          : 'Pesanan baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPendingOrders
                          ? '$pendingOrders pesanan sedang menunggu keputusan Anda.'
                          : 'Belum ada pesanan yang menunggu saat ini.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPendingOrders) ...[
                const SizedBox(width: 10),
                Container(
                  constraints: const BoxConstraints(minWidth: 34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$pendingOrders',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (area.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F5F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBCE3DC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: _teal, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Area layanan: $area',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle(
          icon: Icons.insights_rounded,
          title: 'Ringkasan pekerjaan',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                key: const ValueKey('worker-accepted-metric'),
                value: '$acceptedOrders',
                label: 'Berjalan',
                icon: Icons.handyman_outlined,
                foreground: const Color(0xFF2563EB),
                background: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                key: const ValueKey('worker-completed-metric'),
                value: '$completedOrders',
                label: 'Selesai',
                icon: Icons.task_alt_rounded,
                foreground: const Color(0xFF00875A),
                background: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                key: const ValueKey('worker-rating-metric'),
                value: rating > 0 ? rating.toStringAsFixed(1) : '—',
                label: 'Rating',
                icon: Icons.star_rounded,
                foreground: const Color(0xFFD97706),
                background: const Color(0xFFFFF8E7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WorkerDashboardSectionTitle extends StatelessWidget {
  const WorkerDashboardSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return _SectionTitle(icon: icon, title: title, subtitle: subtitle);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F5F2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF00897B), size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF12364D),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF6B7B87),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: 0.13)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF52616B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
