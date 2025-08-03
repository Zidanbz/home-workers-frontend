import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/notification_model.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/services/realtime_notification_service.dart';

class RealtimeNotificationPage extends StatefulWidget {
  const RealtimeNotificationPage({super.key});

  @override
  State<RealtimeNotificationPage> createState() => _RealtimeNotificationPageState();
}

class _RealtimeNotificationPageState extends State<RealtimeNotificationPage> {
  late RealtimeNotificationService _notificationService;

  // Color Palette
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _notificationService = RealtimeNotificationService();
    _initializeRealtimeNotifications();
  }

  Future<void> _initializeRealtimeNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn && authProvider.user?.uid != null) {
      // Start listening to real-time notifications
      await _notificationService.startListening(
        authProvider.user!.uid,
        authProvider.token,
      );
    }
  }

  @override
  void dispose() {
    _notificationService.stopListening();
    super.dispose();
  }

  Future<void> _markAsRead(String notificationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _notificationService.markAsRead(notificationId, authProvider.token);
  }

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _notificationService.markAllAsRead(authProvider.token);
  }

  void _handleNotificationTap(NotificationItem notif) async {
    if (!notif.isRead) await _markAsRead(notif.id);

    // Navigate based on notification type
    switch (notif.type) {
      case 'service_approved':
      case 'service_rejected':
        Navigator.pushNamed(context, '/my-jobs');
        break;
      case 'new_order':
      case 'order_update':
        if (notif.relatedId != null) {
          Navigator.pushNamed(context, '/order-detail', arguments: notif.relatedId);
        } else {
          Navigator.pushNamed(context, '/orders');
        }
        break;
      case 'chat':
        if (notif.relatedId != null) {
          Navigator.pushNamed(context, '/chat', arguments: notif.relatedId);
        } else {
          Navigator.pushNamed(context, '/chat-list');
        }
        break;
      case 'promo':
      case 'broadcast':
        Navigator.pushNamed(context, '/marketplace');
        break;
      default:
        // Stay on notifications page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Notifikasi Real-time',
          style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
        ),
        backgroundColor: white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<RealtimeNotificationService>(
              builder: (context, service, child) {
                return IconButton(
                  onPressed: service.unreadCount > 0 ? _markAllAsRead : null,
                  icon: Icon(
                    Icons.done_all_rounded,
                    color: service.unreadCount > 0 ? primaryColor : Colors.grey,
                    size: 22,
                  ),
                  tooltip: 'Tandai semua sudah dibaca',
                );
              },
            ),
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _notificationService,
        child: Consumer<RealtimeNotificationService>(
          builder: (context, service, child) {
            final notifications = service.notifications;
            final unreadCount = service.unreadCount;

            if (notifications.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: lightGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 48,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum Ada Notifikasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Notifikasi real-time akan muncul di sini',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_rounded,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Real-time Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Header dengan statistik real-time
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${notifications.length} Notifikasi',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            if (unreadCount > 0)
                              Text(
                                '$unreadCount belum dibaca',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColor.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // List notifikasi real-time
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notif) {
    final timeFormatted = DateFormat(
      'dd MMM HH:mm',
      'id_ID',
    ).format(notif.timestamp);
    final isToday =
        DateFormat('yyyy-MM-dd').format(notif.timestamp) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timeDisplay = isToday
        ? DateFormat('HH:mm').format(notif.timestamp)
        : timeFormatted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: notif.isRead
            ? null
            : Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(notif.isRead ? 0.05 : 0.1),
            blurRadius: notif.isRead ? 8 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notif),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon dengan background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notif.iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(notif.icon, color: notif.iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                fontSize: 16,
                                color: primaryColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time dan status
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (notif.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: lightGray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Dibaca',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryColor.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Baru',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
