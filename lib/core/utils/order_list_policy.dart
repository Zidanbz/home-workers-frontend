const customerOngoingOrderStatuses = {
  'awaiting_payment',
  'pending',
  'accepted',
  'quote_proposed',
  'quote_revision_requested',
  'quote_accepted',
  'ready_to_start',
  'work_in_progress',
  'completion_submitted',
};

const customerHistoryOrderStatuses = {
  'completed',
  'cancelled',
  'quote_rejected',
  'worker_acceptance_expired',
};

const workerQueueOrderStatuses = {
  'pending',
  'accepted',
  'quote_proposed',
  'quote_revision_requested',
  'quote_accepted',
  'ready_to_start',
  'work_in_progress',
  'completion_submitted',
};

const workerHistoryOrderStatuses = {
  'completed',
  'cancelled',
  'quote_rejected',
  'rejected',
  'worker_acceptance_expired',
};

const refundStatusesShownInHistory = {
  'submitted',
  'awaiting_worker_response',
  'under_review',
  'more_evidence_required',
  'rework_offered',
  'approved',
  'awaiting_refund_destination',
  'approved_manual',
  'processing',
  'failed',
  'refunded',
};

bool shouldShowCustomerOrderInOngoing({
  required String orderStatus,
  String? refundStatus,
}) {
  if (refundStatus == 'rework_in_progress') {
    return true;
  }
  return !refundStatusesShownInHistory.contains(refundStatus) &&
      customerOngoingOrderStatuses.contains(orderStatus);
}

bool shouldShowCustomerOrderInHistory({
  required String orderStatus,
  String? refundStatus,
}) {
  return refundStatusesShownInHistory.contains(refundStatus) ||
      customerHistoryOrderStatuses.contains(orderStatus);
}

bool shouldShowWorkerOrderInQueue({
  required String orderStatus,
  String? refundStatus,
}) {
  if (refundStatus == 'rework_in_progress') {
    return true;
  }
  return !refundStatusesShownInHistory.contains(refundStatus) &&
      workerQueueOrderStatuses.contains(orderStatus);
}

bool shouldShowWorkerOrderInHistory({
  required String orderStatus,
  String? refundStatus,
}) {
  return refundStatusesShownInHistory.contains(refundStatus) ||
      workerHistoryOrderStatuses.contains(orderStatus);
}

bool isOrderWorkflowBlockedByRefund(String? refundStatus) {
  return refundStatusesShownInHistory.contains(refundStatus);
}

String effectiveCustomerOrderListStatus({
  required String orderStatus,
  String? refundStatus,
}) {
  if (refundStatus == 'rework_in_progress' ||
      refundStatusesShownInHistory.contains(refundStatus)) {
    return 'refund:$refundStatus';
  }
  return orderStatus;
}
