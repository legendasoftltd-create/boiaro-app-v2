import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app_constants.dart';
import '/backend/boiaro_legacy_adapter.dart';

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

  static Future<Map<String, dynamic>?> get currentAudiobook async {
    if (_handler?.currentAudiobook != null) {
      return _handler!.currentAudiobook;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString('boiaro_active_audiobook');
      if (serialized != null) {
        return json.decode(serialized) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading boiaro_active_audiobook from SharedPreferences: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> get currentChapter async {
    if (_handler?.currentChapter != null) {
      return _handler!.currentChapter;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString('boiaro_active_chapter');
      if (serialized != null) {
        return json.decode(serialized) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading boiaro_active_chapter from SharedPreferences: $e');
    }
    return null;
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

  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool ambientEnabled = false;
  double ambientVolume = 0.3;
  int selectedAmbientIndex = 0;

  Map<String, dynamic>? currentAudiobook;
  Map<String, dynamic>? currentChapter;

  AudiobookAudioHandler() {
    _ambientPlayer.setLoopMode(LoopMode.one);
    _ambientPlayer.setVolume(ambientVolume);
    _player.setLoopMode(LoopMode.off);

    _player.playerStateStream.listen((state) {
      _updateAmbientState();
    });

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
    debugPrint('[Audio Playback Service] playChapter called');
    debugPrint('  - audiobook: $audiobook');
    debugPrint('  - chapter: $chapter');
    currentAudiobook = audiobook;
    currentChapter = chapter;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('boiaro_active_audiobook', json.encode(audiobook));
      await prefs.setString('boiaro_active_chapter', json.encode(chapter));
    } catch (e) {
      debugPrint('Error saving active audio session to SharedPreferences: $e');
    }
    await _ensureSession();
    _resetPreviewSession(audiobook: audiobook, chapter: chapter);
    final isPreview =
        chapter['isPreview'] == true || chapter['is_preview'] == true;
    final url = _resolveAudioUrl(chapter['file'] ?? chapter['audio'],
        isPreview: isPreview);
    debugPrint('  - Resolved play URL: "$url"');
    if (url.isEmpty) {
      debugPrint('  - ERROR: Resolved play URL is empty. Playback aborted.');
      return;
    }
    final title = chapter['title']?.toString() ??
        chapter['name']?.toString() ??
        'Chapter';
    final bookTitle = audiobook['title']?.toString() ??
        audiobook['name']?.toString() ??
        'Audiobook';
    final author = BoiaroLegacyAdapter.resolveAuthorName(
        audiobook['author'] ?? audiobook['authorName'] ?? audiobook['authors']);
    final artUri = _resolveBookImage(audiobook['image']?.toString());

    try {
      debugPrint('[Audio Playback Service] Setting player URL: $url');
      await _player.setUrl(url);
      debugPrint('[Audio Playback Service] URL set successfully. Player duration: ${_player.duration}');
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
    await _ambientPlayer.stop();
    return super.stop();
  }

  void _updateAmbientState() {
    final shouldPlay = ambientEnabled &&
        _player.playing &&
        _player.processingState != ProcessingState.completed &&
        _player.processingState != ProcessingState.idle;
    if (shouldPlay) {
      if (!_ambientPlayer.playing) {
        _ambientPlayer.play();
      }
    } else {
      if (_ambientPlayer.playing) {
        _ambientPlayer.pause();
      }
    }
  }

  Future<void> setAmbientEnabled(bool enabled) async {
    ambientEnabled = enabled;
    if (enabled) {
      _updateAmbientState();
    } else {
      await _ambientPlayer.pause();
    }
  }

  Future<void> setAmbientVolume(double volume) async {
    ambientVolume = volume;
    await _ambientPlayer.setVolume(volume);
  }

  Future<void> setAmbientUrl(String? url, int index) async {
    selectedAmbientIndex = index;
    if (url == null || url.trim().isEmpty) {
      await _ambientPlayer.stop();
    } else {
      try {
        await _ambientPlayer.setUrl(url);
        _updateAmbientState();
      } catch (e) {
        debugPrint('Error setting ambient URL in handler: $e');
      }
    }
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
    if (!_isPreviewSession) {
      return 1.0;
    }
    final percent =
        (audiobook['previewPercent'] as num?)?.toDouble() ?? 100.0;
    return (percent / 100).clamp(0.0, 1.0);
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
