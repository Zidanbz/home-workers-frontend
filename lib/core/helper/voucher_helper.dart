List<Map<String, dynamic>> normalizeVouchers(Map<String, dynamic> raw) {
  print('🔍 [normalizeVouchers] Raw data: $raw');
  
  final global = (raw['global'] as List? ?? []).map((v) {
    print('🌍 [normalizeVouchers] Processing global voucher: $v');
    
    DateTime? endDate;
    if (v['endDate'] != null && v['endDate'] is Map && v['endDate']['_seconds'] != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(
        v['endDate']['_seconds'] * 1000,
      );
    }

    final normalized = {
      'code': (v['code'] ?? v['id'] ?? '').toString(),
      'type': (v['type'] ?? 'ready').toString(),
      'discountType': (v['discountType'] ?? 'percent').toString(),
      'value': v['value'],
      'maxDiscount': v['maxDiscount'],
      'minOrder': v['minOrder'],
      'endDate': endDate,
      'source': 'global',
    };
    
    print('✅ [normalizeVouchers] Normalized global voucher: $normalized');
    return normalized;
  }).toList();

  final user = (raw['user'] as List? ?? []).where((v) {
    // Filter out user vouchers that don't have complete data
    // This happens when backend doesn't populate voucher details
    final hasValue = v['value'] != null || v['discountType'] != null;
    if (!hasValue) {
      print('⚠️ [normalizeVouchers] Skipping incomplete user voucher: ${v['voucherCode']}');
      print('⚠️ [normalizeVouchers] Backend needs to populate voucher details for user vouchers');
    }
    return hasValue;
  }).map((v) {
    print('👤 [normalizeVouchers] Processing user voucher: $v');
    print('👤 [normalizeVouchers] voucherCode: ${v['voucherCode']}');
    print('👤 [normalizeVouchers] value: ${v['value']}');
    print('👤 [normalizeVouchers] discountType: ${v['discountType']}');
    
    DateTime? endDate;
    if (v['endDate'] != null && v['endDate'] is Map && v['endDate']['_seconds'] != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(
        v['endDate']['_seconds'] * 1000,
      );
    }

    final normalized = {
      'code': (v['voucherCode'] ?? v['code'] ?? '').toString(),
      'type': 'user_claimed',
      'discountType': (v['discountType'] ?? 'percent').toString(),
      'value': v['value'],
      'maxDiscount': v['maxDiscount'],
      'minOrder': v['minOrder'],
      'endDate': endDate,
      'source': 'user',
    };
    
    print('✅ [normalizeVouchers] Normalized user voucher: $normalized');
    return normalized;
  }).toList();

  final result = [...global, ...user];
  print('📊 [normalizeVouchers] Total vouchers: ${result.length}');
  print('📊 [normalizeVouchers] Global: ${global.length}, User: ${user.length}');
  return result;
}
