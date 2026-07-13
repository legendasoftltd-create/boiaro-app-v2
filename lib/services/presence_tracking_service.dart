import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:a_i_ebook_app/backend/api_requests/api_calls.dart';
import 'package:a_i_ebook_app/services/audio_playback_service.dart';
import 'package:a_i_ebook_app/services/progress_sync_service.dart';
import 'package:a_i_ebook_app/flutter_flow/flutter_flow_util.dart';

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
    String activityType = _currentActivity.name;
    String? currentBookId = _bookId;
    String? currentProgress = _currentPage;
    final token = FFAppState().token.trim();

    // Check if background audio is playing
    bool isAudioPlaying = false;
    PlaybackState? audioState;
    final handler = AudioPlaybackService.activeHandler;
    try {
      if (handler != null && handler.playbackState.hasValue) {
        audioState = handler.playbackState.value;
        isAudioPlaying = audioState.playing == true;
      }
    } catch (_) {}

    if (isAudioPlaying && handler != null) {
      final book = handler.currentAudiobook;
      if (book != null) {
        final bId = (book['id'] ??
                book['_id'] ??
                getJsonField(book, r'''$._id''') ??
                '')
            .toString()
            .trim();
        if (bId.isNotEmpty) {
          activityType = PresenceActivity.listening.name;
          currentBookId = bId;
          currentProgress = _formatDurationPresence(audioState?.updatePosition ?? Duration.zero);

          // Sync progress of background audio play session to backend
          final chapter = handler.currentChapter;
          final trackNum = chapter?['track_number'] ?? 1;
          final parsedTrackNum = int.tryParse(trackNum.toString()) ?? 1;
          final posSec = audioState?.updatePosition.inSeconds ?? 0;
          final totalSec = handler.mediaItem.value?.duration?.inSeconds ?? 0;

          if (posSec >= 0 && totalSec > 0) {
            ProgressSyncService.saveListeningProgress(
              bookId: bId,
              trackNumber: parsedTrackNum,
              positionSeconds: posSec,
              totalSeconds: totalSec,
            ).then((success) {
              _notifyDebug('BACKGROUND PROGRESS SYNC SUCCESS: $success');
            }).catchError((err) {
              _notifyDebug('BACKGROUND PROGRESS SYNC ERROR: $err');
            });
          }
        }
      }
    }

    _notifyDebug('PRESENCE HEARTBEAT SEND: type=$activityType, session=$_sessionId, bookId=$currentBookId, currentPage=$currentProgress');

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

      if (currentBookId != null && currentBookId.isNotEmpty) {
        if (activityType == 'reading' || activityType == 'listening') {
          final format = activityType == 'listening' ? 'audiobook' : 'ebook';
          EbookGroup.logConsumptionTimeCall.call(
            bookId: currentBookId,
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
        bookId: currentBookId,
        currentPage: currentProgress,
        token: token,
      );
      _notifyDebug('PRESENCE HEARTBEAT SUCCESS: status=${res.statusCode}, succeeded=${res.succeeded}');
    } catch (e) {
      _notifyDebug('PRESENCE HEARTBEAT ERROR: $e');
    }
  }

  String _formatDurationPresence(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
