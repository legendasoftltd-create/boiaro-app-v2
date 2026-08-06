import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/radio/live_session.dart';
import '../../models/radio/radio_station.dart';
import '../../models/radio/radio_chat.dart';
import '../../services/radio/radio_api_service.dart';
import '../../services/radio/radio_socket_service.dart';
import '../../services/radio/radio_webrtc_service.dart';

class RJDashboardPage extends StatefulWidget {
  static const String routeName = 'RJDashboardPage';
  static const String routePath = '/rjDashboardPage';

  const RJDashboardPage({Key? key}) : super(key: key);

  @override
  State<RJDashboardPage> createState() => _RJDashboardPageState();
}

class _RJDashboardPageState extends State<RJDashboardPage> with SingleTickerProviderStateMixin {
  final RadioApiService _apiService = RadioApiService();
  final RadioSocketService _socketService = RadioSocketService();
  final RadioWebRTCService _webrtcService = RadioWebRTCService();

  LiveSession? _myLiveSession;
  Map<String, dynamic>? _tokenInfo;
  Map<String, dynamic>? _termsInfo;
  List<RadioStation> _stations = [];
  bool _isLoading = true;

  // Broadcast Token
  String? _newlyGeneratedToken;

  // Form Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _streamUrlController = TextEditingController();
  final TextEditingController _tokenInputController = TextEditingController();
  RadioStation? _selectedStation;
  bool _isTestMode = false;
  bool _chatEnabled = true;
  bool _requestsEnabled = true;
  bool _recordingEnabled = true;
  bool _callinEnabled = false;

  // Heartbeat Timer
  Timer? _heartbeatTimer;

  // Live Management Data
  List<ChatMessage> _liveChat = [];
  List<SongRequest> _songRequests = [];
  List<CallInRequest> _callInQueue = [];
  List<FloatingReaction> _floatingReactions = [];

  // Socket Subscriptions
  StreamSubscription? _reactionSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _songRequestSub;
  StreamSubscription? _callInStatusSub;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _webrtcService.addListener(_onWebRTCStateChanged);
    _loadDashboardData();
  }

  void _onWebRTCStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final tokenInfo = await _apiService.getBroadcastTokenInfo();
    final termsInfo = await _apiService.getTermsStatus();
    final stations = await _apiService.getStations();
    final session = await _apiService.getMyLiveSession();

    _tokenInfo = tokenInfo;
    _termsInfo = termsInfo;
    _stations = stations;
    _myLiveSession = session;

    if (_stations.isNotEmpty) {
      _selectedStation = _stations.first;
    }

    if (_myLiveSession != null) {
      _startHeartbeatTimer(_myLiveSession!.id);
      _fetchLiveManagementData(_myLiveSession!.id);
      _initRJRealtime(_myLiveSession!.id);
    }

    setState(() => _isLoading = false);
  }

  void _initRJRealtime(String sessionId) {
    print('[RJDashboardPage] Connecting socket for RJ session: $sessionId');
    _socketService.connectAndJoin(sessionId);

    _reactionSub?.cancel();
    _reactionSub = _socketService.onReactionNew.listen((data) {
      print('[RJDashboardPage] Received reaction:new: $data');
      final emoji = data['emoji']?.toString() ?? '❤️';
      _triggerFloatingEmoji(emoji);
    });

    _chatSub?.cancel();
    _chatSub = _socketService.onChatNew.listen((msg) {
      print('[RJDashboardPage] Received chat:new');
      if (mounted) {
        setState(() {
          _liveChat.add(msg);
        });
      }
    });

    _songRequestSub?.cancel();
    _songRequestSub = _socketService.onSongRequestNew.listen((req) {
      print('[RJDashboardPage] Received song_request:new');
      if (mounted) {
        setState(() {
          _songRequests.insert(0, req);
        });
      }
    });

    _callInStatusSub?.cancel();
    _callInStatusSub = _socketService.onCallInStatus.listen((callStatus) {
      print('[RJDashboardPage] Received callin:status: $callStatus');
      if (_myLiveSession != null) {
        _fetchLiveManagementData(_myLiveSession!.id);
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

  void _startHeartbeatTimer(String sessionId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final ok = await _apiService.sendHeartbeat(sessionId);
      if (!ok && mounted) {
        debugPrint('Heartbeat failed!');
      }
    });
  }

  Future<void> _fetchLiveManagementData(String sessionId) async {
    final chat = await _apiService.getChatHistory(sessionId);
    final requests = await _apiService.getSongRequests(sessionId);
    final queue = await _apiService.getCallInQueue(sessionId);

    if (mounted) {
      setState(() {
        _liveChat = chat;
        _songRequests = requests;
        _callInQueue = queue;
      });
    }
  }

  void _generateBroadcastToken() async {
    final newToken = await _apiService.regenerateBroadcastToken();
    if (newToken != null && mounted) {
      setState(() {
        _newlyGeneratedToken = newToken;
        _tokenInputController.text = newToken;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Your Broadcast Token'),
          content: SelectableText(
            'Token: $newToken\n\nSave this immediately! It will NEVER be displayed again.',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('I Have Saved It')),
          ],
        ),
      );
    }
  }

  void _acceptTerms() async {
    final ok = await _apiService.acceptTerms();
    if (ok) {
      _loadDashboardData();
    }
  }

  void _startBroadcasting() async {
    if (_termsInfo?['needs_acceptance'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Broadcaster Terms first.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final streamUrl = _streamUrlController.text.trim();
    final token = _tokenInputController.text.trim();

    if (title.isEmpty || streamUrl.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title, Stream URL, and Broadcast Token.')),
      );
      return;
    }

    final res = await _apiService.startLiveSession(
      streamUrl: streamUrl,
      showTitle: title,
      broadcastToken: token,
      stationId: _selectedStation?.id,
      isTest: _isTestMode,
      chatEnabled: _chatEnabled,
      requestsEnabled: _requestsEnabled,
      recordingEnabled: _recordingEnabled,
      callinEnabled: _callinEnabled,
    );

    if (res['success'] == true && res['session'] != null) {
      setState(() {
        _myLiveSession = res['session'];
      });
      _startHeartbeatTimer(_myLiveSession!.id);
      _fetchLiveManagementData(_myLiveSession!.id);
      _initRJRealtime(_myLiveSession!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BROADCAST STARTED SUCCESSFULLY!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${res['error']}')),
      );
    }
  }

  void _endBroadcasting() async {
    if (_myLiveSession == null) return;
    final ok = await _apiService.endLiveSession(_myLiveSession!.id);
    if (ok) {
      _heartbeatTimer?.cancel();
      setState(() {
        _myLiveSession = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast Session Ended.')),
      );
    }
  }

  void _showEncoderGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('External Encoder Setup Guide', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              '1. Install BUTT (Broadcast Using This Tool) or Mixxx on your PC/Laptop.\n'
              '2. Obtain Icecast mount credentials (host, port, mount point, password) from admin.\n'
              '3. Configure BUTT -> Audio -> Microphone source.\n'
              '4. Press START in BUTT to send audio to Icecast.\n'
              '5. Press "START BROADCAST" below to link your show to BoiAro On Air!',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reactionSub?.cancel();
    _chatSub?.cancel();
    _songRequestSub?.cancel();
    _callInStatusSub?.cancel();
    _tabController.dispose();
    _titleController.dispose();
    _streamUrlController.dispose();
    _tokenInputController.dispose();
    _webrtcService.removeListener(_onWebRTCStateChanged);
    _webrtcService.endCall();
    super.dispose();
  }

  Widget _buildAnimatedReaction(FloatingReaction reaction) {
    return Positioned(
      bottom: 80,
      right: 30 + (DateTime.now().millisecondsSinceEpoch % 80).toDouble(),
      child: Text(
        reaction.emoji,
        style: const TextStyle(fontSize: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: Text(
          'RJ Studio Dashboard',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.amber),
            onPressed: _showEncoderGuide,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4757)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Terms banner if needed
                      if (_termsInfo?['needs_acceptance'] == true) _buildTermsCard(),

                      // Live or Go Live Setup
                      if (_myLiveSession != null) ...[
                        _buildActiveBroadcastCard(),
                        if (_webrtcService.isCallActive) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF22C55E), width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_in_talk, color: Color(0xFF22C55E)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LISTENER ON-AIR LIVE CALL ACTIVE',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const Text(
                                        'Your microphone is connected to the caller.',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _webrtcService.isMuted ? Icons.mic_off : Icons.mic,
                                    color: _webrtcService.isMuted ? Colors.red : Colors.white,
                                  ),
                                  onPressed: () => _webrtcService.toggleMicrophone(),
                                  tooltip: 'Mute/Unmute Mic',
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final onAirCall = _callInQueue.firstWhere(
                                        (c) => c.status == 'on_air' || c.status == 'on-air',
                                      );
                                      print('[RJDashboardPage] RJ hanging up call: ${onAirCall.callId}');
                                      await _apiService.updateCallInStatus(onAirCall.callId, 'remove');
                                    } catch (_) {}
                                    await _webrtcService.endCall();
                                    if (_myLiveSession != null) {
                                      _fetchLiveManagementData(_myLiveSession!.id);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Hangup', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TabBar(
                          controller: _tabController,
                          indicatorColor: const Color(0xFFFF4757),
                          tabs: const [
                            Tab(text: 'Live Moderation'),
                            Tab(text: 'Song Requests'),
                            Tab(text: 'Call-in Queue'),
                          ],
                        ),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildModerationTab(),
                              _buildSongRequestsQueueTab(),
                              _buildCallInQueueTab(),
                            ],
                          ),
                        ),
                      ] else ...[
                        _buildGoLiveSetupCard(),
                      ],
                    ],
                  ),
                ),

                // Floating Reactions Animation Overlay for RJ
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _floatingReactions.map((r) => _buildAnimatedReaction(r)).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTermsCard() {
    return Card(
      color: Colors.amber.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.amber)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.gavel, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Broadcaster Terms Acceptance Required before going live.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: _acceptTerms,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Accept Terms', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoLiveSetupCard() {
    return Card(
      color: const Color(0xFF1E1E36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Go Live Configuration', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                OutlinedButton.icon(
                  onPressed: _generateBroadcastToken,
                  icon: const Icon(Icons.key, size: 16),
                  label: Text(_tokenInfo?['has_token'] == true ? 'Regen Token' : 'Gen Token'),
                ),
              ],
            ),
            if (_newlyGeneratedToken != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Newly generated token active.',
                  style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Show Title',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2B2B4A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _streamUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Icecast Public Stream URL (https://...)',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2B2B4A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenInputController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Broadcast Token',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2B2B4A),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Test Broadcast Mode (Private)', style: TextStyle(color: Colors.white)),
              value: _isTestMode,
              activeTrackColor: const Color(0xFFFF4757),
              onChanged: (val) => setState(() => _isTestMode = val),
            ),
            SwitchListTile(
              title: const Text('Enable Live Chat', style: TextStyle(color: Colors.white)),
              value: _chatEnabled,
              activeTrackColor: const Color(0xFFFF4757),
              onChanged: (val) => setState(() => _chatEnabled = val),
            ),
            SwitchListTile(
              title: const Text('Enable Song Requests', style: TextStyle(color: Colors.white)),
              value: _requestsEnabled,
              activeTrackColor: const Color(0xFFFF4757),
              onChanged: (val) => setState(() => _requestsEnabled = val),
            ),
            SwitchListTile(
              title: const Text('Enable Listener WebRTC Call-In', style: TextStyle(color: Colors.white)),
              value: _callinEnabled,
              activeTrackColor: const Color(0xFFFF4757),
              onChanged: (val) => setState(() => _callinEnabled = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startBroadcasting,
                icon: const Icon(Icons.sensors),
                label: const Text('START BROADCAST NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4757),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBroadcastCard() {
    return Card(
      color: const Color(0xFF1E1E36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4757)),
              child: const Icon(Icons.podcasts, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_myLiveSession!.showTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text('Status: ${_myLiveSession!.status.toUpperCase()}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Listeners: ${_myLiveSession!.listenerCount}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _endBroadcasting,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Show'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _liveChat.length,
      itemBuilder: (context, index) {
        final msg = _liveChat[index];
        return ListTile(
          title: Text(msg.displayName, style: const TextStyle(color: Color(0xFFFF6B81), fontWeight: FontWeight.bold)),
          subtitle: Text(msg.message, style: const TextStyle(color: Colors.white)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (action) async {
              if (action == 'delete') {
                await _apiService.deleteChatMessage(_myLiveSession!.id, msg.id);
                _fetchLiveManagementData(_myLiveSession!.id);
              } else if (action == 'mute') {
                await _apiService.muteOrBanUser(_myLiveSession!.id, userId: msg.userId, type: 'mute');
              } else if (action == 'ban') {
                await _apiService.muteOrBanUser(_myLiveSession!.id, userId: msg.userId, type: 'ban');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete Message')),
              PopupMenuItem(value: 'mute', child: Text('Mute Listener')),
              PopupMenuItem(value: 'ban', child: Text('Ban & Disconnect')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongRequestsQueueTab() {
    if (_songRequests.isEmpty) {
      return const Center(
        child: Text('No song requests yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _songRequests.length,
      itemBuilder: (context, index) {
        final req = _songRequests[index];
        final isPending = req.status == 'pending';
        final isPlayed = req.status == 'played';
        final isRejected = req.status == 'rejected';

        Color badgeColor = Colors.orange;
        String badgeText = 'Pending';
        if (isPlayed) {
          badgeColor = Colors.green;
          badgeText = 'Played';
        } else if (isRejected) {
          badgeColor = Colors.redAccent;
          badgeText = 'Rejected';
        }

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    req.displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor, width: 1),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(req.requestText, style: const TextStyle(color: Colors.white70)),
            ),
            trailing: isPending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Mark as Played',
                        onPressed: () async {
                          print('[RJDashboardPage] Accepting song request: reqId=${req.id}');
                          if (_myLiveSession == null) return;
                          final success = await _apiService.updateSongRequestStatus(_myLiveSession!.id, req.id, 'played');
                          _socketService.updateSongRequestStatus(req.id, 'played');
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update song request status'), backgroundColor: Colors.redAccent),
                            );
                          }
                          _fetchLiveManagementData(_myLiveSession!.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        tooltip: 'Reject Request',
                        onPressed: () async {
                          print('[RJDashboardPage] Rejecting song request: reqId=${req.id}');
                          if (_myLiveSession == null) return;
                          final success = await _apiService.updateSongRequestStatus(_myLiveSession!.id, req.id, 'rejected');
                          _socketService.updateSongRequestStatus(req.id, 'rejected');
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update song request status'), backgroundColor: Colors.redAccent),
                            );
                          }
                          _fetchLiveManagementData(_myLiveSession!.id);
                        },
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCallInQueueTab() {
    if (_callInQueue.isEmpty) {
      return const Center(
        child: Text('No active call-in requests', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _callInQueue.length,
      itemBuilder: (context, index) {
        final call = _callInQueue[index];
        final title = (call.displayName != null && call.displayName!.isNotEmpty)
            ? call.displayName!
            : 'Call Request #${call.callId.substring(0, call.callId.length > 8 ? 8 : call.callId.length)}';

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF4757),
              backgroundImage: (call.avatarUrl != null && call.avatarUrl!.isNotEmpty)
                  ? NetworkImage(call.avatarUrl!)
                  : null,
              child: (call.avatarUrl == null || call.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${call.status.toUpperCase()}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ElevatedButton(
                  onPressed: (call.status == 'on_air' || call.status == 'on-air')
                      ? null
                      : () async {
                          print('[RJDashboardPage] Putting call on-air: callId=${call.callId}');
                          await _apiService.updateCallInStatus(call.callId, 'on-air');
                          if (_myLiveSession != null) {
                            _fetchLiveManagementData(_myLiveSession!.id);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (call.status == 'on_air' || call.status == 'on-air') ? Colors.grey : Colors.green,
                  ),
                  child: Text((call.status == 'on_air' || call.status == 'on-air') ? 'Live On-Air' : 'Put On Air'),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.redAccent),
                  onPressed: () async {
                    print('[RJDashboardPage] Removing call: callId=${call.callId}');
                    await _apiService.updateCallInStatus(call.callId, 'remove');
                    if (_myLiveSession != null) {
                      _fetchLiveManagementData(_myLiveSession!.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
