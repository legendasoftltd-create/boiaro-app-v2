import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/audio_playback_service.dart';
import '/app_constants.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();
  AudiobookAudioHandler? _handler;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<Map<String, dynamic>> _chapters = [];
  int _currentIndex = 0;
  Map<String, dynamic>? _currentChapter;
  double _speed = 1.0;
  Timer? _sleepTimer;
  String _sleepLabel = 'Off';
  int _lastPersistedSecond = -1;

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
    _initializeChapters();
    _persistAudiobookMeta();
    _initAudio();
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
    _positionSub = AudioService.position.listen((pos) {
      if (!mounted) {
        return;
      }
      setState(() => _position = pos);
      _persistAudiobookProgress(pos);
    });
    _mediaItemSub = handler.mediaItem.listen((item) {
      if (!mounted) {
        return;
      }
      setState(() => _duration = item?.duration ?? Duration.zero);
      _persistAudiobookProgress(_position);
    });
    await handler.playChapter(
      audiobook: widget.audiobook,
      chapter: _currentChapter ?? widget.chapter,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mediaItemSub?.cancel();
    _sleepTimer?.cancel();
    _model.dispose();
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
          'isLocked': chapter['isLocked'] ?? chapter['is_locked'] ?? false,
          'isPreview': chapter['isPreview'] ?? chapter['is_preview'] ?? false,
          'raw': chapter,
        };
      }
      return {
        'title': 'Chapter',
        'file': chapter?.toString(),
        'isLocked': false,
        'isPreview': false,
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

  Future<void> _playChapterAt(int index) async {
    if (index < 0 || index >= _chapters.length) {
      return;
    }
    final handler = _handler ?? await AudioPlaybackService.handler;
    _handler = handler;
    setState(() {
      _currentIndex = index;
      _currentChapter = _chapters[index];
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    _persistAudiobookMeta();
    await handler.playChapter(
      audiobook: widget.audiobook,
      chapter: _currentChapter ?? widget.chapter,
    );
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
    FFAppState().homePageLastAudioBookAuthor = author?.toString() ?? '';
    FFAppState().homePageLastAudioBookImage = imageUrl;
  }

  void _persistAudiobookProgress(Duration position) {
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
    final progress =
        (currentSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();
    FFAppState().homePageLastAudioPositionSec = currentSeconds;
    FFAppState().homePageLastAudioDurationSec = totalSeconds;
    FFAppState().homePageLastAudioProgress = progress;
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
                          ? Icon(Icons.check, color: FlutterFlowTheme.of(context).primary)
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
                trailing: _sleepLabel == label || _sleepLabel == label.replaceAll(' min', 'm')
                    ? Icon(Icons.check, color: FlutterFlowTheme.of(context).primary)
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

  @override
  Widget build(BuildContext context) {
    final chapterTitle = _currentChapter?['title'] ??
        _currentChapter?['name'] ??
        widget.chapter['title'] ??
        widget.chapter['name'] ??
        'Chapter';
    final authorName = widget.audiobook['author'] ??
        widget.audiobook['authorName'] ??
        'Author';
    final coverImage = _resolveBookImage(widget.audiobook['image']?.toString());

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
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 30),
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
              icon: Icon(Icons.more_vert_rounded, color: FlutterFlowTheme.of(context).primaryText),
              onPressed: () {},
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Art
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 40.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(0, 20),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: Image.network(
                          coverImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animateOnPageLoad(animationsMap['imageOnPageLoadAnimation']!),
                  ),
                ),

                // Title and Author
                Column(
                  children: [
                    Text(
                      chapterTitle,
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      authorName,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),

                SizedBox(height: 48),

                // Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: FlutterFlowTheme.of(context).primary,
                        inactiveTrackColor: FlutterFlowTheme.of(context).gray200,
                        thumbColor: FlutterFlowTheme.of(context).primary,
                        overlayColor: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: (_duration.inMilliseconds > 0)
                            ? _position.inMilliseconds
                                .toDouble()
                                .clamp(0, _duration.inMilliseconds.toDouble())
                                .toDouble()
                            : 0.0,
                        min: 0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (val) {
                          setState(() {
                            _position = Duration(milliseconds: val.toInt());
                          });
                        },
                        onChangeEnd: (val) {
                          _handler?.seek(Duration(milliseconds: val.toInt()));
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
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {
                        if (_chapters.isNotEmpty && _currentIndex > 0) {
                          _playChapterAt(_currentIndex - 1);
                        } else {
                          _handler?.seek(Duration.zero);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.replay_10_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {
                        final target = _position - Duration(seconds: 10);
                        _handler?.seek(target.isNegative ? Duration.zero : target);
                      },
                    ),
                    // Play/Pause Button
                    StreamBuilder<PlaybackState>(
                      stream: _handler?.playbackState,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final isPlaying = state?.playing ?? false;
                        final processingState = state?.processingState;
                        final isLoading = processingState == AudioProcessingState.loading ||
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
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 20.0,
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.3),
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
                                    size: 40,
                                  ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {
                        final target = _position + Duration(seconds: 10);
                        _handler?.seek(target);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {
                        if (_chapters.isNotEmpty &&
                            _currentIndex < _chapters.length - 1) {
                          _playChapterAt(_currentIndex + 1);
                        }
                      },
                    ),
                  ],
                ),

                SizedBox(height: 48),

                // Bottom Icons Row
                Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
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
                        _sleepLabel == 'Off' ? 'Sleep Timer' : 'Sleep $_sleepLabel',
                        onTap: _showSleepTimerSheet,
                      ),
                    ],
                  ),
                ),
              ],
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
