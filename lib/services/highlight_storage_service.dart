// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/highlight_model.dart';

// /// Service for storing and retrieving highlights from SharedPreferences
// class HighlightStorageService {
//   static const String _keyPrefix = 'book_highlights_';

//   /// Get all highlights for a specific book
//   static Future<List<HighlightModel>> getHighlightsForBook(String bookId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final key = '$_keyPrefix$bookId';
//       final jsonString = prefs.getString(key);
      
//       if (jsonString == null || jsonString.isEmpty) {
//         return [];
//       }

//       final List<dynamic> jsonList = json.decode(jsonString);
//       return jsonList
//           .map((json) => HighlightModel.fromJson(json as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       print('Error loading highlights: $e');
//       return [];
//     }
//   }

//   /// Get all highlights (across all books)
//   static Future<List<HighlightModel>> getAllHighlights() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      
//       final List<HighlightModel> allHighlights = [];
//       for (final key in keys) {
//         final jsonString = prefs.getString(key);
//         if (jsonString != null && jsonString.isNotEmpty) {
//           final List<dynamic> jsonList = json.decode(jsonString);
//           allHighlights.addAll(
//             jsonList.map((json) => HighlightModel.fromJson(json as Map<String, dynamic>)),
//           );
//         }
//       }
      
//       return allHighlights;
//     } catch (e) {
//       print('Error loading all highlights: $e');
//       return [];
//     }
//   }

//   /// Save a highlight
//   static Future<bool> saveHighlight(HighlightModel highlight) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final key = '$_keyPrefix${highlight.bookId}';
      
//       // Get existing highlights for this book
//       final existingHighlights = await getHighlightsForBook(highlight.bookId);
      
//       // Remove duplicate if exists (same ID)
//       existingHighlights.removeWhere((h) => h.id == highlight.id);
      
//       // Add new highlight
//       existingHighlights.add(highlight);
      
//       // Sort by creation date (newest first)
//       existingHighlights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
//       // Save back to SharedPreferences
//       final jsonList = existingHighlights.map((h) => h.toJson()).toList();
//       final jsonString = json.encode(jsonList);
      
//       return await prefs.setString(key, jsonString);
//     } catch (e) {
//       print('Error saving highlight: $e');
//       return false;
//     }
//   }

//   /// Delete a highlight
//   static Future<bool> deleteHighlight(HighlightModel highlight) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final key = '$_keyPrefix${highlight.bookId}';
      
//       // Get existing highlights for this book
//       final existingHighlights = await getHighlightsForBook(highlight.bookId);
      
//       // Remove the highlight
//       existingHighlights.removeWhere((h) => h.id == highlight.id);
      
//       // Save back to SharedPreferences
//       final jsonList = existingHighlights.map((h) => h.toJson()).toList();
//       final jsonString = json.encode(jsonList);
      
//       return await prefs.setString(key, jsonString);
//     } catch (e) {
//       print('Error deleting highlight: $e');
//       return false;
//     }
//   }

//   /// Delete all highlights for a book
//   static Future<bool> deleteAllHighlightsForBook(String bookId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final key = '$_keyPrefix$bookId';
//       return await prefs.remove(key);
//     } catch (e) {
//       print('Error deleting all highlights: $e');
//       return false;
//     }
//   }

//   /// Get highlights for a specific chapter
//   static Future<List<HighlightModel>> getHighlightsForChapter(
//     String bookId,
//     String chapterId,
//   ) async {
//     final allHighlights = await getHighlightsForBook(bookId);
//     return allHighlights.where((h) => h.chapterId == chapterId).toList();
//   }
// }

