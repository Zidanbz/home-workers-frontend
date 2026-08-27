import '../models/order_model.dart';

bool isIncomingOrderEligible(
  Order order, {
  required String workerId,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final deadline = order.workerAcceptanceDeadlineAt;

  return order.workerId == workerId &&
      order.status.toLowerCase() == 'pending' &&
      order.paymentStatus?.toLowerCase() == 'paid' &&
      order.workerAccess &&
      order.workerAcceptanceState?.toLowerCase() != 'accepted' &&
      order.workerAcceptanceState?.toLowerCase() != 'expired' &&
      deadline != null &&
      deadline.isAfter(currentTime);
}

String incomingOrderCountdown(Duration remaining) {
  if (remaining <= Duration.zero) return '00:00';
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = remaining.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
