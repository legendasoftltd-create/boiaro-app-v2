import 'dart:convert';
import 'dart:io';

import 'package:a_i_ebook_app/app_constants.dart';
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
  });

  final String bookId;
  final String name;
  final String image;
  final String author;
  final String remoteUrl;
  final String localPath;
  final int downloadedAtMillis;

  bool get existsOnDisk => File(localPath).existsSync();

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'name': name,
      'image': image,
      'author': author,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'downloadedAtMillis': downloadedAtMillis,
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
    if (ext == '.epub' || ext == '.pdf') {
      return ext;
    }
    return '.pdf';
  }

  static Future<LocalDownloadedBook> downloadBook({
    required String bookId,
    required String name,
    required String image,
    required String author,
    required String remoteUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final resolvedRemoteUrl = _resolveRemoteUrl(remoteUrl);
    if (resolvedRemoteUrl.isEmpty) {
      throw Exception('Download URL is empty.');
    }
    final downloadDir = await _downloadsDirectory();
    final extension = _extensionFromUrl(resolvedRemoteUrl);
    final savePath = p.join(downloadDir.path, '${bookId}_book$extension');
    final file = File(savePath);

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
    );
    await _upsertDownload(item);
    return item;
  }

  static Future<void> _upsertDownload(LocalDownloadedBook item) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllDownloads();

    final updated = <LocalDownloadedBook>[];
    var replaced = false;
    for (final entry in all) {
      if (entry.bookId == item.bookId) {
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
}
