import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_model.dart';

class BookmarkService {
  static const String _bookmarksKey = 'user_bookmarks';

  // Get all bookmarks for current user
  Future<List<Bookmark>> getBookmarks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString('${_bookmarksKey}_$userId');

      if (bookmarksJson == null) return [];

      final List<dynamic> bookmarksList = jsonDecode(bookmarksJson);
      return bookmarksList.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  // Add bookmark
  Future<bool> addBookmark(String userId, Bookmark bookmark) async {
    try {
      final bookmarks = await getBookmarks(userId);

      // Check if already bookmarked
      if (bookmarks.any((b) => b.serviceId == bookmark.serviceId)) {
        return false; // Already bookmarked
      }

      bookmarks.add(bookmark);
      return await _saveBookmarks(userId, bookmarks);
    } catch (e) {
      print('Error adding bookmark: $e');
      return false;
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark(String userId, String serviceId) async {
    try {
      final bookmarks = await getBookmarks(userId);
      bookmarks.removeWhere((b) => b.serviceId == serviceId);
      return await _saveBookmarks(userId, bookmarks);
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }

  // Check if service is bookmarked
  Future<bool> isBookmarked(String userId, String serviceId) async {
    try {
      final bookmarks = await getBookmarks(userId);
      return bookmarks.any((b) => b.serviceId == serviceId);
    } catch (e) {
      print('Error checking bookmark: $e');
      return false;
    }
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String userId, Bookmark bookmark) async {
    final isCurrentlyBookmarked = await isBookmarked(
      userId,
      bookmark.serviceId,
    );

    if (isCurrentlyBookmarked) {
      return await removeBookmark(userId, bookmark.serviceId);
    } else {
      return await addBookmark(userId, bookmark);
    }
  }

  // Private method to save bookmarks
  Future<bool> _saveBookmarks(String userId, List<Bookmark> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = jsonEncode(
        bookmarks.map((b) => b.toJson()).toList(),
      );
      return await prefs.setString('${_bookmarksKey}_$userId', bookmarksJson);
    } catch (e) {
      print('Error saving bookmarks: $e');
      return false;
    }
  }

  // Clear all bookmarks for user
  Future<bool> clearBookmarks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('${_bookmarksKey}_$userId');
    } catch (e) {
      print('Error clearing bookmarks: $e');
      return false;
    }
  }
}
