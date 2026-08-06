import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/radio/radio_chat.dart';
import '../../services/radio/radio_api_service.dart';

class CatchupPodcastsPage extends StatefulWidget {
  static const String routeName = 'CatchupPodcastsPage';
  static const String routePath = '/catchupPodcastsPage';

  const CatchupPodcastsPage({Key? key}) : super(key: key);

  @override
  State<CatchupPodcastsPage> createState() => _CatchupPodcastsPageState();
}

class _CatchupPodcastsPageState extends State<CatchupPodcastsPage> with SingleTickerProviderStateMixin {
  final RadioApiService _apiService = RadioApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<CatchupRecording> _recordings = [];
  List<CatchupRecording> _history = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  CatchupRecording? _currentlyPlaying;
  Timer? _progressTimer;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecordings();
    _loadHistory();
    _listenPlayerEvents();
  }

  void _listenPlayerEvents() {
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() {});
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _saveProgress();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getCatchupRecordings(limit: 20);
    _recordings = result['sessions'] as List<CatchupRecording>;
    _nextCursor = result['next_cursor'];
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreRecordings() async {
    if (_nextCursor == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final result = await _apiService.getCatchupRecordings(limit: 20, cursor: _nextCursor);
    final items = result['sessions'] as List<CatchupRecording>;
    _recordings.addAll(items);
    _nextCursor = result['next_cursor'];
    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadHistory() async {
    final history = await _apiService.getCatchupHistory();
    if (mounted) {
      setState(() => _history = history);
    }
  }

  Future<void> _playRecording(CatchupRecording rec) async {
    if (_currentlyPlaying?.id == rec.id && _audioPlayer.playing) {
      await _audioPlayer.pause();
      _saveProgress();
      return;
    }

    _currentlyPlaying = rec;
    _progressTimer?.cancel();

    // Call /play endpoint
    await _apiService.recordCatchupPlay(rec.id);

    // Fetch saved progress
    final progress = await _apiService.getCatchupProgress(rec.id);

    try {
      await _audioPlayer.setUrl(rec.recordingUrl);
      if (progress != null && progress.positionSeconds > 0) {
        await _audioPlayer.seek(Duration(seconds: progress.positionSeconds));
      }
      await _audioPlayer.play();

      // Start 15s auto-save timer
      _progressTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _saveProgress();
      });
    } catch (e) {
      debugPrint('CatchupPodcastsPage play error: $e');
    }
    setState(() {});
  }

  void _saveProgress() {
    if (_currentlyPlaying == null) return;
    final posSec = _audioPlayer.position.inSeconds;
    final durSec = _audioPlayer.duration?.inSeconds ?? 0;
    _apiService.saveCatchupProgress(
      _currentlyPlaying!.id,
      positionSeconds: posSec,
      durationSeconds: durSec,
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveProgress();
    _audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: Text(
          'Catch-up Podcasts',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF4757),
          tabs: const [
            Tab(text: 'All Episodes'),
            Tab(text: 'My History'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEpisodesList(_recordings),
                _buildEpisodesList(_history),
              ],
            ),
          ),

          // Sticky On-Demand Player Bar
          if (_currentlyPlaying != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildEpisodesList(List<CatchupRecording> list) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4757)));
    }
    if (list.isEmpty) {
      return const Center(child: Text('No podcast recordings available.', style: TextStyle(color: Colors.grey)));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreRecordings();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == list.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
          }
          final rec = list[index];
          final isPlayingThis = _currentlyPlaying?.id == rec.id && _audioPlayer.playing;

          return Card(
            color: const Color(0xFF1E1E36),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [Color(0xFFFF4757), Color(0xFFFF6B81)]),
                ),
                child: const Icon(Icons.podcasts, color: Colors.white, size: 28),
              ),
              title: Text(
                rec.showTitle,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                'RJ ${rec.rjStageName} • ${_formatDate(rec.startedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: IconButton(
                icon: Icon(
                  isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: const Color(0xFFFF4757),
                  size: 40,
                ),
                onPressed: () => _playRecording(rec),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final rec = _currentlyPlaying!;
    final pos = _audioPlayer.position;
    final dur = _audioPlayer.duration ?? Duration.zero;

    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF16162A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec.showTitle,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              IconButton(
                icon: Icon(_audioPlayer.playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: () => _playRecording(rec),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
              max: dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0,
              activeColor: const Color(0xFFFF4757),
              inactiveColor: Colors.white24,
              onChanged: (val) {
                _audioPlayer.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
