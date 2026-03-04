import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReadingReportService {
  ReadingReportService._();
  static final ReadingReportService instance = ReadingReportService._();

  String? _sessionId;
  String? _bookId;
  int _lastPercentageSent = -1;
  DateTime? _lastProgressAt;
  bool _sessionActive = false;
  void Function(String message)? _debugListener;

  void setDebugListener(void Function(String message)? listener) {
    _debugListener = listener;
  }

  bool get hasActiveSession =>
      _sessionActive && (_sessionId?.isNotEmpty ?? false);

  Future<void> startSession({required String bookId}) async {
    final userId = _resolveUserId();
    final token = FFAppState().token.trim();
    final normalizedBookId = bookId.trim();
    _notifyDebug(
      'READING START TRY: bookId=$normalizedBookId userId=$userId token=${token.isNotEmpty ? "set" : "empty"}',
    );

    if (normalizedBookId.isEmpty) {
      _notifyDebug('READING START SKIP: missing bookId');
      return;
    }

    if (_sessionActive && _bookId == normalizedBookId) {
      _notifyDebug('READING START SKIP: session already active');
      return;
    }

    if (_sessionActive) {
      await endSession();
    }

    // Count a view whenever a new reading session starts.
    try {
      final viewResponse = await EbookGroup.bookViewApiCall.call(
        bookId: normalizedBookId,
        userId: userId,
      );
      if (viewResponse.succeeded) {
        _notifyDebug('BOOK VIEW OK: bookId=$normalizedBookId userId=$userId');
      } else {
        _notifyDebug('BOOK VIEW FAIL: bookId=$normalizedBookId userId=$userId');
      }
    } catch (e) {
      _notifyDebug('BOOK VIEW EXCEPTION: $e');
    }

    final sessionId = _createSessionId();
    try {
      final response = await EbookGroup.bookReadingStartApiCall.call(
        bookId: normalizedBookId,
        userId: userId,
        sessionId: sessionId,
        token: token,
      );

      if (response.succeeded) {
        _sessionActive = true;
        _sessionId = sessionId;
        _bookId = normalizedBookId;
        _lastPercentageSent = -1;
        _lastProgressAt = null;
        _notifyDebug(
            'READING START OK: bookId=$normalizedBookId sessionId=$sessionId');
      } else {
        _notifyDebug(
            'READING START FAIL: bookId=$normalizedBookId sessionId=$sessionId');
      }
    } catch (e) {
      _notifyDebug('READING START EXCEPTION: $e');
    }
  }

  Future<void> updateProgress({
    required int percentage,
    bool force = false,
  }) async {
    if (!_sessionActive) {
      _notifyDebug('READING PROGRESS SKIP: no active session');
      return;
    }

    final bookId = _bookId?.trim() ?? '';
    final userId = _resolveUserId();
    final token = FFAppState().token.trim();
    _notifyDebug(
      'READING PROGRESS TRY: bookId=$bookId userId=$userId percentage=$percentage token=${token.isNotEmpty ? "set" : "empty"} force=$force',
    );

    if (bookId.isEmpty) {
      _notifyDebug('READING PROGRESS SKIP: missing bookId');
      return;
    }

    final bounded = percentage.clamp(0, 100);
    final now = DateTime.now();
    final lastAt = _lastProgressAt;
    final isWithinThrottle =
        lastAt != null && now.difference(lastAt).inSeconds < 30;
    final isSamePercentage = bounded == _lastPercentageSent;

    if (!force && isWithinThrottle && isSamePercentage) {
      _notifyDebug('READING PROGRESS SKIP: throttled same percentage=$bounded');
      return;
    }

    try {
      final response = await EbookGroup.bookReadingProgressApiCall.call(
        bookId: bookId,
        userId: userId,
        percentage: bounded,
        token: token,
      );

      if (response.succeeded) {
        _lastProgressAt = now;
        _lastPercentageSent = bounded;
        _notifyDebug(
            'READING PROGRESS OK: bookId=$bookId sessionId=${_sessionId ?? ''} percentage=$bounded');
      } else {
        _notifyDebug(
            'READING PROGRESS FAIL: bookId=$bookId sessionId=${_sessionId ?? ''} percentage=$bounded');
      }
    } catch (e) {
      _notifyDebug('READING PROGRESS EXCEPTION: $e');
    }
  }

  Future<void> endSession() async {
    if (!_sessionActive) {
      _notifyDebug('READING END SKIP: no active session');
      return;
    }

    final token = FFAppState().token.trim();
    final sessionId = _sessionId?.trim() ?? '';
    _notifyDebug(
      'READING END TRY: sessionId=$sessionId token=${token.isNotEmpty ? "set" : "empty"}',
    );
    if (sessionId.isNotEmpty && token.isNotEmpty) {
      try {
        final response = await EbookGroup.bookReadingEndApiCall.call(
          sessionId: sessionId,
          token: token,
        );
        if (response.succeeded) {
          _notifyDebug('READING END OK: sessionId=$sessionId');
        } else {
          _notifyDebug('READING END FAIL: sessionId=$sessionId');
        }
      } catch (e) {
        _notifyDebug('READING END EXCEPTION: $e');
      }
    } else {
      _notifyDebug('READING END SKIP: missing session/token');
    }

    _sessionActive = false;
    _sessionId = null;
    _bookId = null;
    _lastPercentageSent = -1;
    _lastProgressAt = null;
  }

  String _createSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 32);
    return 'read_$now\_$random';
  }

  void _notifyDebug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
    _debugListener?.call(message);
  }

  String _resolveUserId() {
    final direct = FFAppState().userId.trim();
    if (direct.isNotEmpty) return direct;

    final detail = FFAppState().userDetail;
    if (detail is Map) {
      final fromId = (detail['id'] ?? '').toString().trim();
      if (fromId.isNotEmpty) return fromId;
      final fromUnderscoreId = (detail['_id'] ?? '').toString().trim();
      if (fromUnderscoreId.isNotEmpty) return fromUnderscoreId;
    }
    return '';
  }
}
