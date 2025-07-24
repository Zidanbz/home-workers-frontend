List<Map<String, dynamic>> normalizeVouchers(Map<String, dynamic> raw) {
  final global = (raw['global'] as List).map((v) {
    return {
      'code': v['code'] ?? v['id'],
      'type': v['type'], // 'global'
      'discountType': v['discountType'],
      'value': v['value'],
      'maxDiscount': v['maxDiscount'],
      'minOrder': v['minOrder'],
      'endDate': DateTime.fromMillisecondsSinceEpoch(
        v['endDate']['_seconds'] * 1000,
      ),

      'source': 'global',
    };
  });

  final user = (raw['user'] as List).map((v) {
    return {
      'code': v['voucherCode'],
      'type': 'user_claimed',
      'discountType': v['discountType'],
      'value': v['value'],
      'maxDiscount': v['maxDiscount'],
      'minOrder': v['minOrder'],
      'endDate': DateTime.fromMillisecondsSinceEpoch(
        v['endDate']['_seconds'] * 1000,
      ),
      'source': 'user',
    };
  });

  return [...global, ...user];
}
