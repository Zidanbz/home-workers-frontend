import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../api/api_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Services
  final ApiService _apiService = ApiService();

  // State
  List<Chat> _chats = [];
  Timer? _chatPollingTimer;
  String? _currentUserId;
  String? _currentToken;
  bool _isInitialized = false;
  bool _refreshInProgress = false;
  int _syncGeneration = 0;

  // Getters
  List<Chat> get chats => _chats;
  int get unreadChatCount =>
      _chats.where((chat) => chat.unreadCount > 0).length;
  int get totalUnreadMessages =>
      _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  bool get isInitialized => _isInitialized;

  /// Initialize chat service
  static Future<void> initialize() async {
    final instance = ChatService();
    instance._isInitialized = true;
    print('💬 [ChatService] Initialized successfully');
  }

  /// Start listening to user's chats in real-time
  Future<void> startListening(String userId, String? token) async {
    if (_currentUserId == userId && _chatPollingTimer != null) {
      print('💬 [ChatService] Already syncing for user: $userId');
      return;
    }

    // Stop previous subscription
    await stopListening();

    final generation = ++_syncGeneration;
    _currentUserId = userId;
    _currentToken = token;
    print('💬 [ChatService] Starting chat synchronization for user: $userId');

    try {
      // Load initial chats from API
      if (token != null) {
        final chats = await _apiService.getMyChats(token, userId);
        if (generation != _syncGeneration || _currentUserId != userId) return;
        _chats = chats;
        notifyListeners();
        print('💬 [ChatService] Loaded ${_chats.length} chats from API');
      }

      // Sinkronisasi melalui API menjaga aturan otorisasi tetap berada di
      // backend dan tidak bergantung pada Firestore Rules milik client.
      if (generation != _syncGeneration) return;
      _chatPollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        unawaited(refreshChats(_currentToken));
      });

      print('✅ [ChatService] API synchronization started successfully');
    } catch (e) {
      print('❌ [ChatService] Error starting chat listener: $e');
    }
  }

  /// Stop listening to chats
  Future<void> stopListening({bool clearData = false}) async {
    _syncGeneration++;
    _chatPollingTimer?.cancel();
    _chatPollingTimer = null;
    _currentUserId = null;
    _currentToken = null;
    _refreshInProgress = false;
    if (clearData && _chats.isNotEmpty) {
      _chats = [];
      notifyListeners();
    }
    print('💬 [ChatService] Stopped listening to chats');
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
    if (token == null || _currentUserId == null || _refreshInProgress) return;

    final generation = _syncGeneration;
    final userId = _currentUserId!;
    _refreshInProgress = true;
    try {
      final chats = await _apiService.getMyChats(token, userId);
      if (generation != _syncGeneration || _currentUserId != userId) return;
      _chats = chats;
      notifyListeners();
      print('✅ [ChatService] Refreshed ${_chats.length} chats');
    } catch (e) {
      print('❌ [ChatService] Error refreshing chats: $e');
    } finally {
      if (generation == _syncGeneration) {
        _refreshInProgress = false;
      }
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
