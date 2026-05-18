import 'package:http/http.dart' as http;

import '/flutter_flow/flutter_flow_util.dart';

class RemoteReadingProgress {
  const RemoteReadingProgress({
    required this.currentPage,
    required this.totalPages,
    required this.percentage,
    required this.lastReadAt,
  });

  final int currentPage;
  final int totalPages;
  final int percentage;
  final String? lastReadAt;

  bool get hasProgress => currentPage > 0 || totalPages > 0 || percentage > 0;

  static const empty = RemoteReadingProgress(
    currentPage: 0,
    totalPages: 0,
    percentage: 0,
    lastReadAt: null,
  );
}

class RemoteListeningProgress {
  const RemoteListeningProgress({
    required this.currentTrack,
    required this.positionSeconds,
    required this.totalSeconds,
    required this.lastListenedAt,
  });

  final int currentTrack;
  final int positionSeconds;
  final int totalSeconds;
  final String? lastListenedAt;

  bool get hasProgress =>
      currentTrack > 1 || positionSeconds > 0 || totalSeconds > 0;

  static const empty = RemoteListeningProgress(
    currentTrack: 1,
    positionSeconds: 0,
    totalSeconds: 0,
    lastListenedAt: null,
  );
}

class ProgressSyncService {
  static Map<String, String> _headers() {
    return <String, String>{
      'apikey': FFAppConstants.supabaseAnonApiKey,
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${FFAppState().token.trim()}',
    };
  }

  static bool get _canSync =>
      FFAppState().isLogin && FFAppState().token.trim().isNotEmpty;

  static Uri _uri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final base = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return base;
    }
    return base.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  static Future<RemoteReadingProgress> fetchReadingProgress(
      String bookId) async {
    final normalizedBookId = bookId.trim();
    if (!_canSync || normalizedBookId.isEmpty) {
      return RemoteReadingProgress.empty;
    }
    try {
      final res = await http.get(
        _uri('progress/reading', queryParameters: {'book_id': normalizedBookId}),
        headers: _headers(),
      );
      if (res.statusCode != 200) {
        return RemoteReadingProgress.empty;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        return RemoteReadingProgress.empty;
      }
      return RemoteReadingProgress(
        currentPage: _toInt(decoded['current_page']),
        totalPages: _toInt(decoded['total_pages']),
        percentage: _toInt(decoded['percentage']),
        lastReadAt: decoded['last_read_at']?.toString(),
      );
    } catch (_) {
      return RemoteReadingProgress.empty;
    }
  }

  static Future<bool> saveReadingProgress({
    required String bookId,
    required int currentPage,
    required int totalPages,
  }) async {
    final normalizedBookId = bookId.trim();
    if (!_canSync || normalizedBookId.isEmpty) {
      return false;
    }
    try {
      final res = await http.put(
        _uri('progress/reading'),
        headers: _headers(),
        body: jsonEncode({
          'book_id': normalizedBookId,
          'current_page': currentPage < 0 ? 0 : currentPage,
          'total_pages': totalPages < 0 ? 0 : totalPages,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<RemoteListeningProgress> fetchListeningProgress(
      String bookId) async {
    final normalizedBookId = bookId.trim();
    if (!_canSync || normalizedBookId.isEmpty) {
      return RemoteListeningProgress.empty;
    }
    try {
      final res = await http.get(
        _uri('progress/listening',
            queryParameters: {'book_id': normalizedBookId}),
        headers: _headers(),
      );
      if (res.statusCode != 200) {
        return RemoteListeningProgress.empty;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        return RemoteListeningProgress.empty;
      }
      return RemoteListeningProgress(
        currentTrack: _toInt(decoded['current_track'], fallback: 1),
        positionSeconds: _toInt(decoded['position_seconds']),
        totalSeconds: _toInt(decoded['total_seconds']),
        lastListenedAt: decoded['last_listened_at']?.toString(),
      );
    } catch (_) {
      return RemoteListeningProgress.empty;
    }
  }

  static Future<bool> saveListeningProgress({
    required String bookId,
    int trackNumber = 1,
    int positionSeconds = 0,
    int totalSeconds = 0,
  }) async {
    final normalizedBookId = bookId.trim();
    if (!_canSync || normalizedBookId.isEmpty) {
      return false;
    }
    try {
      final res = await http.put(
        _uri('progress/listening'),
        headers: _headers(),
        body: jsonEncode({
          'book_id': normalizedBookId,
          'track_number': trackNumber <= 0 ? 1 : trackNumber,
          'position_seconds': positionSeconds < 0 ? 0 : positionSeconds,
          'total_seconds': totalSeconds < 0 ? 0 : totalSeconds,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
