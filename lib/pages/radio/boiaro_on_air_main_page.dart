import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/radio/radio_station.dart';
import '../../models/radio/live_session.dart';
import '../../models/radio/radio_chat.dart';
import '../../services/radio/radio_api_service.dart';
import '../../services/radio/radio_socket_service.dart';
import '../../services/radio/radio_audio_player_service.dart';
import '../../services/radio/radio_webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../flutter_flow/flutter_flow_theme.dart';

class BoiAroOnAirMainPage extends StatefulWidget {
  static const String routeName = 'BoiAroOnAirMainPage';
  static const String routePath = '/boiAroOnAirMainPage';

  const BoiAroOnAirMainPage({Key? key}) : super(key: key);

  @override
  State<BoiAroOnAirMainPage> createState() => _BoiAroOnAirMainPageState();
}

class _BoiAroOnAirMainPageState extends State<BoiAroOnAirMainPage> with SingleTickerProviderStateMixin {
  final RadioApiService _apiService = RadioApiService();
  final RadioSocketService _socketService = RadioSocketService();
  final RadioAudioPlayerService _playerService = RadioAudioPlayerService();
  final RadioWebRTCService _webrtcService = RadioWebRTCService();

  List<RadioStation> _stations = [];
  RadioStation? _selectedStation;
  LiveSession? _liveSession;
  int _listenerCount = 0;
  bool _isLoading = true;

  // Chat & Reactions
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<ChatMessage> _chatMessages = [];
  List<FloatingReaction> _floatingReactions = [];
  DateTime? _lastMessageSentAt;

  // Song Requests
  final TextEditingController _songRequestController = TextEditingController();
  List<SongRequest> _mySongRequests = [];

  // Call-In State
  CallInRequest? _myCallStatus;
  bool _callConsentGiven = false;



  // Subscriptions
  StreamSubscription? _listenerSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _chatDeletedSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _requestSub;
  StreamSubscription? _requestUpdatedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _callStatusSub;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _liveSession != null) {
        _fetchMyCallStatus(_liveSession!.id);
      }
    });
    _playerService.addListener(_onPlayerStateChanged);
    _webrtcService.addListener(_onWebRTCStateChanged);
    _fetchInitialData();
  }

  void _onPlayerStateChanged() {
    if (mounted) setState(() {});
  }

  void _onWebRTCStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final stations = await _apiService.getStations();
    final live = await _apiService.getLiveSession();
    _stations = stations;
    _liveSession = live;

    if (_stations.isNotEmpty) {
      _selectedStation = live?.station ?? _stations.first;
    }

    if (_liveSession != null) {
      _listenerCount = _liveSession!.listenerCount;
      _initSessionRealtime(_liveSession!.id);
    } else if (_selectedStation != null && _selectedStation!.streamUrl != null) {
      _playerService.playLive(station: _selectedStation);
    }

    setState(() => _isLoading = false);
  }

  void _initSessionRealtime(String sessionId) {
    if (_webrtcService.isCallActive) {
      print('[BoiaroOnAirPage] Switching session while call is active. Ending previous WebRTC call.');
      _webrtcService.endCall();
    }
    _socketService.connectAndJoin(sessionId);
    _fetchChatHistory(sessionId);
    _fetchMyCallStatus(sessionId);
    _fetchMySongRequests(sessionId);

    // Auto play stream
    _playerService.playLive(liveSession: _liveSession, station: _selectedStation);

    // Cancel old subs
    _listenerSub?.cancel();
    _chatSub?.cancel();
    _chatDeletedSub?.cancel();
    _reactionSub?.cancel();
    _requestSub?.cancel();
    _requestUpdatedSub?.cancel();
    _errorSub?.cancel();
    _callStatusSub?.cancel();

    _listenerSub = _socketService.onListenerCount.listen((count) {
      if (mounted) setState(() => _listenerCount = count);
    });

    _chatSub = _socketService.onChatNew.listen((msg) {
      if (mounted) {
        setState(() {
          _chatMessages.add(msg);
        });
        _scrollToBottom();
      }
    });

    _chatDeletedSub = _socketService.onChatDeleted.listen((id) {
      if (mounted) {
        setState(() {
          _chatMessages.removeWhere((m) => m.id == id);
        });
      }
    });

    _reactionSub = _socketService.onReactionNew.listen((data) {
      final emoji = data['emoji']?.toString() ?? '❤️';
      _triggerFloatingEmoji(emoji);
    });

    _requestSub = _socketService.onSongRequestNew.listen((req) {
      if (mounted) {
        setState(() {
          _mySongRequests.insert(0, req);
        });
      }
    });

    _requestUpdatedSub = _socketService.onSongRequestUpdated.listen((data) {
      print('[BoiaroOnAirPage] Received song_request:updated: $data');
      if (_liveSession != null) {
        _fetchMySongRequests(_liveSession!.id);
      }
      final reqId = data['requestId']?.toString() ?? data['id']?.toString() ?? data['request_id']?.toString();
      final status = data['status']?.toString();
      if (mounted && reqId != null && status != null) {
        setState(() {
          final idx = _mySongRequests.indexWhere((r) => r.id == reqId);
          if (idx != -1) {
            final old = _mySongRequests[idx];
            _mySongRequests[idx] = SongRequest(
              id: old.id,
              userId: old.userId,
              displayName: old.displayName,
              requestText: old.requestText,
              status: status,
              createdAt: old.createdAt,
            );
          }
        });
      }
    });

    _errorSub = _socketService.onError.listen((err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    _callStatusSub = _socketService.onCallInStatus.listen((callStatus) {
      print('[BoiaroOnAirPage] Received callin:status socket event: status=${callStatus.status}, callId=${callStatus.callId}');
      if (mounted) {
        setState(() => _myCallStatus = callStatus);
        if (_liveSession != null) {
          _fetchMyCallStatus(_liveSession!.id);
        }
        final targetHostId = callStatus.hostUserId ?? _liveSession?.rjUserId;
        print('[BoiaroOnAirPage] callStatus.isOnAir evaluated. targetHostId: $targetHostId, isOnAir: ${callStatus.isOnAir}');
        if (callStatus.isOnAir && targetHostId != null) {
          print('[BoiaroOnAirPage] Triggering _webrtcService.initializeCall with targetHostId: $targetHostId');
          _webrtcService.initializeCall(targetHostId, isCaller: true);
        } else if (!callStatus.isOnAir && _webrtcService.isCallActive) {
          print('[BoiaroOnAirPage] Call status is no longer on-air via socket. Ending WebRTC call.');
          _webrtcService.endCall();
        }
      }
    });
  }

  Future<void> _fetchChatHistory(String sessionId) async {
    final history = await _apiService.getChatHistory(sessionId);
    if (mounted) {
      setState(() => _chatMessages = history);
      _scrollToBottom();
    }
  }

  Future<void> _fetchMySongRequests(String sessionId) async {
    print('[BoiaroOnAirPage] Fetching song requests for session: $sessionId');
    final requests = await _apiService.getSongRequests(sessionId);
    print('[BoiaroOnAirPage] Fetched ${requests.length} song requests');
    if (mounted) {
      setState(() => _mySongRequests = requests);
    }
  }

  Future<void> _fetchMyCallStatus(String sessionId) async {
    print('[BoiaroOnAirPage] _fetchMyCallStatus calling for session $sessionId');
    final status = await _apiService.getMyCallInStatus(sessionId);
    print('[BoiaroOnAirPage] _fetchMyCallStatus returned: status=${status?.status}, hostUserId=${status?.hostUserId}');
    if (mounted) {
      setState(() => _myCallStatus = status);
      final targetHostId = status?.hostUserId ?? _liveSession?.rjUserId;
      print('[BoiaroOnAirPage] _fetchMyCallStatus processing. isOnAir: ${status?.isOnAir}, targetHostId: $targetHostId, isCallActive: ${_webrtcService.isCallActive}');
      if (status != null && status.isOnAir && targetHostId != null && !_webrtcService.isCallActive) {
        print('[BoiaroOnAirPage] Triggering _webrtcService.initializeCall from _fetchMyCallStatus with targetHostId: $targetHostId');
        _webrtcService.initializeCall(targetHostId, isCaller: true);
      } else if ((status == null || !status.isOnAir) && _webrtcService.isCallActive) {
        print('[BoiaroOnAirPage] Call status is no longer on-air (status is null or isOnAir is false). Ending stale active call.');
        _webrtcService.endCall();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerFloatingEmoji(String emoji) {
    if (!mounted) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _floatingReactions.add(FloatingReaction(id: id, emoji: emoji));
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _floatingReactions.removeWhere((r) => r.id == id);
        });
      }
    });
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    print('[BoiaroOnAirPage] _sendChatMessage triggered with text: "$text"');
    if (text.isEmpty) {
      print('[BoiaroOnAirPage] Chat text is empty, ignoring');
      return;
    }
    if (_liveSession == null) {
      print('[BoiaroOnAirPage] ERROR: _liveSession is NULL, cannot send chat message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send message: No active live session')),
      );
      return;
    }

    if (_lastMessageSentAt != null) {
      final diff = DateTime.now().difference(_lastMessageSentAt!).inSeconds;
      if (diff < 2) {
        print('[BoiaroOnAirPage] Slow mode active ($diff s < 2s)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait 2 seconds between messages (Slow mode)')),
        );
        return;
      }
    }

    print('[BoiaroOnAirPage] Calling _socketService.sendChat');
    _socketService.sendChat(text);
    _lastMessageSentAt = DateTime.now();
    _chatController.clear();
  }

  void _sendEmojiReaction(String emoji) {
    print('[BoiaroOnAirPage] _sendEmojiReaction triggered with emoji: "$emoji"');
    if (_liveSession == null) {
      print('[BoiaroOnAirPage] ERROR: _liveSession is NULL, cannot send emoji reaction');
      return;
    }
    print('[BoiaroOnAirPage] Calling _socketService.sendReaction');
    _socketService.sendReaction(emoji);
    _triggerFloatingEmoji(emoji);
  }

  void _sendSongRequest() async {
    final text = _songRequestController.text.trim();
    if (text.isEmpty || _liveSession == null) return;

    final success = await _apiService.sendSongRequest(_liveSession!.id, text);
    if (success) {
      _songRequestController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song request submitted to RJ!')),
      );
      _fetchMySongRequests(_liveSession!.id);
    }
  }

  void _requestCallIn() async {
    if (_liveSession == null) return;

    // Check and request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to call on-air. Please enable it in Settings.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!_callConsentGiven) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Listener Call-In Disclaimer'),
          content: const Text(
            'By requesting to call in, you consent to your voice being broadcast live on BoiAro On Air and recorded for catch-up podcasts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4757)),
              child: const Text('Agree & Call'),
            ),
          ],
        ),
      );
      if (agreed != true) return;
      setState(() => _callConsentGiven = true);
    }

    final req = await _apiService.requestCallIn(_liveSession!.id);
    if (req != null && mounted) {
      setState(() => _myCallStatus = req);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call-in request sent to RJ!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send Call-In request. Please verify Call-In is enabled for this show.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _endCallIn() async {
    print('[BoiaroOnAirPage] Listener ending call/request...');
    
    // 1. End WebRTC connection locally if active
    await _webrtcService.endCall();
    
    // 2. Call API to update status to 'end' if we have a valid call record
    if (_myCallStatus != null) {
      final callId = _myCallStatus!.callId;
      print('[BoiaroOnAirPage] Updating call status to end for callId=$callId');
      await _apiService.updateCallInStatus(callId, 'end');
      if (mounted) {
        setState(() {
          _myCallStatus = null;
        });
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call / Request ended.')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _songRequestController.dispose();

    _listenerSub?.cancel();
    _chatSub?.cancel();
    _chatDeletedSub?.cancel();
    _reactionSub?.cancel();
    _requestSub?.cancel();
    _errorSub?.cancel();
    _callStatusSub?.cancel();

    _playerService.removeListener(_onPlayerStateChanged);
    _webrtcService.removeListener(_onWebRTCStateChanged);
    print('[BoiaroOnAirPage] Disposing page. Ending WebRTC call to clean up resources.');
    _webrtcService.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: FlutterFlowTheme.of(context).primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'BoiAro On Air',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading)
                LinearProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                ),

              // Combined Header & Player control bar
              _buildHeaderPlayerControl(),

              // Navigation Tabs
              Container(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: FlutterFlowTheme.of(context).primary,
                  labelColor: FlutterFlowTheme.of(context).primary,
                  unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
                  tabs: const [
                    Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Live Chat'),
                    Tab(icon: Icon(Icons.music_note_outlined), text: 'Requests'),
                    Tab(icon: Icon(Icons.phone_in_talk_outlined), text: 'Call-In'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatTab(),
                    _buildSongRequestsTab(),
                    _buildCallInTab(),
                  ],
                ),
              ),
            ],
          ),

          // Floating Reaction Animations Overlay
          IgnorePointer(
            child: Stack(
              children: _floatingReactions.map((r) => _buildAnimatedReaction(r)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPlayerControl() {
    final live = _liveSession;
    final isPlaying = _playerService.isPlaying;
    final isLoading = _playerService.isLoading;
    final hasQuality = _selectedStation?.hasQualityOptions == true;



    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        border: Border(
          bottom: BorderSide(color: FlutterFlowTheme.of(context).alternate),
        ),
      ),
      child: Row(
        children: [
          // 1. RJ Avatar / Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.8),
                ],
              ),
              image: live?.rjProfile?.avatarUrl != null
                  ? DecorationImage(image: NetworkImage(live!.rjProfile!.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: live?.rjProfile?.avatarUrl == null
                ? (isPlaying
                    ? const Icon(Icons.radio, color: Colors.white, size: 24)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.85, end: 1.15, duration: 600.ms)
                    : const Icon(Icons.radio, color: Colors.white, size: 24))
                : null,
          ),
          const SizedBox(width: 12),

          // 2. Title, RJ & Streaming Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: live?.isReconnecting == true
                            ? Colors.orange
                            : FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 0.8, end: 1.4),
                          const SizedBox(width: 4),
                          Text(
                            live?.isReconnecting == true ? 'RECONNECTING' : 'LIVE',
                            style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    if (_listenerCount > 0) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.people_outline, size: 10, color: FlutterFlowTheme.of(context).secondaryText),
                      const SizedBox(width: 2),
                      Text(
                        '$_listenerCount',
                        style: TextStyle(
                          fontSize: 9,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  live?.showTitle ?? _selectedStation?.name ?? 'BoiAro On Air Radio',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _playerService.errorMessage ?? (_playerService.isReconnecting ? 'Stream reconnecting...' : (isPlaying ? 'Now Streaming Audio' : 'Stream Paused')),
                  style: TextStyle(
                    fontSize: 11,
                    color: _playerService.errorMessage != null 
                        ? FlutterFlowTheme.of(context).error 
                        : FlutterFlowTheme.of(context).secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Play / Pause Button
          GestureDetector(
            onTap: () {
              if (isPlaying) {
                _playerService.pause();
              } else {
                if (_playerService.currentLiveSession != null) {
                  _playerService.playLive(liveSession: _liveSession, station: _selectedStation);
                } else if (_selectedStation != null) {
                  _playerService.playStation(_selectedStation!);
                } else {
                  _playerService.playLive(liveSession: _liveSession, station: _selectedStation);
                }
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary,
                    FlutterFlowTheme.of(context).primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ),

          // 4. Quality Selector
          if (hasQuality) ...[
            const SizedBox(width: 4),
            PopupMenuButton<StreamQuality>(
              icon: Icon(Icons.high_quality, color: FlutterFlowTheme.of(context).secondaryText, size: 24),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => const [
                PopupMenuItem(value: StreamQuality.high, child: Text('High Quality')),
                PopupMenuItem(value: StreamQuality.medium, child: Text('Medium Quality')),
                PopupMenuItem(value: StreamQuality.low, child: Text('Low Data')),
              ],
              onSelected: (quality) => _playerService.setQuality(quality),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.purpleAccent,
                      backgroundImage: msg.avatarUrl != null ? NetworkImage(msg.avatarUrl!) : null,
                      child: msg.avatarUrl == null
                          ? Text(
                              msg.displayName.isNotEmpty ? msg.displayName[0].toUpperCase() : 'L',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.displayName,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: FlutterFlowTheme.of(context).primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.message,
                              style: TextStyle(fontSize: 14, color: FlutterFlowTheme.of(context).primaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Quick Emoji Reaction Bar
        Container(
          height: 44,
          color: FlutterFlowTheme.of(context).primaryBackground,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['❤️', '🔥', '👏', '😂', '🎉', '🎵', '😍', '👍'].map((emoji) {
              return GestureDetector(
                onTap: () => _sendEmojiReaction(emoji),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Chat Input Field
        Container(
          padding: const EdgeInsets.all(12),
          color: FlutterFlowTheme.of(context).secondaryBackground,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Type a message on air...',
                    hintStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                    counterText: '',
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).primaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send_rounded, color: FlutterFlowTheme.of(context).primary),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongRequestsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request a Song / Shoutout',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: FlutterFlowTheme.of(context).primaryText),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _songRequestController,
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your song request or message for the RJ...',
              hintStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
              filled: true,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _sendSongRequest,
              icon: const Icon(Icons.queue_music, size: 18),
              label: const Text('Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Submitted Requests',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: FlutterFlowTheme.of(context).primaryText),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _mySongRequests.isEmpty
                ? Center(child: Text('No song requests submitted yet.', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)))
                : ListView.builder(
                    itemCount: _mySongRequests.length,
                    itemBuilder: (context, index) {
                      final req = _mySongRequests[index];
                      Color statusColor = Colors.orange;
                      if (req.status == 'played') statusColor = Colors.green;
                      if (req.status == 'rejected') statusColor = Colors.red;

                      return Card(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(req.requestText, style: TextStyle(color: FlutterFlowTheme.of(context).primaryText)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInTab() {
    final status = _myCallStatus;
    final isWebRTCActive = _webrtcService.isCallActive;

    String titleText = 'Call In to Speak Live';
    String subTitleText = 'Request permission to talk live on air with the RJ during this broadcast.';
    Color iconColor = const Color(0xFFFF4757);
    IconData iconData = Icons.phone_in_talk;
    Widget? statusBadge;

    if (isWebRTCActive) {
      titleText = 'YOU ARE LIVE ON AIR WITH THE RJ!';
      subTitleText = 'Your microphone is connected directly to the show using HD WebRTC Audio.';
      iconColor = Colors.greenAccent;
      iconData = Icons.mic;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent),
        ),
        child: const Text('LIVE ON AIR', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else if (status != null) {
      if (status.isRequested) {
        titleText = 'Call-in Request Submitted';
        subTitleText = 'Your request has been sent to the RJ. Please wait for approval.';
        iconColor = Colors.amber;
        iconData = Icons.hourglass_top;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: const Text('REQUESTED (Awaiting RJ)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      } else if (status.isWaiting) {
        titleText = 'Waiting in Host Queue...';
        subTitleText = 'The RJ accepted your call! You will be put on air shortly.';
        iconColor = Colors.cyanAccent;
        iconData = Icons.phone_callback;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent),
          ),
          child: const Text('WAITING IN QUEUE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      } else if (status.isOnAir) {
        titleText = 'Connecting to RJ...';
        subTitleText = 'The RJ accepted your call! Connecting audio stream...';
        iconColor = Colors.greenAccent;
        iconData = Icons.perm_phone_msg;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: const Text('CONNECTING...', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      } else if (status.status == 'rejected' || status.status == 'removed' || status.status == 'ended') {
        titleText = 'Call Request Declined';
        subTitleText = 'The RJ is currently not accepting calls or declined the request.';
        iconColor = Colors.redAccent;
        iconData = Icons.phone_disabled;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent),
          ),
          child: const Text('DECLINED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 64,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          if (statusBadge != null) ...[
            statusBadge,
            const SizedBox(height: 12),
          ],
          Text(
            titleText,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: FlutterFlowTheme.of(context).primaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subTitleText,
            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          if (!isWebRTCActive && (status == null || status.status == 'ended' || status.status == 'rejected' || status.status == 'removed'))
            ElevatedButton.icon(
              onPressed: _requestCallIn,
              icon: const Icon(Icons.phone_forwarded),
              label: const Text('Request to Call On-Air'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

          if (!isWebRTCActive && status != null && (status.isRequested || status.isWaiting || status.isOnAir))
            ElevatedButton.icon(
              onPressed: _endCallIn,
              icon: const Icon(Icons.call_end),
              label: const Text('Cancel Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).error,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

          if (isWebRTCActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _webrtcService.isMuted ? Icons.mic_off : Icons.mic,
                    color: _webrtcService.isMuted
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).primaryText,
                    size: 32,
                  ),
                  onPressed: () => _webrtcService.toggleMicrophone(),
                ),
                const SizedBox(width: 30),
                ElevatedButton.icon(
                  onPressed: _endCallIn,
                  icon: const Icon(Icons.call_end),
                  label: const Text('End Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).error,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }



  Widget _buildAnimatedReaction(FloatingReaction reaction) {
    return Positioned(
      bottom: 100,
      right: 20 + (DateTime.now().millisecondsSinceEpoch % 60).toDouble(),
      child: Text(
        reaction.emoji,
        style: const TextStyle(fontSize: 32),
      )
          .animate()
          .moveY(begin: 0, end: -350, duration: const Duration(milliseconds: 2200), curve: Curves.easeOutCubic)
          .fadeOut(duration: const Duration(milliseconds: 2200)),
    );
  }
}

class FloatingReaction {
  final String id;
  final String emoji;
  FloatingReaction({required this.id, required this.emoji});
}
