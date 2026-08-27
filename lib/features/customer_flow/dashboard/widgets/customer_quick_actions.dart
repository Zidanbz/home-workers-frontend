import 'package:flutter/material.dart';

class CustomerQuickActions extends StatelessWidget {
  final VoidCallback onMarketplaceTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onNearbyTap;
  final Key? marketplaceKey;
  final Key? ordersKey;

  const CustomerQuickActions({
    super.key,
    required this.onMarketplaceTap,
    required this.onOrdersTap,
    required this.onNearbyTap,
    this.marketplaceKey,
    this.ordersKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrimaryQuickAction(
          key: marketplaceKey,
          title: 'Cari Penyedia Jasa',
          subtitle: 'Jelajahi layanan dari Worker tepercaya',
          icon: Icons.person_search_rounded,
          onTap: onMarketplaceTap,
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SecondaryQuickAction(
                  key: ordersKey,
                  title: 'Riwayat Pesanan',
                  subtitle: 'Pantau status pesanan',
                  icon: Icons.work_history_rounded,
                  accentColor: const Color(0xFF445068),
                  accentSurface: const Color(0xFFEDF0F5),
                  onTap: onOrdersTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryQuickAction(
                  key: const ValueKey('customer-nearby-action'),
                  title: 'Cari di Sekitar',
                  subtitle: 'Temukan Worker terdekat',
                  icon: Icons.near_me_rounded,
                  accentColor: const Color(0xFFE95662),
                  accentSurface: const Color(0xFFFFECEE),
                  onTap: onNearbyTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryQuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryQuickAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24163B52),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF163B52), Color(0xFF27657A)],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD5E7EC),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 13),
                        const Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Lihat semua layanan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 29),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryQuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentSurface;
  final VoidCallback onTap;

  const _SecondaryQuickAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentSurface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: accentColor.withValues(alpha: 0.72),
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172B38),
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF73838D),
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
