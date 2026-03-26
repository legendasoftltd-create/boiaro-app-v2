import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalReadingProgress {
  LocalReadingProgress({
    required this.bookId,
    required this.percent,
    required this.updatedAtMillis,
    required this.name,
    required this.imageUrl,
    required this.author,
    required this.contentType,
  });

  final String bookId;
  final double percent;
  final int updatedAtMillis;
  final String name;
  final String imageUrl;
  final String author;
  final String contentType;

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'percent': percent,
      'updatedAtMillis': updatedAtMillis,
      'name': name,
      'imageUrl': imageUrl,
      'author': author,
      'contentType': contentType,
    };
  }

  static LocalReadingProgress fromMap(Map<String, dynamic> map) {
    return LocalReadingProgress(
      bookId: (map['bookId'] ?? '').toString(),
      percent: double.tryParse((map['percent'] ?? '0').toString()) ?? 0.0,
      updatedAtMillis:
          int.tryParse((map['updatedAtMillis'] ?? '0').toString()) ?? 0,
      name: (map['name'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      author: (map['author'] ?? '').toString(),
      contentType: (map['contentType'] ?? '').toString(),
    );
  }
}

class ReadingProgressService {
  static const String _progressKey = 'ff_local_reading_progress_v1';

  static Future<Map<String, LocalReadingProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return {};
      }
      final items = decoded
          .whereType<Map>()
          .map((e) => LocalReadingProgress.fromMap(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .where((e) => e.bookId.isNotEmpty)
          .toList();

      final map = <String, LocalReadingProgress>{};
      for (final item in items) {
        map[item.bookId] = item;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<LocalReadingProgress?> getProgressByBookId(
      String bookId) async {
    final all = await getAllProgress();
    return all[bookId];
  }

  static Future<void> upsertProgress({
    required String bookId,
    required double percent,
    String? name,
    String? imageUrl,
    String? author,
    String? contentType,
  }) async {
    final normalized = bookId.trim();
    if (normalized.isEmpty) return;
    final bounded = percent.clamp(0.0, 100.0);
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllProgress();
    final previous = all[normalized];

    final updated = <LocalReadingProgress>[];
    var replaced = false;
    for (final entry in all.values) {
      if (entry.bookId == normalized) {
        updated.add(
          LocalReadingProgress(
            bookId: normalized,
            percent: bounded,
            updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
            name: (name ?? entry.name).trim(),
            imageUrl: (imageUrl ?? entry.imageUrl).trim(),
            author: (author ?? entry.author).trim(),
            contentType: (contentType ?? entry.contentType).trim(),
          ),
        );
        replaced = true;
      } else {
        updated.add(entry);
      }
    }
    if (!replaced) {
      updated.add(
        LocalReadingProgress(
          bookId: normalized,
          percent: bounded,
          updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
          name: (name ?? '').trim(),
          imageUrl: (imageUrl ?? '').trim(),
          author: (author ?? '').trim(),
          contentType: (contentType ?? '').trim(),
        ),
      );
    }

    final encoded = jsonEncode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_progressKey, encoded);
  }
}
