import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/models/service_model.dart';
import '../pages/marketplace_detail_page.dart';

class MarketplaceServiceCard extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF163B52);
  static const Color _accentColor = Color(0xFF0F8B78);
  static const Color _mutedColor = Color(0xFF6B7D87);

  final Service service;

  const MarketplaceServiceCard({super.key, required this.service});

  String get _workerName {
    final name = service.workerInfo['nama']?.toString().trim() ?? '';
    return name.isEmpty ? 'Mitra Home Workers' : name;
  }

  double? get _workerRating {
    final value = service.workerInfo['rating'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String get _displayPrice {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final amount = service.tipeLayanan == 'survey'
        ? service.biayaSurvei ?? 0
        : service.harga;
    return formatCurrency.format(amount);
  }

  String get _priceLabel {
    return service.tipeLayanan == 'survey' ? 'Biaya survei' : 'Harga layanan';
  }

  String get _paymentText {
    final methods = service.metodePembayaran
        .map((method) => method.toString().trim())
        .where((method) => method.isNotEmpty)
        .toList();
    return methods.isEmpty ? 'Menyusul' : methods.join(' • ');
  }

  String get _imageUrl => service.fotoUtamaUrl.trim();

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerServiceDetailPage(serviceId: service.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = _workerRating;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E8EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D163B52),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceImage(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 112,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryChip(),
                            const SizedBox(height: 9),
                            Text(
                              service.namaLayanan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: _accentColor,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _workerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _mutedColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (rating != null && rating > 0) ...[
                                  const SizedBox(width: 7),
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF4B740),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: _primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (service.distanceKm != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey('marketplace-distance-info'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 16,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_distanceText(service.distanceKm!)} • '
                            '${service.operationalAreaLabel ?? 'Area Worker'}'
                            ' • Menjangkau alamat Anda',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE5EBEE)),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _priceLabel,
                            style: const TextStyle(
                              color: _mutedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displayPrice,
                            style: TextStyle(
                              color: service.tipeLayanan == 'survey'
                                  ? const Color(0xFFC56A12)
                                  : _primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: const ValueKey('marketplace-payment-chip'),
                          constraints: const BoxConstraints(maxWidth: 108),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 15,
                                color: _mutedColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _paymentText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _mutedColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          key: const ValueKey('marketplace-detail-button'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _distanceText(double distanceKm) {
    if (distanceKm < 0.1) return '< 0,1 km';
    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  Widget _buildServiceImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 108,
        height: 112,
        child: _imageUrl.isEmpty
            ? _buildImageFallback()
            : CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (_, __) => Container(
                  color: const Color(0xFFEDF3F5),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildImageFallback(),
              ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3F5), Color(0xFFDCE9ED)],
        ),
      ),
      child: Icon(
        Category.getIconForCategoryString(service.category),
        color: const Color(0xFF4E8290),
        size: 38,
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Category.getIconForCategoryString(service.category),
            size: 13,
            color: const Color(0xFF397382),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              service.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF397382),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketplaceServiceCardSkeleton extends StatelessWidget {
  const MarketplaceServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 108,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonLine(width: 82, height: 24),
                      const SizedBox(height: 12),
                      _skeletonLine(width: double.infinity, height: 15),
                      const SizedBox(height: 7),
                      _skeletonLine(width: 120, height: 15),
                      const Spacer(),
                      _skeletonLine(width: 145, height: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5EBEE)),
          const SizedBox(height: 12),
          Row(
            children: [
              _skeletonLine(width: 105, height: 27),
              const Spacer(),
              _skeletonLine(width: 98, height: 34),
              const SizedBox(width: 9),
              _skeletonLine(width: 40, height: 40),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
