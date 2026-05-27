import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/audio_playback_service.dart';
import '/services/progress_sync_service.dart';
import '/services/presence_tracking_service.dart';
import '/services/tts_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, AudioPlayer;
import 'dart:async';
import 'audio_player_page_model.dart';
export 'audio_player_page_model.dart';


class AudioPlayerPageWidget extends StatefulWidget {
  const AudioPlayerPageWidget({
    super.key,
    required this.audiobook,
    required this.chapter,
  });

  final Map<String, dynamic> audiobook;
  final Map<String, dynamic> chapter;

  static String routeName = 'AudioPlayerPage';
  static String routePath = '/audioPlayerPage';

  @override
  State<AudioPlayerPageWidget> createState() => _AudioPlayerPageWidgetState();
}

class _AudioPlayerPageWidgetState extends State<AudioPlayerPageWidget>
    with TickerProviderStateMixin {
  late AudioPlayerPageModel _model;

  // Video Player state
  bool _videoMode = false;
  VideoPlayerController? _videoController;
  bool _videoLoading = false;

  // Ambient Sound player state
  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool _ambientEnabled = false;
  int _selectedAmbientIndex = 0;
  double _ambientVolume = 0.3; // Default 30% background volume

  final scaffoldKey = GlobalKey<ScaffoldState>();
  AudiobookAudioHandler? _handler;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<Map<String, dynamic>> _chapters = [];
  int _currentIndex = 0;
  Map<String, dynamic>? _currentChapter;
  double _speed = 1.0;
  Timer? _sleepTimer;
  String _sleepLabel = 'Off';
  int _lastPersistedSecond = -1;
  bool _isPreviewMode = false;
  int _previewPercent = 100;
  bool _previewLimitShown = false;
  RemoteListeningProgress? _remoteListeningProgress;
  bool _isPlaying = false;


  final animationsMap = {
    'imageOnPageLoadAnimation': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effectsBuilder: () => [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
        ScaleEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
        ),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudioPlayerPageModel());
    _isPreviewMode = widget.audiobook['isPreviewMode'] == true;
    _previewPercent =
        (widget.audiobook['previewPercent'] as num?)?.toInt() ?? 100;
    _initializeChapters();
    _persistAudiobookMeta();
    _initAudio();
    _initAmbientPlayer();
    _loadAmbientTracks();
  }

  void _initializeChapters() {
    _chapters = _normalizeChapters(widget.audiobook['chapters']);
    if (_chapters.isEmpty) {
      _chapters = [widget.chapter];
    }
    _currentIndex = _findChapterIndex(_chapters, widget.chapter);
    _currentChapter = _chapters[_currentIndex];
  }

  Future<void> _initAudio() async {
    final handler = await AudioPlaybackService.handler;
    _handler = handler;
    final bookId = _bookId();
    if (bookId.isNotEmpty) {
      _remoteListeningProgress =
          await ProgressSyncService.fetchListeningProgress(bookId);
      _applyRemoteListeningStart(_remoteListeningProgress);
    }
    _playbackStateSub = handler.playbackState.listen((state) {
      if (_isPreviewMode) {
        _onPlaybackState(state);
      }
      _isPlaying = state.playing;
      _updateAmbientState();
      final bId = _bookId();
      if (bId.isNotEmpty) {
        if (_isPlaying) {
          PresenceTrackingService.instance.updateActivity(
            PresenceActivity.listening,
            bookId: bId,
            currentPage: _formatDurationPresence(_position),
          );
        } else {
          PresenceTrackingService.instance.updateActivity(
            PresenceActivity.browsing,
          );
        }
      }
    });
    _positionSub = AudioService.position.listen((pos) {
      if (!mounted || _videoMode) {
        return;
      }
      final cappedPosition = _capPreviewPosition(pos);
      if (cappedPosition != pos) {
        _handler?.seek(cappedPosition);
      }
      setState(() => _position = cappedPosition);
      _persistAudiobookProgress(cappedPosition);
      _maybeHandlePreviewBoundary(cappedPosition);
    });
    _mediaItemSub = handler.mediaItem.listen((item) {
      if (!mounted || _videoMode) {
        return;
      }
      setState(() => _duration = item?.duration ?? Duration.zero);
      _persistAudiobookProgress(_position);
    });
    await _startPlayback();
    if (mounted) {
      setState(() {});
    }
  }

  String _bookId() {
    return (widget.audiobook['id'] ??
            widget.audiobook['_id'] ??
            getJsonField(widget.audiobook, r'''$._id''') ??
            '')
        .toString()
        .trim();
  }

  void _applyRemoteListeningStart(RemoteListeningProgress? remote) {
    if (remote == null || !remote.hasProgress) {
      return;
    }
    final targetIndex = _chapters.indexWhere((chapter) {
      final chapterTrack =
          int.tryParse((chapter['track_number'] ?? '').toString()) ??
              (_chapters.indexOf(chapter) + 1);
      return chapterTrack == remote.currentTrack;
    });
    if (targetIndex >= 0) {
      _currentIndex = targetIndex;
      _currentChapter = _chapters[targetIndex];
    }
  }

  Future<void> _restoreSavedAudioPosition(AudiobookAudioHandler handler) async {
    final remote = _remoteListeningProgress;
    if (remote != null && remote.hasProgress) {
      if (remote.positionSeconds > 0) {
        await handler.seek(Duration(seconds: remote.positionSeconds));
      }
      return;
    }

    final isSameBook = widget.audiobook['id']?.toString() ==
            FFAppState().homePageLastAudioBookId ||
        widget.audiobook['_id']?.toString() ==
            FFAppState().homePageLastAudioBookId;
    if (!isSameBook) {
      return;
    }
    final savedSec = FFAppState().homePageLastAudioPositionSec;
    if (savedSec <= 0) {
      return;
    }
    final lastTrack =
        FFAppState().prefs.getInt('ff_homePageLastAudioTrackNumber') ?? 1;
    final currentTrack =
        int.tryParse((_currentChapter?['track_number'] ?? '').toString()) ??
            (_currentIndex + 1);
    if (currentTrack == lastTrack) {
      await handler.seek(Duration(seconds: savedSec));
    }
  }

  void _onPlaybackState(PlaybackState state) {
    if (!mounted || _previewLimitShown) return;
    if (_isPreviewMode) {
      _maybeHandlePreviewBoundary(_position);
    }
  }

  void _showPreviewLimitDialog() {
    final bookName = widget.audiobook['name']?.toString() ??
        widget.audiobook['title']?.toString() ??
        'this audiobook';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Ended'),
        content: Text(
          'You\'ve reached the $_previewPercent% preview limit for "$bookName". '
          'Purchase the full audiobook to keep listening.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.safePop();
            },
            child: const Text('Buy Now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _sleepTimer?.cancel();
    _model.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _ambientPlayer.dispose();
    PresenceTrackingService.instance.updateActivity(PresenceActivity.browsing);
    super.dispose();
  }

  List<Map<String, dynamic>> _normalizeChapters(dynamic rawChapters) {
    if (rawChapters is! List) {
      return [];
    }
    return rawChapters.map<Map<String, dynamic>>((chapter) {
      if (chapter is Map<String, dynamic>) {
        return {
          'title': chapter['title'] ?? chapter['name'] ?? 'Chapter',
          'file': chapter['file'] ?? chapter['audio'],
          'track_number': chapter['track_number'],
          'isLocked': chapter['isLocked'] ?? chapter['is_locked'] ?? false,
          'isPreview': chapter['isPreview'] ?? chapter['is_preview'] ?? false,
          'previewFraction': chapter['previewFraction'] ?? 1.0,
          'raw': chapter,
        };
      }
      return {
        'title': 'Chapter',
        'file': chapter?.toString(),
        'track_number': null,
        'isLocked': false,
        'isPreview': false,
        'previewFraction': 1.0,
        'raw': chapter,
      };
    }).toList();
  }

  int _findChapterIndex(
    List<Map<String, dynamic>> chapters,
    Map<String, dynamic> current,
  ) {
    final currentFile = current['file'] ?? current['audio'];
    if (currentFile != null) {
      final idx = chapters.indexWhere((chapter) =>
          (chapter['file'] ?? chapter['audio'])?.toString() ==
          currentFile.toString());
      if (idx >= 0) {
        return idx;
      }
    }
    final currentTitle = current['title'] ?? current['name'];
    if (currentTitle != null) {
      final idx = chapters.indexWhere(
        (chapter) =>
            (chapter['title'] ?? chapter['name'])?.toString() ==
            currentTitle.toString(),
      );
      if (idx >= 0) {
        return idx;
      }
    }
    return 0;
  }

  Future<void> _startPlayback() async {
    final handler = _handler ?? await AudioPlaybackService.handler;
    _handler = handler;

    if (_hasVideo()) {
      setState(() {
        _videoMode = true;
      });
      await handler.pause();
      await _initVideoPlayer();
      
      final isSameBook = widget.audiobook['id']?.toString() ==
              FFAppState().homePageLastAudioBookId ||
          widget.audiobook['_id']?.toString() ==
              FFAppState().homePageLastAudioBookId;
      if (isSameBook) {
        final savedSec = FFAppState().homePageLastAudioPositionSec;
        if (savedSec > 0) {
          final lastTrack =
              FFAppState().prefs.getInt('ff_homePageLastAudioTrackNumber') ?? 1;
          final currentTrack =
              int.tryParse((_currentChapter?['track_number'] ?? '').toString()) ??
                  (_currentIndex + 1);
          if (currentTrack == lastTrack) {
            await _videoController?.seekTo(Duration(seconds: savedSec));
          }
        }
      }
    } else {
      setState(() {
        _videoMode = false;
      });
      if (_videoController != null) {
        await _videoController!.pause();
      }
      _updateAmbientState();
      await handler.playChapter(
        audiobook: widget.audiobook,
        chapter: _currentChapter ?? widget.chapter,
      );
      await _restoreSavedAudioPosition(handler);
    }
  }

  Future<void> _playChapterAt(int index) async {
    if (index < 0 || index >= _chapters.length) {
      return;
    }
    setState(() {
      _currentIndex = index;
      _currentChapter = _chapters[index];
      _position = Duration.zero;
      _duration = Duration.zero;
      _previewLimitShown = false;
    });
    _persistAudiobookMeta();
    await _startPlayback();
  }

  void _persistAudiobookMeta() {
    final audiobook = widget.audiobook;
    final id = audiobook['id'] ??
        audiobook['_id'] ??
        getJsonField(audiobook, r'''$._id''');
    final name = audiobook['title'] ?? audiobook['name'] ?? '';
    final author = audiobook['author'] ??
        audiobook['authorName'] ??
        getJsonField(audiobook, r'''$.author.name''');
    final imageValue =
        audiobook['image'] ?? getJsonField(audiobook, r'''$.image''');
    final imageUrl = _resolveBookImage(imageValue?.toString());
    FFAppState().homePageLastAudioBookId = id?.toString() ?? '';
    FFAppState().homePageLastAudioBookName = name?.toString() ?? '';
    FFAppState().homePageLastAudioBookAuthor =
        _stringValue(author, fallback: '');
    FFAppState().homePageLastAudioBookImage = imageUrl;
  }

  double _currentPreviewFraction() {
    if (!_isPreviewMode) {
      return 1.0;
    }
    final raw = _currentChapter?['previewFraction'];
    if (raw is num) {
      final value = raw.toDouble().clamp(0.0, 1.0);
      if (value > 0.0 && value < 1.0) {
        return value;
      }
      if (value == 0.0) {
        return 0.0;
      }
      if (_chapters.length > 1) {
        return 1.0;
      }
    }
    if (_currentIndex == 0 && _chapters.length == 1) {
      return (_previewPercent / 100).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  Duration? _currentPreviewLimit() {
    if (!_isPreviewMode || _duration <= Duration.zero) {
      return null;
    }
    final fraction = _currentPreviewFraction();
    if (fraction >= 1.0) {
      return null;
    }
    final limitedMs = (_duration.inMilliseconds * fraction)
        .floor()
        .clamp(0, _duration.inMilliseconds);
    return Duration(milliseconds: limitedMs);
  }

  Duration _effectiveDuration() {
    return _currentPreviewLimit() ?? _duration;
  }

  Duration _capPreviewPosition(Duration position) {
    if (position.isNegative) {
      return Duration.zero;
    }
    final limit = _currentPreviewLimit();
    if (limit != null && position > limit) {
      return limit;
    }
    return position;
  }

  Future<void> _seekTo(Duration position) async {
    final target = _capPreviewPosition(position);
    if (mounted) {
      setState(() => _position = target);
    }
    if (_videoMode) {
      await _videoController?.seekTo(target);
    } else {
      await _handler?.seek(target);
      _maybeHandlePreviewBoundary(target);
    }
  }

  void _clearPersistedAudiobookProgress() {
    FFAppState().homePageLastAudioBookId = '';
    FFAppState().homePageLastAudioBookName = '';
    FFAppState().homePageLastAudioBookAuthor = '';
    FFAppState().homePageLastAudioBookImage = '';
    FFAppState().homePageLastAudioPositionSec = 0;
    FFAppState().homePageLastAudioDurationSec = 0;
    FFAppState().homePageLastAudioProgress = 0.0;
    FFAppState().prefs.setInt('ff_homePageLastAudioTrackNumber', 1);
  }

  Future<void> _finishPreviewSession(Duration limit) async {
    if (_previewLimitShown) {
      return;
    }
    _previewLimitShown = true;
    if (mounted && _position != limit) {
      setState(() => _position = limit);
    }
    _clearPersistedAudiobookProgress();
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPreviewLimitDialog();
      }
    });
  }

  void _maybeHandlePreviewBoundary(Duration position) {
    if (!_isPreviewMode || _previewLimitShown) {
      return;
    }
    final limit = _currentPreviewLimit();
    if (limit == null || limit <= Duration.zero) {
      return;
    }
    if (position < limit) {
      return;
    }
    unawaited(_finishPreviewSession(limit));
  }

  void _persistAudiobookProgress(Duration position) {
    final bookId = _bookId();
    final totalSeconds = _duration.inSeconds;
    if (totalSeconds <= 0) {
      return;
    }
    final currentSeconds = position.inSeconds;
    if (_lastPersistedSecond >= 0 &&
        (currentSeconds - _lastPersistedSecond).abs() < 5) {
      return;
    }
    _lastPersistedSecond = currentSeconds;
    final progress = (currentSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();
    FFAppState().homePageLastAudioPositionSec = currentSeconds;
    FFAppState().homePageLastAudioDurationSec = totalSeconds;
    FFAppState().homePageLastAudioProgress = progress;
    final trackNum = _currentChapter?['track_number'] ?? (_currentIndex + 1);
    final parsedTrackNum =
        int.tryParse(trackNum.toString()) ?? (_currentIndex + 1);
    FFAppState()
        .prefs
        .setInt('ff_homePageLastAudioTrackNumber', parsedTrackNum);
    if (bookId.isNotEmpty) {
      unawaited(ProgressSyncService.saveListeningProgress(
        bookId: bookId,
        trackNumber: parsedTrackNum,
        positionSeconds: currentSeconds,
        totalSeconds: totalSeconds,
      ));
      if (_isPlaying) {
        PresenceTrackingService.instance.updateActivity(
          PresenceActivity.listening,
          bookId: bookId,
          currentPage: _formatDurationPresence(position),
        );
      }
    }
  }

  String _formatDurationPresence(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _initAmbientPlayer() {
    _ambientPlayer.setLoopMode(LoopMode.one);
    _ambientPlayer.setVolume(_ambientVolume);
  }

  Future<void> _loadAmbientTracks() async {
    try {
      if (TtsService.instance.ambientTracks.isEmpty) {
        await TtsService.instance.fetchAmbientTracks();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  List<Map<String, String>> _getAmbientTracks() {
    return TtsService.instance.ambientTracks.map((t) => {
      'name': '${t.emoji} ${t.label}'.trim().isNotEmpty ? '${t.emoji} ${t.label}'.trim() : t.name,
      'url': t.url,
    }).toList();
  }

  void _updateAmbientState() {
    if (!mounted) return;
    if (_ambientEnabled && _isPlaying && !_videoMode) {
      _ambientPlayer.play();
    } else {
      _ambientPlayer.pause();
    }
  }

  bool _hasVideo() {
    if (_currentChapter == null) return false;
    final file = (_currentChapter?['file'] ?? _currentChapter?['audio'] ?? '').toString().toLowerCase();
    
    final hasVideoUrl = _currentChapter?['video'] != null ||
                        _currentChapter?['videoUrl'] != null ||
                        _currentChapter?['video_url'] != null;

    bool isVideoFile = false;
    if (file.isNotEmpty) {
      try {
        final uri = Uri.parse(file);
        final path = uri.path.toLowerCase();
        isVideoFile = path.endsWith('.mp4') ||
                      path.endsWith('.m4v') ||
                      path.endsWith('.mov') ||
                      path.endsWith('.avi') ||
                      path.endsWith('.mkv') ||
                      path.endsWith('.webm');
      } catch (_) {
        isVideoFile = file.contains('.mp4') ||
                      file.contains('.m4v') ||
                      file.contains('.mov') ||
                      file.contains('.avi') ||
                      file.contains('.mkv') ||
                      file.contains('.webm');
      }
    }

    final raw = _currentChapter?['raw'];
    final isRawVideo = raw != null && (
      raw['is_video'] == true ||
      raw['isVideo'] == true ||
      raw['media_type']?.toString().toLowerCase() == 'video' ||
      raw['format']?.toString().toLowerCase() == 'video'
    );

    final rawIsVideo = _currentChapter?['isVideo'] == true ||
                       _currentChapter?['is_video'] == true ||
                       _currentChapter?['format']?.toString().toLowerCase() == 'video' ||
                       isRawVideo ||
                       widget.audiobook['isVideo'] == true ||
                       widget.audiobook['is_video'] == true ||
                       widget.audiobook['format']?.toString().toLowerCase() == 'video';

    return hasVideoUrl || isVideoFile || rawIsVideo;
  }

  String _resolveVideoUrl() {
    if (_currentChapter == null) return '';
    final videoUrl = _currentChapter?['video'] ??
                     _currentChapter?['videoUrl'] ??
                     _currentChapter?['video_url'] ??
                     _currentChapter?['file'] ??
                     _currentChapter?['audio'] ??
                     '';
    final raw = videoUrl.toString().trim();
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http')) {
      return raw;
    }
    final base = FFAppConstants.audiobookAudioUrl;
    if (raw.startsWith('/')) {
      return '$base${raw.substring(1)}';
    }
    return '$base$raw';
  }

  Future<void> _initVideoPlayer() async {
    if (!mounted) return;
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.dispose();
      _videoController = null;
    }

    final url = _resolveVideoUrl();
    if (url.isEmpty) return;

    final controller = url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.asset(url);

    _videoController = controller;

    setState(() {
      _videoLoading = true;
    });

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _duration = controller.value.duration;
      });
      controller.addListener(_videoListener);
      if (_isPlaying) {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Video init failed: $e');
      if (mounted) {
        setState(() {
          _videoLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_videoMode || _videoController == null) return;
    final val = _videoController!.value;
    setState(() {
      _position = val.position;
      _duration = val.duration;
      _isPlaying = val.isPlaying;
    });
    _updateAmbientState();
  }



  void _showAmbientSettingsSheet() {
    final tracks = _getAmbientTracks();
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Background Ambient Sound',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Switch(
                          value: _ambientEnabled,
                          activeColor: FlutterFlowTheme.of(context).primary,
                          onChanged: (val) async {
                            setState(() {
                              _ambientEnabled = val;
                            });
                            setModalState(() {});
                            if (val) {
                              if (_selectedAmbientIndex >= tracks.length) {
                                _selectedAmbientIndex = 0;
                              }
                              await _ambientPlayer.setUrl(tracks[_selectedAmbientIndex]['url']!);
                              _updateAmbientState();
                            } else {
                              await _ambientPlayer.pause();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Track',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isSelected = _selectedAmbientIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(track['name']!),
                              selected: isSelected,
                              selectedColor: FlutterFlowTheme.of(context).primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : FlutterFlowTheme.of(context).primaryText,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: _ambientEnabled
                                  ? (selected) async {
                                      if (selected) {
                                        setState(() {
                                          _selectedAmbientIndex = index;
                                        });
                                        setModalState(() {});
                                        await _ambientPlayer.setUrl(track['url']!);
                                        _updateAmbientState();
                                      }
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ambient Volume',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${(_ambientVolume * 100).toInt()}%',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _ambientVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: FlutterFlowTheme.of(context).primary,
                      inactiveColor: FlutterFlowTheme.of(context).gray200,
                      onChanged: _ambientEnabled
                          ? (val) {
                              setState(() {
                                _ambientVolume = val;
                              });
                              setModalState(() {});
                              _ambientPlayer.setVolume(val);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _setSpeed(double speed) async {
    final handler = _handler ?? await AudioPlaybackService.handler;
    _handler = handler;
    await handler.setSpeed(speed);
    if (mounted) {
      setState(() => _speed = speed);
    }
  }

  void _setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      setState(() => _sleepLabel = 'Off');
      return;
    }
    final minutes = duration.inMinutes;
    setState(() => _sleepLabel = '${minutes}m');
    _sleepTimer = Timer(duration, () async {
      await _handler?.pause();
      if (mounted) {
        setState(() => _sleepLabel = 'Off');
      }
    });
  }

  void _showSpeedSheet() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: speeds
                .map((speed) => ListTile(
                      title: Text('${speed.toStringAsFixed(2)}x'),
                      trailing: _speed == speed
                          ? Icon(Icons.check,
                              color: FlutterFlowTheme.of(context).primary)
                          : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await _setSpeed(speed);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showChaptersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _chapters.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final chapter = _chapters[index];
              final title = chapter['title'] ?? 'Chapter ${index + 1}';
              final isCurrent = index == _currentIndex;
              return ListTile(
                title: Text(title.toString()),
                trailing: isCurrent
                    ? Icon(Icons.play_arrow_rounded,
                        color: FlutterFlowTheme.of(context).primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _playChapterAt(index);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet() {
    final options = <String, Duration?>{
      'Off': null,
      '5 min': Duration(minutes: 5),
      '10 min': Duration(minutes: 10),
      '15 min': Duration(minutes: 15),
      '30 min': Duration(minutes: 30),
      '45 min': Duration(minutes: 45),
      '60 min': Duration(minutes: 60),
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: options.entries.map((entry) {
              final label = entry.key;
              return ListTile(
                title: Text(label),
                trailing: _sleepLabel == label ||
                        _sleepLabel == label.replaceAll(' min', 'm')
                    ? Icon(Icons.check,
                        color: FlutterFlowTheme.of(context).primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _setSleepTimer(entry.value);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final buffer = StringBuffer();
    if (hours > 0) {
      buffer.write(hours.toString().padLeft(2, '0'));
      buffer.write(':');
    }
    buffer.write(minutes.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(seconds.toString().padLeft(2, '0'));
    return buffer.toString();
  }

  String _resolveBookImage(String? imagePath) {
    final trimmed = (imagePath ?? '').trim();
    if (trimmed.isEmpty) {
      return 'https://picsum.photos/seed/audiobook-cover/600/600';
    }
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${FFAppConstants.bookImagesUrl}$trimmed';
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? trimmed : fallback;
    }
    if (value is Map) {
      final name = value['name'] ?? value['title'] ?? value['full_name'];
      if (name != null) {
        final s = name.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return fallback;
    }
    if (value is List) {
      final names = value
          .map((e) => _stringValue(e, fallback: ''))
          .where((e) => e.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
      return fallback;
    }
    final out = value.toString().trim();
    return out.isNotEmpty ? out : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = _stringValue(
      _currentChapter?['title'] ??
          _currentChapter?['name'] ??
          widget.chapter['title'] ??
          widget.chapter['name'],
      fallback: 'Chapter',
    );
    final authorName = _stringValue(
      widget.audiobook['author'] ??
          widget.audiobook['authorName'] ??
          widget.audiobook['authors'] ??
          getJsonField(widget.audiobook, r'''$.authors.name''') ??
          getJsonField(widget.audiobook, r'''$.narrators.name'''),
      fallback: 'Author',
    );
    final bookName = _stringValue(
      widget.audiobook['title'] ?? widget.audiobook['name'],
      fallback: '',
    );
    final coverImage = _resolveBookImage(widget.audiobook['image']?.toString());
    final effectiveDuration = _effectiveDuration();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: FlutterFlowTheme.of(context).primaryText, size: 30),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Now Playing',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded,
                  color: FlutterFlowTheme.of(context).primaryText),
              onPressed: () {},
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0.0, 0.65),
              colors: [
                FlutterFlowTheme.of(context).primary.withValues(alpha: 0.10),
                FlutterFlowTheme.of(context).primaryBackground,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // if (_hasVideo())
                //   Padding(
                //     padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                //     child: Container(
                //       padding: const EdgeInsets.all(4),
                //       decoration: BoxDecoration(
                //         color: FlutterFlowTheme.of(context).secondaryBackground,
                //         borderRadius: BorderRadius.circular(24),
                //       ),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           GestureDetector(
                //             onTap: () => _setVideoMode(false),
                //             child: Container(
                //               padding: const EdgeInsets.symmetric(
                //                   horizontal: 16, vertical: 8),
                //               decoration: BoxDecoration(
                //                 color: !_videoMode
                //                     ? FlutterFlowTheme.of(context).primary
                //                     : Colors.transparent,
                //                 borderRadius: BorderRadius.circular(20),
                //               ),
                //               child: Row(
                //                 children: [
                //                   Icon(
                //                     Icons.audiotrack_rounded,
                //                     color: !_videoMode
                //                         ? Colors.white
                //                         : FlutterFlowTheme.of(context).primaryText,
                //                     size: 16,
                //                   ),
                //                   const SizedBox(width: 6),
                //                   Text(
                //                     'Audio',
                //                     style: TextStyle(
                //                       color: !_videoMode
                //                           ? Colors.white
                //                           : FlutterFlowTheme.of(context).primaryText,
                //                       fontWeight: FontWeight.bold,
                //                       fontSize: 13,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //           const SizedBox(width: 4),
                //           GestureDetector(
                //             onTap: () => _setVideoMode(true),
                //             child: Container(
                //               padding: const EdgeInsets.symmetric(
                //                   horizontal: 16, vertical: 8),
                //               decoration: BoxDecoration(
                //                 color: _videoMode
                //                     ? FlutterFlowTheme.of(context).primary
                //                     : Colors.transparent,
                //                 borderRadius: BorderRadius.circular(20),
                //               ),
                //               child: Row(
                //                 children: [
                //                   Icon(
                //                     Icons.videocam_rounded,
                //                     color: _videoMode
                //                         ? Colors.white
                //                         : FlutterFlowTheme.of(context).primaryText,
                //                     size: 16,
                //                   ),
                //                   const SizedBox(width: 6),
                //                   Text(
                //                     'Video',
                //                     style: TextStyle(
                //                       color: _videoMode
                //                           ? Colors.white
                //                           : FlutterFlowTheme.of(context).primaryText,
                //                       fontWeight: FontWeight.bold,
                //                       fontSize: 13,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // // Album Art
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availH = constraints.maxHeight;
                          final idealW = (MediaQuery.of(context).size.width - 40) * 0.85;
                          final idealH = idealW * 1.5;
                          final coverH = idealH.clamp(0.0, availH);
                          final coverW = coverH * (2.0 / 3.0);
                          
                          final double playerW = _videoMode
                              ? (MediaQuery.of(context).size.width - 40)
                              : coverW;
                              
                          final double playerH = _videoMode
                              ? (_videoController != null && _videoController!.value.isInitialized
                                  ? (playerW / _videoController!.value.aspectRatio).clamp(0.0, availH)
                                  : playerW * (9 / 16)).clamp(0.0, availH)
                              : coverH;
                              
                          return SizedBox(
                            width: playerW,
                            height: playerH,
                            child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 48.0,
                                  color: Colors.black.withValues(alpha: 0.45),
                                  offset: Offset(0, 24),
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  blurRadius: 24.0,
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withValues(alpha: 0.2),
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: _videoMode
                                  ? (_videoController != null && _videoController!.value.isInitialized
                                      ? Center(
                                          child: AspectRatio(
                                            aspectRatio: _videoController!.value.aspectRatio,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                VideoPlayer(_videoController!),
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (context) => FullscreenVideoPage(
                                                            controller: _videoController!,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.fullscreen_rounded,
                                                      color: Colors.white54,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.black,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                FlutterFlowTheme.of(context).primary,
                                              ),
                                            ),
                                          ),
                                        ))
                                  : Image.network(
                                      coverImage,
                                      fit: BoxFit.fill,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        child: Icon(
                                          Icons.library_books_rounded,
                                          size: 64,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                  ).animateOnPageLoad(
                      animationsMap['imageOnPageLoadAnimation']!),
                ),

                // Book name + Chapter + Author
                Column(
                  children: [
                    if (bookName.isNotEmpty && bookName != chapterTitle) ...[
                      Text(
                        bookName.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              color: FlutterFlowTheme.of(context).primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                      ),
                      SizedBox(height: 4),
                    ],
                    Text(
                      chapterTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      authorName,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                if (_isPreviewMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: Colors.orange, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Preview ($_previewPercent%) — Buy to unlock full audiobook',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 6),

                // Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: FlutterFlowTheme.of(context).primary,
                        inactiveTrackColor:
                            FlutterFlowTheme.of(context).gray200,
                        thumbColor: FlutterFlowTheme.of(context).primary,
                        overlayColor: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: (effectiveDuration.inMilliseconds > 0)
                            ? _position.inMilliseconds
                                .toDouble()
                                .clamp(0,
                                    effectiveDuration.inMilliseconds.toDouble())
                                .toDouble()
                            : 0.0,
                        min: 0,
                        max: effectiveDuration.inMilliseconds > 0
                            ? effectiveDuration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (val) {
                          setState(() {
                            _position = _capPreviewPosition(
                              Duration(milliseconds: val.toInt()),
                            );
                          });
                        },
                        onChangeEnd: (val) {
                          _seekTo(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12),
                          ),
                          Text(
                            _formatDuration(effectiveDuration),
                            style: TextStyle(
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 30),
                      onPressed: () {
                        if (_chapters.isNotEmpty && _currentIndex > 0) {
                          _playChapterAt(_currentIndex - 1);
                        } else {
                          _seekTo(Duration.zero);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.replay_10_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 30),
                      onPressed: () {
                        final target = _position - Duration(seconds: 10);
                        _seekTo(target.isNegative ? Duration.zero : target);
                      },
                    ),
                    // Play/Pause Button
                    _videoMode
                        ? InkWell(
                            onTap: () {
                              if (_videoController == null) return;
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                                setState(() {
                                  _isPlaying = false;
                                });
                              } else {
                                _videoController!.play();
                                setState(() {
                                  _isPlaying = true;
                                });
                              }
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 20.0,
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withValues(alpha: 0.3),
                                    offset: Offset(0, 10),
                                  )
                                ],
                              ),
                              child: _videoLoading
                                  ? Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                            ),
                          )
                        : StreamBuilder<PlaybackState>(
                            stream: _handler?.playbackState,
                            builder: (context, snapshot) {
                              final state = snapshot.data;
                              final isPlaying = state?.playing ?? false;
                              final processingState = state?.processingState;
                              final isLoading = processingState ==
                                      AudioProcessingState.loading ||
                                  processingState == AudioProcessingState.buffering;
                              return InkWell(
                                onTap: () {
                                  if (_handler == null) {
                                    return;
                                  }
                                  if (isPlaying) {
                                    _handler!.pause();
                                  } else {
                                    _handler!.play();
                                  }
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 20.0,
                                        color: FlutterFlowTheme.of(context)
                                            .primary
                                            .withValues(alpha: 0.3),
                                        offset: Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: isLoading
                                      ? Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 34,
                                        ),
                                ),
                              );
                            },
                          ),
                    IconButton(
                      icon: Icon(Icons.forward_10_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 30),
                      onPressed: () {
                        final target = _position + Duration(seconds: 10);
                        _seekTo(target);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: (_isPreviewMode &&
                                _currentIndex >= _chapters.length - 1)
                            ? FlutterFlowTheme.of(context).secondaryText
                            : FlutterFlowTheme.of(context).primaryText,
                        size: 30,
                      ),
                      onPressed: (_isPreviewMode &&
                              _currentIndex >= _chapters.length - 1)
                          ? null
                          : () {
                              if (_chapters.isNotEmpty &&
                                  _currentIndex < _chapters.length - 1) {
                                _playChapterAt(_currentIndex + 1);
                              }
                            },
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // Bottom Icons Row
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context)
                        .secondaryBackground
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomAction(
                        context,
                        '${_speed.toStringAsFixed(2)}x',
                        'Speed',
                        onTap: _showSpeedSheet,
                      ),
                      _buildBottomAction(
                        context,
                        Icons.format_list_bulleted_rounded,
                        'Episodes',
                        onTap: _showChaptersSheet,
                      ),
                      _buildBottomAction(
                        context,
                        Icons.timer_outlined,
                        _sleepLabel == 'Off'
                            ? 'Sleep Timer'
                            : 'Sleep $_sleepLabel',
                        onTap: _showSleepTimerSheet,
                      ),
                      _buildBottomAction(
                        context,
                        Icons.spa_rounded,
                        _ambientEnabled ? 'Ambient: On' : 'Ambient',
                        onTap: _showAmbientSettingsSheet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    dynamic icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is IconData)
              Icon(icon,
                  color: FlutterFlowTheme.of(context).primaryText, size: 24)
            else
              Text(
                icon,
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPage({super.key, required this.controller});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    // Immersive fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Cinema Landscape rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    widget.controller.addListener(_videoListener);
    _startControlsTimer();
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    _controlsTimer?.cancel();
    // Restore orientations and status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isInitialized = controller.value.isInitialized;
    final isPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls Overlay
            if (_showControls)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Stack(
                  children: [
                    // Exit Button
                    Positioned(
                      top: 24,
                      left: 24,
                      child: SafeArea(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),

                    // Centered Play/Pause Button
                    Center(
                      child: InkWell(
                        onTap: () {
                          if (isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                          _startControlsTimer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    // Premium seek controls at bottom
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: Colors.white12,
                              ),
                              child: Slider(
                                value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                                min: 0.0,
                                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                onChanged: (val) {
                                  controller.seekTo(Duration(milliseconds: val.toInt()));
                                  _startControlsTimer();
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

