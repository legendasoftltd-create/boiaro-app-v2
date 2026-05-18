import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import '/app_constants.dart';

class AudioPlaybackService {
  static AudiobookAudioHandler? _handler;

  static Future<AudiobookAudioHandler> get handler async {
    _handler ??= await AudioService.init(
      builder: () => AudiobookAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.boiaro.app.audiobook',
        androidNotificationChannelName: 'Audiobook Playback',
        androidNotificationChannelDescription: 'Audiobook playback controls',
        androidNotificationIcon: 'drawable/ic_stat_audiobook',
        androidNotificationClickStartsActivity: true,
        androidShowNotificationBadge: false,
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
      ),
    );
    return _handler!;
  }
}

class AudiobookAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  bool _sessionConfigured = false;
  bool _isPreviewSession = false;
  double _previewFraction = 1.0;
  Duration? _previewLimit;
  bool _previewEnded = false;
  bool _isStoppingAtPreviewLimit = false;

  AudiobookAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).listen(playbackState.add);
    _player.positionStream.listen((position) {
      final limit = _previewLimit;
      if (_previewEnded || limit == null || _isStoppingAtPreviewLimit) {
        return;
      }
      if (position >= limit) {
        unawaited(_stopAtPreviewLimit());
      }
    });
    // Update media item duration once the player determines it (async for streams)
    _player.durationStream.listen((duration) {
      _updatePreviewLimit(duration);
      final current = mediaItem.value;
      if (current != null && duration != null && duration > Duration.zero) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  Future<void> _ensureSession() async {
    if (_sessionConfigured) {
      return;
    }
    final session = await AudioSession.instance;
    if (!kIsWeb && Platform.isIOS) {
      await session.configure(const AudioSessionConfiguration.music());
    } else {
      await session.configure(const AudioSessionConfiguration.speech());
    }
    _sessionConfigured = true;
  }

  Future<void> playChapter({
    required Map<String, dynamic> audiobook,
    required Map<String, dynamic> chapter,
  }) async {
    await _ensureSession();
    _resetPreviewSession(audiobook: audiobook, chapter: chapter);
    final isPreview =
        chapter['isPreview'] == true || chapter['is_preview'] == true;
    final url = _resolveAudioUrl(chapter['file'] ?? chapter['audio'],
        isPreview: isPreview);
    if (url.isEmpty) {
      return;
    }
    final title = chapter['title']?.toString() ??
        chapter['name']?.toString() ??
        'Chapter';
    final bookTitle = audiobook['title']?.toString() ??
        audiobook['name']?.toString() ??
        'Audiobook';
    final author =
        audiobook['author']?.toString() ?? audiobook['authorName']?.toString();
    final artUri = _resolveBookImage(audiobook['image']?.toString());

    try {
      await _player.setUrl(url);
    } on PlayerException catch (e) {
      // Likely a bad/unsupported stream (e.g. HTML/JSON instead of audio).
      debugPrint('Audio load failed: $url -> ${e.code}: ${e.message}');
      return;
    } on PlayerInterruptedException {
      // Another load request interrupted this one.
      return;
    } catch (e) {
      debugPrint('Audio load failed: $url -> $e');
      return;
    }
    _updatePreviewLimit(_player.duration);
    final mediaItem = MediaItem(
      id: url,
      title: title,
      album: bookTitle,
      artist: author,
      artUri: artUri.isNotEmpty ? Uri.parse(artUri) : null,
      duration: _player.duration,
    );

    this.mediaItem.add(mediaItem);
    await _player.play();
  }

  @override
  Future<void> play() async {
    if (_previewEnded && _isPreviewSession) {
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) async {
    if (_previewEnded && _isPreviewSession) {
      return;
    }
    final capped = _capPreviewPosition(position);
    if (_previewLimit != null && capped >= _previewLimit!) {
      await _stopAtPreviewLimit();
      return;
    }
    await _player.seek(capped);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  void _resetPreviewSession({
    required Map<String, dynamic> audiobook,
    required Map<String, dynamic> chapter,
  }) {
    _isPreviewSession = audiobook['isPreviewMode'] == true;
    _previewEnded = false;
    _isStoppingAtPreviewLimit = false;
    _previewLimit = null;
    _previewFraction = _resolvePreviewFraction(
      audiobook: audiobook,
      chapter: chapter,
    );
  }

  double _resolvePreviewFraction({
    required Map<String, dynamic> audiobook,
    required Map<String, dynamic> chapter,
  }) {
    final raw = chapter['previewFraction'];
    if (raw is num) {
      final value = raw.toDouble().clamp(0.0, 1.0);
      if (value > 0.0 && value < 1.0) {
        return value;
      }
      if (value == 0.0) {
        return 0.0;
      }
    }
    final chapters = audiobook['chapters'];
    final chapterCount = chapters is List ? chapters.length : 0;
    if (_isPreviewSession && chapterCount <= 1) {
      final percent =
          (audiobook['previewPercent'] as num?)?.toDouble() ?? 100.0;
      return (percent / 100).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  void _updatePreviewLimit(Duration? duration) {
    if (duration == null ||
        duration <= Duration.zero ||
        _previewFraction >= 1.0) {
      _previewLimit = null;
      return;
    }
    final limitedMs = (duration.inMilliseconds * _previewFraction)
        .floor()
        .clamp(0, duration.inMilliseconds);
    _previewLimit = Duration(milliseconds: limitedMs);
  }

  Duration _capPreviewPosition(Duration position) {
    if (position.isNegative) {
      return Duration.zero;
    }
    final limit = _previewLimit;
    if (limit != null && position > limit) {
      return limit;
    }
    return position;
  }

  Future<void> _stopAtPreviewLimit() async {
    final limit = _previewLimit;
    if (!_isPreviewSession ||
        _previewEnded ||
        limit == null ||
        _isStoppingAtPreviewLimit) {
      return;
    }
    _isStoppingAtPreviewLimit = true;
    _previewEnded = true;
    try {
      if (_player.playing) {
        await _player.pause();
      }
      await _player.seek(limit);
    } catch (_) {
      // Best effort; stop below will still tear down playback/notification.
    }
    await _player.stop();
    await super.stop();
    _isStoppingAtPreviewLimit = false;
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  String _resolveAudioUrl(dynamic value, {bool isPreview = false}) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http')) {
      return raw;
    }
    final base = isPreview
        ? FFAppConstants.audiobookPreviewAudioUrl
        : FFAppConstants.audiobookAudioUrl;
    if (raw.startsWith('/')) {
      return '$base${raw.substring(1)}';
    }
    return '$base$raw';
  }

  String _resolveBookImage(String? imagePath) {
    final trimmed = (imagePath ?? '').trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${FFAppConstants.bookImagesUrl}$trimmed';
  }
}
