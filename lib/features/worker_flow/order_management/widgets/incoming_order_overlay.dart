import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/services/incoming_order_sound_service.dart';
import '../../../../core/services/realtime_notification_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/utils/incoming_order_policy.dart';
import '../pages/order_detail_page.dart';

class WorkerIncomingOrderOverlay extends StatefulWidget {
  const WorkerIncomingOrderOverlay({
    super.key,
    this.apiService,
    this.alertController,
  });

  final ApiService? apiService;
  final IncomingOrderAlertController? alertController;

  @override
  State<WorkerIncomingOrderOverlay> createState() =>
      _WorkerIncomingOrderOverlayState();
}

class _WorkerIncomingOrderOverlayState extends State<WorkerIncomingOrderOverlay>
    with WidgetsBindingObserver {
  late final ApiService _apiService;
  late final IncomingOrderAlertController _alertController;
  late final bool _ownsAlertController;
  Timer? _countdownTimer;
  Timer? _retryTimer;
  String? _observedNotificationId;
  Order? _order;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _ownsAlertController = widget.alertController == null;
    _alertController = widget.alertController ?? IncomingOrderAlertController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _retryTimer?.cancel();
    if (_ownsAlertController) {
      _alertController.dispose();
    } else {
      unawaited(_alertController.stop());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_alertController.stop());
      return;
    }
    final notification = context
        .read<RealtimeNotificationService>()
        .incomingOrderNotification;
    if (notification != null) {
      _loadIncomingOrder(notification, force: true);
    }
  }

  void _observeCandidate(NotificationItem? notification) {
    final notificationId = notification?.id;
    if (_observedNotificationId == notificationId) return;
    _observedNotificationId = notificationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (notification == null) {
        _clearOrder();
      } else {
        _loadIncomingOrder(notification);
      }
    });
  }

  Future<void> _loadIncomingOrder(
    NotificationItem notification, {
    bool force = false,
  }) async {
    final auth = context.read<AuthProvider>();
    final workerId = auth.user?.uid;
    final token = auth.token;
    final orderId = notification.relatedId?.trim();
    if (workerId == null ||
        token == null ||
        orderId == null ||
        orderId.isEmpty) {
      return;
    }
    if (!force && _order?.id == orderId) return;

    final generation = ++_loadGeneration;
    _retryTimer?.cancel();
    try {
      final order = await _apiService.getOrderById(
        token: token,
        orderId: orderId,
      );
      if (!mounted || generation != _loadGeneration) return;

      if (!isIncomingOrderEligible(order, workerId: workerId)) {
        context.read<RealtimeNotificationService>().dismissIncomingOrder(
          orderId,
        );
        _clearOrder();
        return;
      }

      setState(() => _order = order);
      _startCountdown(order);
      unawaited(_alertController.showOrder(order.id));
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      _retryTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _observedNotificationId == notification.id) {
          _loadIncomingOrder(notification, force: true);
        }
      });
    }
  }

  void _startCountdown(Order order) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final deadline = _order?.workerAcceptanceDeadlineAt;
      if (deadline == null || !deadline.isAfter(DateTime.now())) {
        _dismissOrder(order.id);
      } else {
        setState(() {});
      }
    });
  }

  void _clearOrder() {
    _loadGeneration++;
    _countdownTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_alertController.stop());
    if (_order != null && mounted) setState(() => _order = null);
  }

  void _dismissOrder(String orderId) {
    context.read<RealtimeNotificationService>().dismissIncomingOrder(orderId);
    _clearOrder();
  }

  void _openOrder(Order order) {
    _dismissOrder(order.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notificationService = context.watch<RealtimeNotificationService>();
    final notification = auth.user?.role.toUpperCase() == 'WORKER'
        ? notificationService.incomingOrderNotification
        : null;
    _observeCandidate(notification);

    final order = _order;
    if (order == null || notification?.relatedId != order.id) {
      return const SizedBox.shrink();
    }

    final deadline = order.workerAcceptanceDeadlineAt!;
    final remaining = deadline.difference(DateTime.now());
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 12,
      right: 12,
      child: IncomingOrderCard(
        order: order,
        remaining: remaining,
        queuedOrderCount: notificationService.incomingOrderQueueLength,
        onDismiss: () => _dismissOrder(order.id),
        onOpen: () => _openOrder(order),
      ),
    );
  }
}

class IncomingOrderCard extends StatelessWidget {
  const IncomingOrderCard({
    super.key,
    required this.order,
    required this.remaining,
    required this.queuedOrderCount,
    required this.onDismiss,
    required this.onOpen,
  });

  final Order order;
  final Duration remaining;
  final int queuedOrderCount;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  String _formatPrice(num? value) {
    if (value == null) return 'Harga tercantum di detail';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12384B);
    const accent = Color(0xFFFFB020);
    return Material(
      key: const Key('incoming-order-card'),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.work_rounded, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesanan baru masuk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        queuedOrderCount > 1
                            ? '$queuedOrderCount pesanan menunggu dilihat'
                            : 'Segera periksa sebelum waktunya habis',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incomingOrderCountdown(remaining),
                    key: const Key('incoming-order-countdown'),
                    style: const TextStyle(
                      color: Color(0xFF18242B),
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              order.serviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _OrderMeta(
                  icon: Icons.schedule_rounded,
                  label: DateFormat(
                    'dd MMM, HH:mm',
                    'id_ID',
                  ).format(order.jadwalPerbaikan),
                ),
                _OrderMeta(
                  icon: Icons.payments_outlined,
                  label: order.serviceType.toLowerCase() == 'survey'
                      ? 'Biaya survei ${_formatPrice(order.quotedPrice)}'
                      : 'Nilai layanan ${_formatPrice(order.quotedPrice)}',
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('incoming-order-later'),
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Nanti'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('incoming-order-open'),
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Lihat & Terima',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
