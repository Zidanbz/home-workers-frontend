import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../api/api_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  // State
  List<Chat> _chats = [];
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  String? _currentUserId;
  bool _isInitialized = false;

  // Getters
  List<Chat> get chats => _chats;
  int get unreadChatCount => _chats.where((chat) => chat.unreadCount > 0).length;
  int get totalUnreadMessages => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  bool get isInitialized => _isInitialized;

  /// Initialize chat service
  static Future<void> initialize() async {
    final instance = ChatService();
    instance._isInitialized = true;
    print('💬 [ChatService] Initialized successfully');
  }

  /// Start listening to user's chats in real-time
  Future<void> startListening(String userId, String? token) async {
    if (_currentUserId == userId && _chatSubscription != null) {
      print('💬 [ChatService] Already listening for user: $userId');
      return;
    }

    // Stop previous subscription
    await stopListening();

    _currentUserId = userId;
    print('💬 [ChatService] Starting real-time listener for user: $userId');

    try {
      // Load initial chats from API
      if (token != null) {
        _chats = await _apiService.getMyChats(token, userId);
        notifyListeners();
        print('💬 [ChatService] Loaded ${_chats.length} chats from API');
      }

      // Listen to Firestore chats collection for real-time updates
      _chatSubscription = _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen(
            (snapshot) => _handleChatSnapshot(snapshot, userId),
            onError: (error) {
              print('❌ [ChatService] Error listening to chats: $error');
            },
          );

      print('✅ [ChatService] Real-time listener started successfully');
    } catch (e) {
      print('❌ [ChatService] Error starting chat listener: $e');
    }
  }

  /// Stop listening to chats
  Future<void> stopListening() async {
    await _chatSubscription?.cancel();
    _chatSubscription = null;
    _currentUserId = null;
    print('💬 [ChatService] Stopped listening to chats');
  }

  /// Handle Firestore chat snapshot changes
  void _handleChatSnapshot(QuerySnapshot snapshot, String currentUserId) {
    try {
      final List<Chat> updatedChats = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID
          
          final chat = Chat.fromJson(data, currentUserId);
          updatedChats.add(chat);
        } catch (e) {
          print('❌ [ChatService] Error parsing chat: $e');
        }
      }

      // Update state
      _chats = updatedChats;
      notifyListeners();

      print('✅ [ChatService] Updated ${updatedChats.length} chats, ${unreadChatCount} unread');
    } catch (e) {
      print('❌ [ChatService] Error handling chat snapshot: $e');
    }
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId, String? token) async {
    if (token == null || _currentUserId == null) return;

    try {
      // Update in backend
      await _apiService.markChatAsRead(token, chatId);

      // Update local state immediately for better UX
      final index = _chats.indexWhere((chat) => chat.id == chatId);
      if (index != -1) {
        _chats[index] = Chat(
          id: _chats[index].id,
          otherUserName: _chats[index].otherUserName,
          otherUserAvatarUrl: _chats[index].otherUserAvatarUrl,
          otherUserId: _chats[index].otherUserId,
          lastMessage: _chats[index].lastMessage,
          lastMessageTimestamp: _chats[index].lastMessageTimestamp,
          unreadCount: 0, // Mark as read
        );
        notifyListeners();
      }

      print('✅ [ChatService] Marked chat as read: $chatId');
    } catch (e) {
      print('❌ [ChatService] Error marking chat as read: $e');
    }
  }

  /// Refresh chats from API
  Future<void> refreshChats(String? token) async {
    if (token == null || _currentUserId == null) return;

    try {
      _chats = await _apiService.getMyChats(token, _currentUserId!);
      notifyListeners();
      print('✅ [ChatService] Refreshed ${_chats.length} chats');
    } catch (e) {
      print('❌ [ChatService] Error refreshing chats: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
