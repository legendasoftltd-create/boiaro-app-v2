import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../../models/radio/live_session.dart';
import '../../models/radio/radio_station.dart';
import '../audio_playback_service.dart';

enum StreamQuality { high, medium, low }

class RadioAudioPlayerService extends ChangeNotifier {
  static final RadioAudioPlayerService _instance = RadioAudioPlayerService._internal();
  factory RadioAudioPlayerService() => _instance;
  RadioAudioPlayerService._internal() {
    _initAudioSession();
    _listenToPlayerEvents();
  }

  final AudioPlayer _player = AudioPlayer();

  LiveSession? _currentLiveSession;
  RadioStation? _currentStation;
  String? _currentStreamUrl;
  StreamQuality _selectedQuality = StreamQuality.high;
  bool _isReconnectingState = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AudioPlayer get player => _player;
  LiveSession? get currentLiveSession => _currentLiveSession;
  RadioStation? get currentStation => _currentStation;
  String? get currentStreamUrl => _currentStreamUrl;
  StreamQuality get selectedQuality => _selectedQuality;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  bool get isReconnecting => _isReconnectingState || (_currentLiveSession?.isReconnecting ?? false);
  String? get errorMessage => _errorMessage;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('RadioAudioPlayerService: Error initializing audio session: $e');
    }
  }

  void _listenToPlayerEvents() {
    _player.playerStateStream.listen((state) {
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _syncNotificationStatus();
      notifyListeners();
    });

    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      debugPrint('RadioAudioPlayerService error: $e');
      _errorMessage = 'Stream connection error. Retrying...';
      notifyListeners();
    });
  }

  Future<void> _updateNotificationState() async {
    try {
      final handler = await AudioPlaybackService.handler;
      final stationName = _currentStation?.name ?? 'Book On Air';
      final title = _currentLiveSession?.showTitle ?? stationName;
      final rjName = _currentLiveSession?.rjProfile?.stageName ?? '';
      final artist = rjName.isNotEmpty ? 'RJ $rjName' : stationName;
      final image = _currentLiveSession?.rjProfile?.avatarUrl ?? _currentStation?.artworkUrl ?? '';

      final item = MediaItem(
        id: _currentStreamUrl ?? 'radio_stream',
        title: title,
        album: 'Book On Air',
        artist: artist,
        artUri: image.isNotEmpty ? Uri.tryParse(image) : null,
      );

      handler.setRadioMode(
        item: item,
        onPlay: () => resume(),
        onPause: () => pause(),
        onStop: () => stop(),
      );
    } catch (e) {
      debugPrint('RadioAudioPlayerService notification update error: $e');
    }
  }

  Future<void> _syncNotificationStatus() async {
    try {
      final handler = AudioPlaybackService.activeHandler;
      handler?.updateRadioPlaybackState(
        playing: _player.playing,
        loading: _isLoading,
      );
    } catch (_) {}
  }

  String _resolveStreamUrl(RadioStation? station, LiveSession? liveSession, StreamQuality quality) {
    if (liveSession != null && liveSession.streamUrl.isNotEmpty) {
      return liveSession.streamUrl;
    }
    if (station != null) {
      if (quality == StreamQuality.medium && station.streamUrlMedium != null && station.streamUrlMedium!.isNotEmpty) {
        return station.streamUrlMedium!;
      }
      if (quality == StreamQuality.low && station.streamUrlLow != null && station.streamUrlLow!.isNotEmpty) {
        return station.streamUrlLow!;
      }
      return station.streamUrl ?? '';
    }
    return '';
  }

  Future<void> playLive({RadioStation? station, LiveSession? liveSession}) async {
    _currentStation = station ?? liveSession?.station;
    _currentLiveSession = liveSession;
    _errorMessage = null;

    final url = _resolveStreamUrl(_currentStation, _currentLiveSession, _selectedQuality);
    if (url.isEmpty) {
      _errorMessage = 'Stream URL unavailable';
      notifyListeners();
      return;
    }

    if (_currentStreamUrl == url && _player.playing) {
      return;
    }

    _currentStreamUrl = url;
    _isLoading = true;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setUrl(_currentStreamUrl!);
      await _player.play();
      await _updateNotificationState();
    } catch (e) {
      debugPrint('RadioAudioPlayerService.playLive error: $e');
      _errorMessage = 'Unable to play radio stream.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playStation(RadioStation station) async {
    _currentStation = station;
    _currentLiveSession = null;
    _errorMessage = null;

    final url = _resolveStreamUrl(station, null, _selectedQuality);
    if (url.isEmpty) {
      _errorMessage = 'Station stream URL unavailable';
      notifyListeners();
      return;
    }

    if (_currentStreamUrl == url && _player.playing) {
      return;
    }

    _currentStreamUrl = url;
    _isLoading = true;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setUrl(_currentStreamUrl!);
      await _player.play();
      await _updateNotificationState();
    } catch (e) {
      debugPrint('RadioAudioPlayerService.playStation error: $e');
      _errorMessage = 'Unable to play station stream.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setQuality(StreamQuality quality) async {
    if (_selectedQuality == quality) return;
    _selectedQuality = quality;
    if (_currentStation != null || _currentLiveSession != null) {
      await playLive(station: _currentStation, liveSession: _currentLiveSession);
    }
  }

  void setReconnecting(bool reconnecting) {
    _isReconnectingState = reconnecting;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _syncNotificationStatus();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    _syncNotificationStatus();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStreamUrl = null;
    _currentLiveSession = null;
    _currentStation = null;
    try {
      final handler = AudioPlaybackService.activeHandler;
      handler?.stopRadioMode();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
