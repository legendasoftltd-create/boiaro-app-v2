import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_model.dart';

/// Service for storing and retrieving bookmarks from SharedPreferences
class BookmarkStorageService {
  static const String _keyPrefix = 'book_bookmarks_';

  /// Get all bookmarks for a specific book
  static Future<List<BookmarkModel>> getBookmarksForBook(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$bookId';
      final jsonString = prefs.getString(key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => BookmarkModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading bookmarks: $e');
      return [];
    }
  }

  /// Get all bookmarks (across all books)
  static Future<List<BookmarkModel>> getAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
      final List<BookmarkModel> allBookmarks = [];
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(jsonString);
          allBookmarks.addAll(
            jsonList.map((json) => BookmarkModel.fromJson(json as Map<String, dynamic>)),
          );
        }
      }
      
      return allBookmarks;
    } catch (e) {
      print('Error loading all bookmarks: $e');
      return [];
    }
  }

  /// Save a bookmark
  static Future<bool> saveBookmark(BookmarkModel bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix${bookmark.bookId}';
      
      // Get existing bookmarks for this book
      final existingBookmarks = await getBookmarksForBook(bookmark.bookId);
      
      // Remove duplicate if exists (same ID)
      existingBookmarks.removeWhere((b) => b.id == bookmark.id);
      
      // Add new bookmark
      existingBookmarks.add(bookmark);
      
      // Sort by creation date (newest first)
      existingBookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Save back to SharedPreferences
      final jsonList = existingBookmarks.map((b) => b.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error saving bookmark: $e');
      return false;
    }
  }

  /// Delete a bookmark
  static Future<bool> deleteBookmark(BookmarkModel bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix${bookmark.bookId}';
      
      // Get existing bookmarks for this book
      final existingBookmarks = await getBookmarksForBook(bookmark.bookId);
      
      // Remove the bookmark
      existingBookmarks.removeWhere((b) => b.id == bookmark.id);
      
      // Save back to SharedPreferences
      final jsonList = existingBookmarks.map((b) => b.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error deleting bookmark: $e');
      return false;
    }
  }

  /// Delete all bookmarks for a book
  static Future<bool> deleteAllBookmarksForBook(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$bookId';
      return await prefs.remove(key);
    } catch (e) {
      print('Error deleting all bookmarks: $e');
      return false;
    }
  }

  /// Get bookmarks for a specific chapter
  static Future<List<BookmarkModel>> getBookmarksForChapter(
    String bookId,
    String chapterId,
  ) async {
    final allBookmarks = await getBookmarksForBook(bookId);
    return allBookmarks.where((b) => b.chapterId == chapterId).toList();
  }
}

