class Transaction {
  final String id;
  final String type; // 'cash-in' atau 'cash-out'
  final num amount;
  final String description;
  final String status; // 'confirmed' atau 'pending'
  final DateTime timestamp;
  final String? orderId;
  final String? refundId;
  final String? paymentTarget;
  final String? payoutReason;
  final String? destination;
  final num? grossAmount;
  final num? initialGrossAmount;
  final num? finalGrossAmount;
  final num? customerPaidAmount;
  final num? voucherDiscountAmount;
  final num? platformAmount;
  final num? platformNetAmount;
  final num? originalAmount;
  final num? refundedAmount;
  final Map<String, dynamic> paymentBreakdown;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.timestamp,
    this.orderId,
    this.refundId,
    this.paymentTarget,
    this.payoutReason,
    this.destination,
    this.grossAmount,
    this.initialGrossAmount,
    this.finalGrossAmount,
    this.customerPaidAmount,
    this.voucherDiscountAmount,
    this.platformAmount,
    this.platformNetAmount,
    this.originalAmount,
    this.refundedAmount,
    this.paymentBreakdown = const {},
  });

  static num? _optionalNumber(dynamic value) {
    if (value is num && value.isFinite) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  static String? _optionalText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Map) {
      final seconds = _optionalNumber(value['_seconds'] ?? value['seconds']);
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      }
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['paymentBreakdown'];

    return Transaction(
      id: _optionalText(json['id']) ?? '',
      type: _optionalText(json['type']) ?? 'cash-in',
      amount: _optionalNumber(json['amount']) ?? 0,
      description: _optionalText(json['description']) ?? 'Tidak ada deskripsi',
      status: _optionalText(json['status']) ?? 'pending',
      timestamp: _parseTimestamp(json['timestamp']),
      orderId: _optionalText(json['orderId']),
      refundId: _optionalText(json['refundId']),
      paymentTarget: _optionalText(json['paymentTarget']),
      payoutReason: _optionalText(json['payoutReason']),
      destination: _optionalText(json['destination']),
      grossAmount: _optionalNumber(json['grossAmount']),
      initialGrossAmount: _optionalNumber(json['initialGrossAmount']),
      finalGrossAmount: _optionalNumber(json['finalGrossAmount']),
      customerPaidAmount: _optionalNumber(json['customerPaidAmount']),
      voucherDiscountAmount: _optionalNumber(json['voucherDiscountAmount']),
      platformAmount: _optionalNumber(json['platformAmount']),
      platformNetAmount: _optionalNumber(json['platformNetAmount']),
      originalAmount: _optionalNumber(json['originalAmount']),
      refundedAmount: _optionalNumber(json['refundedAmount']),
      paymentBreakdown: rawBreakdown is Map
          ? Map<String, dynamic>.from(rawBreakdown)
          : const {},
    );
  }

  bool get isIncome => type == 'cash-in' || type == 'cash-in-hold';

  bool get hasPayoutBreakdown => grossAmount != null && platformAmount != null;

  num? get platformFeePercent {
    final gross = grossAmount;
    final fee = platformAmount;
    if (gross == null || fee == null || gross <= 0 || fee < 0) return null;
    return (fee * 100) / gross;
  }
}

class Wallet {
  final num currentBalance;
  final num heldBalance;
  final bool withdrawalBlocked;
  final String? withdrawalBlockedReason;
  final List<Transaction> transactions;

  Wallet({
    required this.currentBalance,
    required this.heldBalance,
    this.withdrawalBlocked = false,
    this.withdrawalBlockedReason,
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    var transactionsList = json['transactions'] as List<dynamic>? ?? [];
    List<Transaction> parsedTransactions = transactionsList
        .map((i) => Transaction.fromJson(i))
        .toList();

    return Wallet(
      currentBalance: json['currentBalance'] ?? 0,
      heldBalance: json['heldBalance'] ?? 0,
      withdrawalBlocked: json['withdrawalBlocked'] == true,
      withdrawalBlockedReason: json['withdrawalBlockedReason']?.toString(),
      transactions: parsedTransactions,
    );
  }
}
