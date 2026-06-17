import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
import 'package:a_i_ebook_app/app_state.dart';

enum PresenceActivity {
  browsing,
  reading,
  listening,
  idle,
}

class PresenceTrackingService {
  PresenceTrackingService._();
  static final PresenceTrackingService instance = PresenceTrackingService._();

  late final String _sessionId;
  PresenceActivity _currentActivity = PresenceActivity.browsing;
  PresenceActivity _lastActiveActivity = PresenceActivity.browsing;

  String? _bookId;
  String? _currentPage;
  DateTime _lastInteractionTime = DateTime.now();
  Timer? _heartbeatTimer;
  bool _isInitialized = false;
  bool _streakUpdated = false;


  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Generate unique session ID: sess_mobile_<timestamp>_<random>
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(100000);
    _sessionId = 'sess_mobile_${nowMs}_$rand';
    _lastInteractionTime = DateTime.now();

    _notifyDebug('PRESENCE INIT: session=$_sessionId');

    // Start 30-second periodic heartbeat timer
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkIdleAndSendHeartbeat();
    });

    // Send initial heartbeat immediately
    _sendHeartbeat();
  }

  void recordInteraction() {
    _lastInteractionTime = DateTime.now();
    if (_currentActivity == PresenceActivity.idle) {
      _notifyDebug('PRESENCE: Resuming from idle to $_lastActiveActivity');
      // Resume previous active activity
      updateActivity(_lastActiveActivity, bookId: _bookId, currentPage: _currentPage);
    }
  }

  void updateActivity(PresenceActivity activity, {String? bookId, String? currentPage}) {
    if (activity != PresenceActivity.idle) {
      _lastActiveActivity = activity;
    }
    _currentActivity = activity;
    _bookId = bookId;
    _currentPage = currentPage;

    _notifyDebug('PRESENCE UPDATE: activity=$activity, bookId=$bookId, currentPage=$currentPage');
    
    // Reset interaction time on manual update
    _lastInteractionTime = DateTime.now();
  }

  void _checkIdleAndSendHeartbeat() {
    final now = DateTime.now();
    final idleDuration = now.difference(_lastInteractionTime);
    if (idleDuration.inMinutes >= 5 && _currentActivity != PresenceActivity.idle) {
      _notifyDebug('PRESENCE: Going idle due to 5 minutes of inactivity');
      updateActivity(PresenceActivity.idle, bookId: _bookId, currentPage: _currentPage);
    }
    _sendHeartbeat();
  }

  Future<void> _sendHeartbeat() async {
    final activityType = _currentActivity.name;
    final token = FFAppState().token.trim();

    _notifyDebug('PRESENCE HEARTBEAT SEND: type=$activityType, session=$_sessionId, bookId=$_bookId, currentPage=$_currentPage');

    if (token.isEmpty) {
      _streakUpdated = false;
    } else {
      if (!_streakUpdated) {
        _streakUpdated = true;
        EbookGroup.updateStreakCall.call(token: token).then((res) {
          _notifyDebug('STREAK UPDATE SUCCESS: status=${res.statusCode}');
        }).catchError((err) {
          _streakUpdated = false;
          _notifyDebug('STREAK UPDATE ERROR: $err');
        });
      }

      if (_bookId != null && _bookId!.isNotEmpty) {
        if (_currentActivity == PresenceActivity.reading ||
            _currentActivity == PresenceActivity.listening) {
          final format = _currentActivity == PresenceActivity.listening ? 'audiobook' : 'ebook';
          EbookGroup.logConsumptionTimeCall.call(
            bookId: _bookId,
            format: format,
            seconds: 30,
            token: token,
          ).then((res) {
            _notifyDebug('CONSUMPTION TIME SUCCESS: status=${res.statusCode}');
          }).catchError((err) {
            _notifyDebug('CONSUMPTION TIME ERROR: $err');
          });
        }
      }
    }

    try {
      final res = await EbookGroup.presenceHeartbeatApiCall.call(
        activityType: activityType,
        sessionId: _sessionId,
        bookId: _bookId,
        currentPage: _currentPage,
        token: token,
      );
      _notifyDebug('PRESENCE HEARTBEAT SUCCESS: status=${res.statusCode}, succeeded=${res.succeeded}');
    } catch (e) {
      _notifyDebug('PRESENCE HEARTBEAT ERROR: $e');
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _isInitialized = false;
  }

  void _notifyDebug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
