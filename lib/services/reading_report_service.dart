import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

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
    final normalizedBookId = bookId.trim();
    _notifyDebug(
      'READING START TRY: bookId=$normalizedBookId',
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

    final sessionId = _createSessionId();
    _sessionActive = true;
    _sessionId = sessionId;
    _bookId = normalizedBookId;
    _lastPercentageSent = -1;
    _lastProgressAt = null;
    _notifyDebug(
        'READING START OK: bookId=$normalizedBookId sessionId=$sessionId');
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
    _notifyDebug(
      'READING PROGRESS TRY: bookId=$bookId percentage=$percentage force=$force',
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

    _lastProgressAt = now;
    _lastPercentageSent = bounded;
    _notifyDebug(
        'READING PROGRESS OK: bookId=$bookId sessionId=${_sessionId ?? ''} percentage=$bounded');
  }

  Future<void> endSession() async {
    if (!_sessionActive) {
      _notifyDebug('READING END SKIP: no active session');
      return;
    }

    final sessionId = _sessionId?.trim() ?? '';
    _notifyDebug(
      'READING END TRY: sessionId=$sessionId',
    );
    _notifyDebug('READING END OK: sessionId=$sessionId');

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
}
