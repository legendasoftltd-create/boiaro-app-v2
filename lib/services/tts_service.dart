import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/app_constants.dart';
import '/app_state.dart';

/// TTS mode — device (flutter_tts) or premium (backend API + just_audio).
enum TtsMode { device, premium }

/// Represents a voice option for the premium TTS.
class TtsVoice {
  final String id;
  final String name;
  final String label;
  final String lang;

  const TtsVoice({
    required this.id,
    required this.name,
    required this.label,
    required this.lang,
  });

  factory TtsVoice.fromJson(Map<String, dynamic> json) => TtsVoice(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        lang: json['lang']?.toString() ?? 'bn',
      );
}

/// Represents an ambient background track.
class TtsAmbientTrack {
  final String id;
  final String name;
  final String label;
  final String emoji;
  final String url;

  const TtsAmbientTrack({
    required this.id,
    required this.name,
    required this.label,
    required this.emoji,
    required this.url,
  });

  factory TtsAmbientTrack.fromJson(Map<String, dynamic> json) => TtsAmbientTrack(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );
}

/// Access info returned by /tts/access/:bookId
class TtsAccessInfo {
  final bool premiumVoiceEnabled;
  final bool unlocked;
  final String accessType; // "free" | "paid"
  final int coinPrice;
  final int walletBalance;

  const TtsAccessInfo({
    required this.premiumVoiceEnabled,
    required this.unlocked,
    required this.accessType,
    required this.coinPrice,
    required this.walletBalance,
  });

  factory TtsAccessInfo.fromJson(Map<String, dynamic> json) => TtsAccessInfo(
        premiumVoiceEnabled: json['premium_voice_enabled'] == true,
        unlocked: json['unlocked'] == true,
        accessType: json['access_type']?.toString() ?? 'paid',
        coinPrice: (json['coin_price'] as num?)?.toInt() ?? 0,
        walletBalance: (json['wallet_balance'] as num?)?.toInt() ?? 0,
      );
}

/// Singleton service managing both device & premium TTS.
class TtsService extends ChangeNotifier {
  TtsService._();
  static final TtsService instance = TtsService._();

  // ── State ──────────────────────────────────────────────────────────────────
  TtsMode _mode = TtsMode.device;
  TtsMode get mode => _mode;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  TtsAccessInfo? _accessInfo;
  TtsAccessInfo? get accessInfo => _accessInfo;

  List<TtsVoice> _voices = [];
  List<TtsVoice> get voices => _voices;

  TtsVoice? _selectedVoice;
  TtsVoice? get selectedVoice => _selectedVoice;

  List<TtsAmbientTrack> _ambientTracks = [];
  List<TtsAmbientTrack> get ambientTracks => _ambientTracks;

  TtsAmbientTrack? _selectedAmbientTrack;
  TtsAmbientTrack? get selectedAmbientTrack => _selectedAmbientTrack;

  double _speechRate = 0.5;
  double get speechRate => _speechRate;

  int _currentParagraphIndex = -1;
  int get currentParagraphIndex => _currentParagraphIndex;

  // ── Internal ───────────────────────────────────────────────────────────────
  final FlutterTts _deviceTts = FlutterTts();
  final AudioPlayer _premiumPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool _deviceTtsInitialized = false;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (FFAppState().token.isNotEmpty)
          'Authorization': 'Bearer ${FFAppState().token}',
      };

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initDeviceTts() async {
    if (_deviceTtsInitialized) return;
    _deviceTtsInitialized = true;

    await _deviceTts.setLanguage('bn-BD');
    await _deviceTts.setSpeechRate(_speechRate);
    await _deviceTts.setVolume(1.0);
    await _deviceTts.setPitch(1.0);

    _deviceTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
    });
    _deviceTts.setCancelHandler(() {
      _isPlaying = false;
      notifyListeners();
    });
    _deviceTts.setErrorHandler((msg) {
      _isPlaying = false;
      _error = msg.toString();
      notifyListeners();
    });

    // Premium player listeners
    _premiumPlayer.playerStateStream.listen((state) {
      final playing = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  // ── API helpers ────────────────────────────────────────────────────────────

  /// GET /tts/voices
  Future<void> fetchVoices() async {
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/tts/voices');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body['voices'];
        if (raw is List) {
          _voices = raw
              .whereType<Map<String, dynamic>>()
              .map((v) => TtsVoice.fromJson(v))
              .toList();
          if (_selectedVoice == null && _voices.isNotEmpty) {
            _selectedVoice = _voices.first;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      log('TTS fetchVoices error: $e');
    }
  }

  /// GET /tts/ambient-tracks
  Future<void> fetchAmbientTracks() async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/tts/ambient-tracks');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body['tracks'];
        if (raw is List) {
          _ambientTracks = raw
              .whereType<Map<String, dynamic>>()
              .map((v) => TtsAmbientTrack.fromJson(v))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      log('TTS fetchAmbientTracks error: $e');
    }
  }

  /// GET /tts/access/:bookId
  Future<TtsAccessInfo?> checkAccess(String bookId) async {
    try {
      final uri = Uri.parse(
          '${FFAppConstants.mobileApiBaseUrl}/tts/access/$bookId');
      final res = await http.get(uri, headers: _authHeaders);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _accessInfo = TtsAccessInfo.fromJson(body as Map<String, dynamic>);
        notifyListeners();
        return _accessInfo;
      }
    } catch (e) {
      log('TTS checkAccess error: $e');
    }
    return null;
  }

  /// POST /tts/unlock
  /// Returns null on success, error string on failure.
  Future<String?> unlockWithCoins(String bookId) async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/tts/unlock');
      final res = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode({'book_id': bookId}),
      );
      final body = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('ff_language') ?? 'en';
      if (res.statusCode == 200 && body['success'] == true) {
        // Refresh access info
        await checkAccess(bookId);
        return null;
      }
      return body['error']?.toString() ?? (lang == 'bn' ? 'আনলক করতে ব্যর্থ হয়েছে' : 'Unlock failed');
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('ff_language') ?? 'en';
      return lang == 'bn' ? 'ত্রুটি: $e' : 'Error: $e';
    }
  }

  /// POST /tts/generate — returns audio URL or throws.
  Future<String> generateAudio({
    required String bookId,
    required String text,
    required String voiceId,
    required int paragraphIndex,
  }) async {
    final uri =
        Uri.parse('${FFAppConstants.mobileApiBaseUrl}/tts/generate');
    final res = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({
        'book_id': bookId,
        'text': text,
        'voice_id': voiceId,
        'paragraph_index': paragraphIndex,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return body['audio_url'] as String;
    }
    final err = body['error']?.toString() ?? 'Generate failed';
    throw Exception(err);
  }

  /// GET /tts/cache/:bookId
  Future<Map<String, dynamic>?> checkCache(String bookId) async {
    try {
      final uri = Uri.parse(
          '${FFAppConstants.mobileApiBaseUrl}/tts/cache/$bookId');
      final res = await http.get(uri, headers: {
        if (FFAppState().token.isNotEmpty)
          'Authorization': 'Bearer ${FFAppState().token}',
      });
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      log('TTS checkCache error: $e');
    }
    return null;
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  void setMode(TtsMode m) {
    if (_mode == m) return;
    stop();
    _mode = m;
    notifyListeners();
  }

  void selectVoice(TtsVoice voice) {
    _selectedVoice = voice;
    notifyListeners();
  }

  Future<void> selectAmbientTrack(TtsAmbientTrack? track) async {
    if (_selectedAmbientTrack?.id == track?.id) return;
    _selectedAmbientTrack = track;
    notifyListeners();

    if (track == null) {
      await _ambientPlayer.stop();
    } else {
      try {
        await _ambientPlayer.setUrl(track.url);
        await _ambientPlayer.setLoopMode(LoopMode.one);
        await _ambientPlayer.setVolume(0.25); // Subtle background
        if (_isPlaying) {
          await _ambientPlayer.play();
        }
      } catch (e) {
        log('Ambient track error: $e');
      }
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _deviceTts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  /// Speak a paragraph. In device mode uses flutter_tts. In premium mode
  /// calls the backend to get an audio URL then plays with just_audio.
  Future<void> speak({
    required String text,
    required String bookId,
    required int paragraphIndex,
  }) async {
    if (text.trim().isEmpty) return;
    // We stop TTS players but keep ambient if it's the same track
    await _deviceTts.stop();
    await _premiumPlayer.stop();

    _error = null;
    _currentParagraphIndex = paragraphIndex;

    // Start ambient if selected and not playing
    if (_selectedAmbientTrack != null && !_ambientPlayer.playing) {
      unawaited(_ambientPlayer.play());
    }

    if (_mode == TtsMode.device) {
      await _speakDevice(text);
    } else {
      await _speakPremium(
          bookId: bookId, text: text, paragraphIndex: paragraphIndex);
    }
  }

  Future<void> _speakDevice(String text) async {
    await initDeviceTts();
    _isPlaying = true;
    notifyListeners();
    await _deviceTts.speak(text);
  }

  Future<void> _speakPremium({
    required String bookId,
    required String text,
    required int paragraphIndex,
  }) async {
    final voice = _selectedVoice;
    if (voice == null) {
      _error = 'No voice selected';
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final audioUrl = await generateAudio(
        bookId: bookId,
        text: text,
        voiceId: voice.id,
        paragraphIndex: paragraphIndex,
      );
      await _premiumPlayer.setUrl(audioUrl);
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      await _premiumPlayer.play();
    } catch (e) {
      _isLoading = false;
      _isPlaying = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _deviceTts.stop();
    await _premiumPlayer.stop();
    await _ambientPlayer.stop();
    _isPlaying = false;
    _isLoading = false;
    _currentParagraphIndex = -1;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_mode == TtsMode.device) {
      await _deviceTts.pause();
    } else {
      await _premiumPlayer.pause();
    }
    await _ambientPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceTts.stop();
    _premiumPlayer.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }
}
