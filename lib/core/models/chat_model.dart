import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Chat {
  final String id;
  final String lastMessage;
  final DateTime? lastMessageTimestamp;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String otherUserId; // Kita butuh ID lawan bicara
  final int unreadCount;
  // final avatarUrl;

  Chat({
    required this.id,
    required this.lastMessage,
    this.lastMessageTimestamp,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.otherUserId,
    required this.unreadCount,
    // required this.avatarUrl,
  });

  // Factory constructor untuk membuat instance Chat dari JSON
  // Membutuhkan ID pengguna saat ini untuk menentukan siapa "lawan bicara"
  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    final members = List<String>.from(json['members'] ?? []);
    final memberInfo = json['memberInfo'] as Map<String, dynamic>? ?? {};

    // Temukan ID lawan bicara
    String otherUserId = members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Ambil info lawan bicara
    final otherUserInfo =
        memberInfo[otherUserId] as Map<String, dynamic>? ?? {};

    // Parsing timestamp dari format Firestore
    DateTime? timestamp;
    if (json['lastMessageTimestamp'] != null &&
        json['lastMessageTimestamp']['_seconds'] != null) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        json['lastMessageTimestamp']['_seconds'] * 1000,
      );
    }

    final unreadCounts = json['unreadCount'] as Map<String, dynamic>? ?? {};
    final count = unreadCounts[currentUserId] ?? 0;

    return Chat(
      id: json['id'] ?? '',
      lastMessage: json['lastMessage'] ?? 'Tidak ada pesan',
      lastMessageTimestamp: timestamp,
      otherUserName: otherUserInfo['nama'] ?? 'Pengguna tidak dikenal',
      otherUserAvatarUrl:
          otherUserInfo['avatarUrl'] ??
          'https://placehold.co/150x150/EFEFEF/AAAAAA?text=?',
      otherUserId: otherUserId,
      unreadCount: count is int ? count : 0,
      // avatarUrl: json['avatarUrl'],
    );
  }

  // Helper untuk format waktu
  String get formattedTimestamp {
    if (lastMessageTimestamp == null) return '';
    // Jika hari ini, tampilkan jam. Jika tidak, tampilkan tanggal.
    if (DateUtils.isSameDay(lastMessageTimestamp, DateTime.now())) {
      return DateFormat('HH:mm').format(lastMessageTimestamp!);
    } else {
      return DateFormat('dd/MM/yy').format(lastMessageTimestamp!);
    }
  }
}
