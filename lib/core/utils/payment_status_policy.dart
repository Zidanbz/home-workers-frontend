bool isPaidTransactionStatus(String? value) {
  final normalized = (value ?? '').toLowerCase();
  return normalized == 'settlement' ||
      normalized == 'capture' ||
      normalized == 'paid';
}

bool isFailedTransactionStatus(String? value) {
  final normalized = (value ?? '').toLowerCase();
  return normalized == 'deny' ||
      normalized == 'expire' ||
      normalized == 'cancel' ||
      normalized == 'failure';
}

bool isVerifiedPaymentStatus({
  required String requestedOrderId,
  required Map<String, dynamic> response,
  required bool Function(String? status) matchesStatus,
}) {
  final returnedOrderId = response['order_id']?.toString().trim();
  if (returnedOrderId == null || returnedOrderId != requestedOrderId) {
    return false;
  }

  final expectedTarget = requestedOrderId.startsWith('quote_')
      ? 'final_quote'
      : 'initial';
  final returnedTarget = response['payment_target']?.toString();
  if (returnedTarget != null && returnedTarget != expectedTarget) {
    return false;
  }

  return matchesStatus(response['transaction_status']?.toString());
}

bool isVerifiedPaidPayment({
  required String requestedOrderId,
  required Map<String, dynamic> response,
}) {
  return isVerifiedPaymentStatus(
    requestedOrderId: requestedOrderId,
    response: response,
    matchesStatus: isPaidTransactionStatus,
  );
}

bool isVerifiedFailedPayment({
  required String requestedOrderId,
  required Map<String, dynamic> response,
}) {
  return isVerifiedPaymentStatus(
    requestedOrderId: requestedOrderId,
    response: response,
    matchesStatus: isFailedTransactionStatus,
  );
}
