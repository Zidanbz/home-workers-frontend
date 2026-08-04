class PaymentInvoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String paymentTarget;
  final String status;
  final String currency;
  final num subtotal;
  final num discount;
  final num total;
  final String? appliedVoucher;
  final String customerName;
  final String? customerEmail;
  final String workerName;
  final String serviceName;
  final String? serviceType;
  final String? paymentType;
  final String? transactionId;
  final String? midtransOrderId;
  final DateTime paidAt;

  const PaymentInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.paymentTarget,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.customerName,
    required this.workerName,
    required this.serviceName,
    required this.paidAt,
    this.appliedVoucher,
    this.customerEmail,
    this.serviceType,
    this.paymentType,
    this.transactionId,
    this.midtransOrderId,
  });

  factory PaymentInvoice.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Map && value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as num).toInt() * 1000,
        ).toLocal();
      }
      if (value is DateTime) {
        return value.isUtc ? value.toLocal() : value;
      }
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : (parsed.isUtc ? parsed.toLocal() : parsed);
    }

    num parseMoney(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;

    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : const <String, dynamic>{};
    final worker = json['worker'] is Map
        ? Map<String, dynamic>.from(json['worker'] as Map)
        : const <String, dynamic>{};
    final service = json['service'] is Map
        ? Map<String, dynamic>.from(json['service'] as Map)
        : const <String, dynamic>{};
    final payment = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : const <String, dynamic>{};

    return PaymentInvoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      paymentTarget: json['paymentTarget']?.toString() ?? 'initial',
      status: json['status']?.toString() ?? 'paid',
      currency: json['currency']?.toString() ?? 'IDR',
      subtotal: parseMoney(json['subtotal']),
      discount: parseMoney(json['discount']),
      total: parseMoney(json['total']),
      appliedVoucher: json['appliedVoucher']?.toString(),
      customerName: customer['name']?.toString() ?? 'Customer',
      customerEmail: customer['email']?.toString(),
      workerName: worker['name']?.toString() ?? 'Worker',
      serviceName: service['name']?.toString() ?? 'Layanan Home Workers',
      serviceType: service['type']?.toString(),
      paymentType: payment['paymentType']?.toString(),
      transactionId: payment['transactionId']?.toString(),
      midtransOrderId: payment['midtransOrderId']?.toString(),
      paidAt: parseDate(payment['paidAt'] ?? json['issuedAt']),
    );
  }

  String get paymentTargetLabel =>
      paymentTarget == 'final_quote' ? 'Pembayaran Final' : 'Pembayaran Awal';

  String get paymentTypeLabel {
    const labels = {
      'bank_transfer': 'Transfer Bank / Virtual Account',
      'credit_card': 'Kartu Kredit',
      'gopay': 'GoPay',
      'qris': 'QRIS',
      'echannel': 'Mandiri Bill Payment',
      'cstore': 'Gerai Retail',
    };
    return labels[paymentType] ?? paymentType ?? 'Metode pembayaran';
  }
}
