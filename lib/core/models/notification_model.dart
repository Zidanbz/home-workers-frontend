import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? relatedId; 

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.relatedId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    if (json['timestamp'] != null && json['timestamp']['_seconds'] != null) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        json['timestamp']['_seconds'] * 1000,
      );
    } else {
      parsedTimestamp = DateTime.now();
    }
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: parsedTimestamp,
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? '',
      relatedId: json['relatedId'],
    );
  }

  // Helper untuk mendapatkan ikon dan warna berdasarkan tipe notifikasi
  IconData get icon {
    switch (type) {
      case 'service_approved':
        return Icons.check_circle_outline;
      case 'service_rejected':
        return Icons.cancel_outlined;
      case 'new_order':
        return Icons.receipt_long_outlined;
      case 'promo':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'service_approved':
        return Colors.green.shade700;
      case 'service_rejected':
        return Colors.red.shade700;
      case 'new_order':
        return Colors.deepPurple;
      case 'promo':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }
}
