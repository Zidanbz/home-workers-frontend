import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import '../api/api_service.dart';
import '../navigation/app_navigator.dart';
import '../utils/notification_sound_policy.dart';

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
  bool _hasNotificationBaseline = false;
  final List<NotificationItem> _incomingOrderQueue = [];
  final Set<String> _dismissedIncomingOrderIds = {};
  final Map<String, DateTime> _recentForegroundFcmOrders = {};

  // Getters
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isInitialized => _isInitialized;
  NotificationItem? get incomingOrderNotification =>
      _incomingOrderQueue.isEmpty ? null : _incomingOrderQueue.first;
  int get incomingOrderQueueLength => _incomingOrderQueue.length;

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
      generalNotificationChannelId,
      'Notifikasi Umum',
      description: 'Notifications for Home Workers app',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        generalNotificationSoundResource,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    const newOrderChannel = AndroidNotificationChannel(
      newOrderNotificationChannelId,
      'Pesanan Baru',
      description: 'Notifikasi prioritas tinggi untuk pesanan Worker baru',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(
        newOrderNotificationSoundResource,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(newOrderChannel);
  }

  /// Initialize FCM
  Future<void> _initializeFCM() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      print('🔔 [FCM] Disabled on iOS for now');
      return;
    }

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
  Future<void> stopListening({bool clearData = false}) async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    _hasNotificationBaseline = false;
    if (clearData && _notifications.isNotEmpty) {
      _notifications = [];
    }
    if (clearData) {
      _incomingOrderQueue.clear();
      _dismissedIncomingOrderIds.clear();
      _recentForegroundFcmOrders.clear();
    }
    if (clearData) notifyListeners();
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
      final isInitialSnapshot = !_hasNotificationBaseline;

      // Update state
      _notifications = newNotifications;

      final incomingCandidates = isInitialSnapshot
          ? newNotifications.where(_canQueueIncomingOrder)
          : newNotifications.where(
              (notification) =>
                  addedIds.contains(notification.id) &&
                  _canQueueIncomingOrder(notification),
            );
      for (final notification in incomingCandidates) {
        _enqueueIncomingOrder(notification);
      }
      _hasNotificationBaseline = true;
      notifyListeners();

      // Show local notifications for new items
      for (final notification in newNotifications) {
        if (!isInitialSnapshot &&
            addedIds.contains(notification.id) &&
            !notification.isRead &&
            !_wasRecentlyShownByFcm(notification)) {
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

    final type = message.data['type']?.toString() ?? 'general';
    final relatedId = message.data['relatedId']?.toString();
    final wasRecentlyShown =
        relatedId != null && _wasOrderRecentlyShown(relatedId);
    if (type == 'new_order' && relatedId != null && relatedId.isNotEmpty) {
      _recentForegroundFcmOrders[relatedId] = DateTime.now();
      _enqueueIncomingOrder(
        NotificationItem(
          id: message.messageId ?? 'fcm-$relatedId',
          title: message.notification?.title ?? 'Order baru masuk',
          body:
              message.notification?.body ??
              'Ada pesanan baru yang menunggu konfirmasi.',
          timestamp: DateTime.now(),
          isRead: false,
          type: type,
          relatedId: relatedId,
          data: Map<String, dynamic>.from(message.data),
        ),
      );
      notifyListeners();
    }

    // Show local notification
    if (!wasRecentlyShown) _showLocalNotificationFromFCM(message);

    // The Firestore listener will automatically update the UI
    // when the notification is saved to Firestore by the backend
  }

  /// Handle background notification tap
  void _handleBackgroundNotificationTap(RemoteMessage message) {
    print('🔔 [FCM] Notification tapped: ${message.messageId}');
    _openNotification(message.data);
  }

  /// Handle local notification tap
  void _handleNotificationTap(NotificationResponse response) {
    print('🔔 [Local] Notification tapped: ${response.id}');
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('|');
    _openNotification({
      'type': parts.isNotEmpty ? parts.first : 'general',
      'relatedId': parts.length > 1 ? parts[1] : '',
    });
  }

  void _openNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final relatedId = data['relatedId']?.toString();
    if (type == 'new_order' && relatedId != null) {
      AppNavigator.openOrder(relatedId);
    }
  }

  bool _canQueueIncomingOrder(NotificationItem notification) {
    final orderId = notification.relatedId?.trim();
    if (notification.type != 'new_order' ||
        notification.isRead ||
        orderId == null ||
        orderId.isEmpty ||
        _dismissedIncomingOrderIds.contains(orderId)) {
      return false;
    }

    final rawDeadline = notification.data['acceptanceDeadlineAt']?.toString();
    final deadline = rawDeadline == null
        ? null
        : DateTime.tryParse(rawDeadline);
    if (deadline != null) return deadline.isAfter(DateTime.now());

    return notification.timestamp.isAfter(
      DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  void _enqueueIncomingOrder(NotificationItem notification) {
    if (!_canQueueIncomingOrder(notification)) return;
    final orderId = notification.relatedId!.trim();
    _incomingOrderQueue.removeWhere(
      (item) => item.relatedId?.trim() == orderId,
    );
    _incomingOrderQueue.insert(0, notification);
    _incomingOrderQueue.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  bool _wasRecentlyShownByFcm(NotificationItem notification) {
    final orderId = notification.relatedId?.trim();
    if (notification.type != 'new_order' || orderId == null) return false;
    return _wasOrderRecentlyShown(orderId);
  }

  bool _wasOrderRecentlyShown(String orderId) {
    final shownAt = _recentForegroundFcmOrders[orderId];
    if (shownAt == null) return false;
    return DateTime.now().difference(shownAt) < const Duration(seconds: 30);
  }

  void dismissIncomingOrder(String orderId) {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) return;
    _dismissedIncomingOrderIds.add(normalizedOrderId);
    _incomingOrderQueue.removeWhere(
      (item) => item.relatedId?.trim() == normalizedOrderId,
    );
    notifyListeners();
  }

  /// Show local notification
  void _showLocalNotification(NotificationItem notification) {
    if (notification.type == 'new_order' && notification.relatedId != null) {
      _recentForegroundFcmOrders[notification.relatedId!.trim()] =
          DateTime.now();
    }
    _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelIdFor(notification.type),
          notification.type == 'new_order'
              ? 'Pesanan Baru'
              : 'Home Workers Notifications',
          channelDescription: 'Notifications for Home Workers app',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
            notificationSoundResourceFor(notification.type),
          ),
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelIdFor(message.data['type']?.toString()),
          message.data['type'] == 'new_order'
              ? 'Pesanan Baru'
              : 'Home Workers Notifications',
          channelDescription: 'Notifications for Home Workers app',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
            notificationSoundResourceFor(message.data['type']?.toString()),
          ),
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
          data: _notifications[index].data,
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) return null;

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
