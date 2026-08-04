import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final parsedTimestamp =
        _parseTimestamp(json['timestamp']) ?? DateTime.now();
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

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    // Firestore JSON-like timestamp format (REST/serialized): { _seconds: ..., _nanoseconds: ... }
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      }
    }

    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      // Heuristic: treat large ints as milliseconds, small as seconds.
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return null;
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
      case 'order_update':
        return Icons.receipt_long_outlined;
      case 'warranty_update':
        return Icons.verified_user_outlined;
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
      case 'order_update':
        return Colors.deepPurple;
      case 'warranty_update':
        return Colors.green.shade700;
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
