import 'dart:convert';
import 'dart:io';

import '/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDownloadedBook {
  LocalDownloadedBook({
    required this.bookId,
    required this.name,
    required this.image,
    required this.author,
    required this.remoteUrl,
    required this.localPath,
    required this.downloadedAtMillis,
    this.formatType = 'ebook',
  });

  final String bookId;
  final String name;
  final String image;
  final String author;
  final String remoteUrl;
  final String localPath;
  final int downloadedAtMillis;
  final String formatType;

  bool get existsOnDisk => File(localPath).existsSync();

  int get fileSizeInBytes {
    try {
      final file = File(localPath);
      return file.existsSync() ? file.lengthSync() : 0;
    } catch (_) {
      return 0;
    }
  }

  String get formattedFileSize {
    final bytes = fileSizeInBytes;
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'name': name,
      'image': image,
      'author': author,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'downloadedAtMillis': downloadedAtMillis,
      'formatType': formatType,
    };
  }

  static LocalDownloadedBook fromMap(Map<String, dynamic> map) {
    return LocalDownloadedBook(
      bookId: (map['bookId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      image: (map['image'] ?? '').toString(),
      author: (map['author'] ?? '').toString(),
      remoteUrl: (map['remoteUrl'] ?? '').toString(),
      localPath: (map['localPath'] ?? '').toString(),
      downloadedAtMillis:
          int.tryParse((map['downloadedAtMillis'] ?? '0').toString()) ?? 0,
      formatType: (map['formatType'] ?? 'ebook').toString(),
    );
  }
}

class LocalDownloadService {
  static const String _downloadsKey = 'ff_local_downloaded_books_v1';
  static final Dio _dio = Dio();

  static String _resolveRemoteUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return Uri.parse(FFAppConstants.webUrl).resolve(trimmed).toString();
  }

  static Future<List<LocalDownloadedBook>> getAllDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_downloadsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      final items = decoded
          .whereType<Map>()
          .map((e) => LocalDownloadedBook.fromMap(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .where((e) => e.bookId.isNotEmpty)
          .toList();

      items
          .sort((a, b) => b.downloadedAtMillis.compareTo(a.downloadedAtMillis));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<LocalDownloadedBook?> getDownloadByBookId(String bookId) async {
    final all = await getAllDownloads();
    for (final item in all) {
      if (item.bookId == bookId) {
        return item;
      }
    }
    return null;
  }

  static Future<Directory> _downloadsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'book_downloads'));
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  static String _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final ext = p.extension(uri?.path ?? '').toLowerCase();
    if (ext == '.epub' || ext == '.pdf' || ext == '.mp3' || ext == '.m4a' || ext == '.aac' || ext == '.wav') {
      return ext;
    }
    return '.mp3';
  }

  static Future<LocalDownloadedBook> downloadBook({
    required String bookId,
    required String name,
    required String image,
    required String author,
    required String remoteUrl,
    String formatType = 'ebook',
    void Function(int received, int total)? onProgress,
  }) async {
    final resolvedRemoteUrl = _resolveRemoteUrl(remoteUrl);
    if (resolvedRemoteUrl.isEmpty) {
      throw Exception('Download URL is empty.');
    }
    final downloadDir = await _downloadsDirectory();
    final extension = _extensionFromUrl(resolvedRemoteUrl);
    final savePath = p.join(downloadDir.path, '${bookId}_${formatType}$extension');
    final file = File(savePath);

    if (file.existsSync()) {
      await file.delete();
    }

    await _dio.download(
      resolvedRemoteUrl,
      savePath,
      deleteOnError: true,
      onReceiveProgress: onProgress,
    );

    if (!file.existsSync()) {
      throw Exception('Downloaded file not found after save.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final item = LocalDownloadedBook(
      bookId: bookId,
      name: name,
      image: image,
      author: author,
      remoteUrl: resolvedRemoteUrl,
      localPath: savePath,
      downloadedAtMillis: now,
      formatType: formatType,
    );
    await _upsertDownload(item);
    return item;
  }

  static Future<bool> isRemoteUrlChanged({
    required String bookId,
    required String newRemoteUrl,
  }) async {
    final existing = await getDownloadByBookId(bookId);
    if (existing == null) return false;
    final resolvedNew = _resolveRemoteUrl(newRemoteUrl);
    return resolvedNew.isNotEmpty && existing.remoteUrl != resolvedNew;
  }

  static Future<void> _upsertDownload(LocalDownloadedBook item) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllDownloads();

    final updated = <LocalDownloadedBook>[];
    var replaced = false;
    for (final entry in all) {
      if (entry.bookId == item.bookId && entry.formatType == item.formatType) {
        updated.add(item);
        replaced = true;
      } else {
        updated.add(entry);
      }
    }
    if (!replaced) {
      updated.add(item);
    }

    final encoded = jsonEncode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_downloadsKey, encoded);
  }

  static Future<void> deleteDownloadByBookId(String bookId, {String? formatType}) async {
    final normalizedBookId = bookId.trim();
    if (normalizedBookId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final all = await getAllDownloads();

    final remaining = <LocalDownloadedBook>[];
    for (final item in all) {
      if (item.bookId == normalizedBookId && (formatType == null || item.formatType == formatType)) {
        final file = File(item.localPath);
        if (file.existsSync()) {
          await file.delete();
        }
        continue;
      }
      remaining.add(item);
    }

    final encoded = jsonEncode(remaining.map((e) => e.toMap()).toList());
    await prefs.setString(_downloadsKey, encoded);
  }
}
