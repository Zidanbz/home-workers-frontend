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
  final bool chatAllowed;
  final String? chatBlockedReason;
  // final avatarUrl;

  Chat({
    required this.id,
    required this.lastMessage,
    this.lastMessageTimestamp,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.otherUserId,
    required this.unreadCount,
    this.chatAllowed = true,
    this.chatBlockedReason,
    // required this.avatarUrl,
  });

  // Factory constructor untuk membuat instance Chat dari JSON
  // Membutuhkan ID pengguna saat ini untuk menentukan siapa "lawan bicara"
  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    final members = List<String>.from(json['members'] ?? []);
    final memberInfo = json['memberInfo'] as Map<String, dynamic>? ?? {};

    // Temukan ID lawan bicara
    var otherUserId = members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Fallback untuk data lama: infer dari chat ID jika `members` tidak lengkap.
    if (otherUserId.isEmpty) {
      final chatId = (json['id'] ?? '').toString().trim();
      final parts = chatId
          .split('_')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (parts.length == 2) {
        otherUserId = parts.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
      }
    }

    // Ambil info lawan bicara
    final otherUserInfo =
        memberInfo[otherUserId] as Map<String, dynamic>? ?? {};

    String firstNonEmpty(List<dynamic> values, String fallback) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

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
      otherUserName: firstNonEmpty([
        otherUserInfo['nama'],
        otherUserInfo['name'],
        json['otherUserName'],
        (json['otherUser'] as Map<String, dynamic>?)?['nama'],
        (json['otherUser'] as Map<String, dynamic>?)?['name'],
      ], 'Pengguna tidak dikenal'),
      otherUserAvatarUrl: firstNonEmpty([
        otherUserInfo['avatarUrl'],
        otherUserInfo['photoUrl'],
        json['otherUserAvatarUrl'],
        (json['otherUser'] as Map<String, dynamic>?)?['avatarUrl'],
        (json['otherUser'] as Map<String, dynamic>?)?['photoUrl'],
      ], 'https://placehold.co/150x150/EFEFEF/AAAAAA?text=?'),
      otherUserId: otherUserId,
      unreadCount: count is int ? count : 0,
      chatAllowed: json['chatAllowed'] ?? true,
      chatBlockedReason: json['chatBlockedReason'],
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
