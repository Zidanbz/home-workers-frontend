import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/state/auth_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService _apiService = ApiService();
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _notificationsFuture = _apiService.getMyNotifications(
          authProvider.token!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: FutureBuilder<List<NotificationItem>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada notifikasi.'));
            }

            final notifications = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 20.0,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: notification.iconColor.withOpacity(0.1),
        child: Icon(notification.icon, color: notification.iconColor, size: 28),
      ),
      title: Text(
        notification.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(notification.body),
      ),
      trailing: Text(
        notification.timeAgo,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {},
    );
  }
}
