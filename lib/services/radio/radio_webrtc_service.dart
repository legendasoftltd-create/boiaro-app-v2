import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'radio_api_service.dart';
import 'radio_socket_service.dart';

class RadioWebRTCService extends ChangeNotifier {
  static final RadioWebRTCService _instance = RadioWebRTCService._internal();
  factory RadioWebRTCService() => _instance;
  RadioWebRTCService._internal() {
    _subscribeToSocketEvents();
  }

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _targetUserId;
  bool _isCallActive = false;
  bool _isMuted = false;

  bool get isCallActive => _isCallActive;
  bool get isMuted => _isMuted;
  MediaStream? get remoteStream => _remoteStream;

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _candidateSub;
  StreamSubscription? _hangupSub;
  StreamSubscription? _muteSub;

  void _subscribeToSocketEvents() {
    final socket = RadioSocketService();

    _offerSub = socket.onCallInOffer.listen((data) async {
      final senderId = data['fromUserId']?.toString() ?? data['targetUserId']?.toString();
      final payload = data['payload'];
      if (payload != null && senderId != null) {
        await handleOffer(senderId, payload);
      }
    });

    _answerSub = socket.onCallInAnswer.listen((data) async {
      final payload = data['payload'];
      if (payload != null) {
        await handleAnswer(payload);
      }
    });

    _candidateSub = socket.onCallInIceCandidate.listen((data) async {
      final payload = data['payload'];
      if (payload != null) {
        await handleIceCandidate(payload);
      }
    });

    _muteSub = socket.onCallInMute.listen((callId) {
      toggleMicrophone(muted: true);
    });

    _hangupSub = socket.onCallInHangup.listen((data) {
      endCall();
    });
  }

  Future<void> initializeCall(String targetUserId, {bool isCaller = true}) async {
    print('[RadioWebRTCService] initializeCall started: targetUserId=$targetUserId, isCaller=$isCaller');
    _targetUserId = targetUserId;
    
    try {
      final iceConfigs = await RadioApiService().getIceServers();
      print('[RadioWebRTCService] Fetched ICE servers from API');

      List<Map<String, dynamic>> iceServers = iceConfigs.map((e) => e.toMap()).toList();
      if (iceServers.isEmpty) {
        print('[RadioWebRTCService] ICE servers list is empty, using fallback Google STUN server');
        iceServers = [
          {'urls': 'stun:stun.l.google.com:19302'}
        ];
      }
      print('[RadioWebRTCService] Configured ICE servers: $iceServers');

      final configuration = <String, dynamic>{
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      };

      print('[RadioWebRTCService] Creating peer connection...');
      _peerConnection = await createPeerConnection(configuration);
      print('[RadioWebRTCService] Peer connection created successfully');

      _peerConnection?.onIceCandidate = (candidate) {
        if (candidate.candidate != null && _targetUserId != null) {
          print('[RadioWebRTCService] Generated local ICE candidate: ${candidate.candidate}. Sending to RJ: $_targetUserId');
          RadioSocketService().sendCallInIceCandidate(_targetUserId!, candidate.toMap());
        }
      };

      _peerConnection?.onIceConnectionState = (state) {
        print('[RadioWebRTCService] ICE Connection State changed: ${state.toString()}');
      };

      _peerConnection?.onConnectionState = (state) {
        print('[RadioWebRTCService] Peer Connection State changed: ${state.toString()}');
      };

      _peerConnection?.onSignalingState = (state) {
        print('[RadioWebRTCService] Signaling State changed: ${state.toString()}');
      };

      _peerConnection?.onTrack = (event) {
        print('[RadioWebRTCService] onTrack received: kind=${event.track.kind}');
        if (event.track.kind == 'audio') {
          _remoteStream = event.streams.isNotEmpty ? event.streams[0] : null;
          print('[RadioWebRTCService] Remote audio track set: $_remoteStream');
          notifyListeners();
        }
      };
    } catch (e) {
      print('[RadioWebRTCService] Error creating peer connection: $e');
      return;
    }

    // Get microphone
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false,
      };
      print('[RadioWebRTCService] Requesting microphone access (getUserMedia)...');
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      print('[RadioWebRTCService] getUserMedia success. Adding tracks to peer connection...');
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });
      print('[RadioWebRTCService] Added local audio tracks to peer connection');
    } catch (e) {
      print('[RadioWebRTCService] getUserMedia error / microphone permission denied: $e');
    }

    _isCallActive = true;
    _isMuted = false;
    notifyListeners();

    if (isCaller) {
      print('[RadioWebRTCService] Caller mode: Creating WebRTC offer...');
      await createAndSendOffer();
    } else {
      print('[RadioWebRTCService] Callee mode: Awaiting remote offer...');
    }
  }

  Future<void> createAndSendOffer() async {
    print('[RadioWebRTCService] createAndSendOffer called');
    if (_peerConnection == null) {
      print('[RadioWebRTCService] Cannot create offer: _peerConnection is null');
      return;
    }
    if (_targetUserId == null) {
      print('[RadioWebRTCService] Cannot create offer: _targetUserId is null');
      return;
    }
    try {
      final offer = await _peerConnection!.createOffer({'offerToReceiveAudio': 1});
      print('[RadioWebRTCService] Offer created successfully. Setting local description...');
      await _peerConnection!.setLocalDescription(offer);
      print('[RadioWebRTCService] Local description set. Emitting callin:offer to RJ ($_targetUserId)...');
      RadioSocketService().sendCallInOffer(_targetUserId!, offer.toMap());
    } catch (e) {
      print('[RadioWebRTCService] Error creating/sending offer: $e');
    }
  }

  Future<void> handleOffer(String senderUserId, dynamic payload) async {
    print('[RadioWebRTCService] handleOffer from sender: $senderUserId');
    _targetUserId = senderUserId;
    if (_peerConnection == null) {
      print('[RadioWebRTCService] Peer connection is null during offer, initializing callee call...');
      await initializeCall(senderUserId, isCaller: false);
    }
    try {
      final description = RTCSessionDescription(payload['sdp'], payload['type']);
      print('[RadioWebRTCService] Setting remote description from offer...');
      await _peerConnection!.setRemoteDescription(description);
      print('[RadioWebRTCService] Creating WebRTC answer...');
      final answer = await _peerConnection!.createAnswer({'offerToReceiveAudio': 1});
      print('[RadioWebRTCService] Setting local description from answer...');
      await _peerConnection!.setLocalDescription(answer);
      print('[RadioWebRTCService] Local description set. Emitting callin:answer to sender ($senderUserId)...');
      RadioSocketService().sendCallInAnswer(_targetUserId!, answer.toMap());
    } catch (e) {
      print('[RadioWebRTCService] Error handling offer: $e');
    }
  }

  Future<void> handleAnswer(dynamic payload) async {
    print('[RadioWebRTCService] handleAnswer received: payload=$payload');
    if (_peerConnection == null) {
      print('[RadioWebRTCService] Cannot handle answer: _peerConnection is null');
      return;
    }
    try {
      final description = RTCSessionDescription(payload['sdp'], payload['type']);
      print('[RadioWebRTCService] Setting remote description from answer...');
      await _peerConnection!.setRemoteDescription(description);
      print('[RadioWebRTCService] Remote description set from answer successfully');
    } catch (e) {
      print('[RadioWebRTCService] Error handling answer: $e');
    }
  }

  Future<void> handleIceCandidate(dynamic payload) async {
    print('[RadioWebRTCService] handleIceCandidate received: payload=$payload');
    if (_peerConnection == null) {
      print('[RadioWebRTCService] Cannot handle ICE candidate: _peerConnection is null');
      return;
    }
    try {
      final candidate = RTCIceCandidate(
        payload['candidate'],
        payload['sdpMid'],
        payload['sdpMLineIndex'],
      );
      print('[RadioWebRTCService] Adding candidate to peer connection: $candidate');
      await _peerConnection!.addCandidate(candidate);
      print('[RadioWebRTCService] ICE candidate added successfully');
    } catch (e) {
      print('[RadioWebRTCService] Error adding ICE candidate: $e');
    }
  }

  void toggleMicrophone({bool? muted}) {
    _isMuted = muted ?? !_isMuted;
    print('[RadioWebRTCService] toggleMicrophone: _isMuted=$_isMuted');
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
    notifyListeners();
  }

  Future<void> endCall() async {
    print('[RadioWebRTCService] endCall triggered');
    if (_targetUserId != null && _isCallActive) {
      print('[RadioWebRTCService] Sending hangup socket event to target RJ: $_targetUserId');
      RadioSocketService().sendCallInHangup(_targetUserId!);
    }
    _localStream?.getTracks().forEach((track) {
      print('[RadioWebRTCService] Stopping local track: ${track.kind}');
      track.stop();
    });
    await _localStream?.dispose();
    await _peerConnection?.close();
    print('[RadioWebRTCService] Disposed streams and closed peer connection');
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _targetUserId = null;
    _isCallActive = false;
    _isMuted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _offerSub?.cancel();
    _answerSub?.cancel();
    _candidateSub?.cancel();
    _hangupSub?.cancel();
    _muteSub?.cancel();
    endCall();
    super.dispose();
  }
}
