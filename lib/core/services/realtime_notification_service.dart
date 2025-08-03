import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import '../api/api_service.dart';

class RealtimeNotificationService extends ChangeNotifier {
  static final RealtimeNotificationService _instance =
      RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  // State
  List<NotificationItem> _notifications = [];
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  String? _currentUserId;
  bool _isInitialized = false;

  // Getters
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isInitialized => _isInitialized;

  /// Initialize notification service
  static Future<void> initialize() async {
    final instance = RealtimeNotificationService();
    await instance._initializeLocalNotifications();
    await instance._initializeFCM();
    instance._isInitialized = true;
    print('🔔 [RealtimeNotificationService] Initialized successfully');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'home_workers_channel',
      'Home Workers Notifications',
      description: 'Notifications for Home Workers app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Initialize FCM
  Future<void> _initializeFCM() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleBackgroundNotificationTap,
    );

    // Handle initial message if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundNotificationTap(initialMessage);
    }

    print('🔔 [FCM] Initialized successfully');
  }

  /// Start listening to user's notifications in real-time
  Future<void> startListening(String userId, String? token) async {
    if (_currentUserId == userId && _notificationSubscription != null) {
      print(
        '🔔 [RealtimeNotificationService] Already listening for user: $userId',
      );
      return;
    }

    // Stop previous subscription
    await stopListening();

    _currentUserId = userId;
    print(
      '🔔 [RealtimeNotificationService] Starting real-time listener for user: $userId',
    );

    // Listen to Firestore notifications collection in real-time
    _notificationSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to prevent excessive data usage
        .snapshots()
        .listen(
          (snapshot) => _handleNotificationSnapshot(snapshot, token),
          onError: (error) {
            print(
              '❌ [RealtimeNotificationService] Error listening to notifications: $error',
            );
          },
        );

    print(
      '✅ [RealtimeNotificationService] Real-time listener started successfully',
    );
  }

  /// Stop listening to notifications
  Future<void> stopListening() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    print(
      '🔔 [RealtimeNotificationService] Stopped listening to notifications',
    );
  }

  /// Handle Firestore notification snapshot changes
  void _handleNotificationSnapshot(QuerySnapshot snapshot, String? token) {
    try {
      final List<NotificationItem> newNotifications = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID

          final notification = NotificationItem.fromJson(data);
          newNotifications.add(notification);
        } catch (e) {
          print(
            '❌ [RealtimeNotificationService] Error parsing notification: $e',
          );
        }
      }

      // Check for new notifications (for local notification display)
      final previousIds = _notifications.map((n) => n.id).toSet();
      final newIds = newNotifications.map((n) => n.id).toSet();
      final addedIds = newIds.difference(previousIds);

      // Update state
      _notifications = newNotifications;
      notifyListeners();

      // Show local notifications for new items
      for (final notification in newNotifications) {
        if (addedIds.contains(notification.id) && !notification.isRead) {
          _showLocalNotification(notification);
        }
      }

      print(
        '✅ [RealtimeNotificationService] Updated ${newNotifications.length} notifications, ${addedIds.length} new',
      );
    } catch (e) {
      print(
        '❌ [RealtimeNotificationService] Error handling notification snapshot: $e',
      );
    }
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 [FCM] Received foreground message: ${message.messageId}');

    // Show local notification
    _showLocalNotificationFromFCM(message);

    // The Firestore listener will automatically update the UI
    // when the notification is saved to Firestore by the backend
  }

  /// Handle background notification tap
  void _handleBackgroundNotificationTap(RemoteMessage message) {
    print('🔔 [FCM] Notification tapped: ${message.messageId}');
    // Navigation will be handled by the UI layer
  }

  /// Handle local notification tap
  void _handleNotificationTap(NotificationResponse response) {
    print('🔔 [Local] Notification tapped: ${response.id}');
    // Navigation will be handled by the UI layer
  }

  /// Show local notification
  void _showLocalNotification(NotificationItem notification) {
    _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'home_workers_channel',
          'Home Workers Notifications',
          channelDescription: 'Notifications for Home Workers app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/notification_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '${notification.type}|${notification.relatedId ?? ''}',
    );
  }

  /// Show local notification from FCM message
  void _showLocalNotificationFromFCM(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.messageId.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'home_workers_channel',
          'Home Workers Notifications',
          channelDescription: 'Notifications for Home Workers app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/notification_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload:
          '${message.data['type'] ?? 'general'}|${message.data['relatedId'] ?? ''}',
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId, String? token) async {
    if (token == null || _currentUserId == null) return;

    try {
      // Update in backend
      await _apiService.markNotificationAsRead(
        token: token,
        notificationId: notificationId,
      );

      // Update local state immediately for better UX
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          timestamp: _notifications[index].timestamp,
          isRead: true, // Mark as read
          type: _notifications[index].type,
          relatedId: _notifications[index].relatedId,
        );
        notifyListeners();
      }

      print(
        '✅ [RealtimeNotificationService] Marked notification as read: $notificationId',
      );
    } catch (e) {
      print(
        '❌ [RealtimeNotificationService] Error marking notification as read: $e',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String? token) async {
    if (token == null || _currentUserId == null) return;

    try {
      // Update all unread notifications in Firestore
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId!)
            .collection('notifications')
            .doc(notification.id);

        batch.update(docRef, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ [RealtimeNotificationService] Marked all notifications as read');
    } catch (e) {
      print(
        '❌ [RealtimeNotificationService] Error marking all notifications as read: $e',
      );
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ [RealtimeNotificationService] Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ [RealtimeNotificationService] Subscribed to topic: $topic');
    } catch (e) {
      print('❌ [RealtimeNotificationService] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ [RealtimeNotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      print(
        '❌ [RealtimeNotificationService] Error unsubscribing from topic: $e',
      );
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
