import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../app_constants.dart';
import '../../app_state.dart';
import '../../models/radio/radio_chat.dart';

class RadioSocketService {
  static final RadioSocketService _instance = RadioSocketService._internal();
  factory RadioSocketService() => _instance;
  RadioSocketService._internal();

  IO.Socket? _socket;
  String? _currentSessionId;

  // Event Stream Controllers
  final _listenerCountController = StreamController<int>.broadcast();
  final _chatNewController = StreamController<ChatMessage>.broadcast();
  final _chatDeletedController = StreamController<String>.broadcast();
  final _reactionNewController = StreamController<Map<String, dynamic>>.broadcast();
  final _songRequestNewController = StreamController<SongRequest>.broadcast();
  final _songRequestUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectingController = StreamController<String>.broadcast();
  final _sessionEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Call-in Signaling Controllers
  final _callinStatusController = StreamController<CallInRequest>.broadcast();
  final _callinOfferController = StreamController<Map<String, dynamic>>.broadcast();
  final _callinAnswerController = StreamController<Map<String, dynamic>>.broadcast();
  final _callinIceCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  final _callinMuteController = StreamController<String>.broadcast();
  final _callinHangupController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams for UI consumption
  Stream<int> get onListenerCount => _listenerCountController.stream;
  Stream<ChatMessage> get onChatNew => _chatNewController.stream;
  Stream<String> get onChatDeleted => _chatDeletedController.stream;
  Stream<Map<String, dynamic>> get onReactionNew => _reactionNewController.stream;
  Stream<SongRequest> get onSongRequestNew => _songRequestNewController.stream;
  Stream<Map<String, dynamic>> get onSongRequestUpdated => _songRequestUpdatedController.stream;
  Stream<String> get onSessionReconnecting => _reconnectingController.stream;
  Stream<Map<String, dynamic>> get onSessionEnded => _sessionEndedController.stream;
  Stream<String> get onError => _errorController.stream;

  Stream<CallInRequest> get onCallInStatus => _callinStatusController.stream;
  Stream<Map<String, dynamic>> get onCallInOffer => _callinOfferController.stream;
  Stream<Map<String, dynamic>> get onCallInAnswer => _callinAnswerController.stream;
  Stream<Map<String, dynamic>> get onCallInIceCandidate => _callinIceCandidateController.stream;
  Stream<String> get onCallInMute => _callinMuteController.stream;
  Stream<Map<String, dynamic>> get onCallInHangup => _callinHangupController.stream;

  bool get isConnected => _socket != null && _socket!.connected;

  void connectAndJoin(String sessionId) {
    _currentSessionId = sessionId;
    final token = FFAppState().token;
    print('[RadioSocketService] connectAndJoin called for sessionId: $sessionId, token length: ${token.length}');
    if (token.isEmpty) {
      print('[RadioSocketService] ERROR: Cannot connect socket without access token (token is empty)');
      return;
    }

    if (_socket != null) {
      print('[RadioSocketService] Disposing previous socket instance');
      _socket?.disconnect();
      _socket?.dispose();
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    final host = FFAppConstants.webUrl;
    print('[RadioSocketService] Connecting socket to host: $host with path: /socket.io');

    _socket = IO.io(
      host,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket?.onConnect((_) {
      print('[RadioSocketService] Socket connected successfully (id: ${_socket?.id})');
      print('[RadioSocketService] Emitting join_session with sessionId: $sessionId, platform: $platform');
      _socket?.emit('join_session', {
        'sessionId': sessionId,
        'platform': platform,
      });
    });

    _socket?.onDisconnect((reason) {
      print('[RadioSocketService] Socket disconnected, reason: $reason');
    });

    _socket?.onConnectError((err) {
      print('[RadioSocketService] Socket connect error: $err');
    });

    _socket?.onError((err) {
      print('[RadioSocketService] Socket error event: $err');
    });

    // Listeners
    _socket?.on('listener_count', (data) {
      if (data is Map && data['count'] != null) {
        _listenerCountController.add((data['count'] as num).toInt());
      }
    });

    _socket?.on('chat:new', (data) {
      print('[RadioSocketService] Received chat:new event: $data');
      if (data is Map<String, dynamic>) {
        _chatNewController.add(ChatMessage.fromJson(data));
      } else if (data is Map) {
        _chatNewController.add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket?.on('chat:deleted', (data) {
      print('[RadioSocketService] Received chat:deleted event: $data');
      if (data is Map && data['messageId'] != null) {
        _chatDeletedController.add(data['messageId'].toString());
      }
    });

    _socket?.on('reaction:new', (data) {
      print('[RadioSocketService] Received reaction:new event: $data');
      if (data is Map) {
        _reactionNewController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('song_request:new', (data) {
      if (data is Map) {
        _songRequestNewController.add(SongRequest.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket?.on('song_request:updated', (data) {
      if (data is Map) {
        _songRequestUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('session:reconnecting', (data) {
      if (data is Map && data['sessionId'] != null) {
        _reconnectingController.add(data['sessionId'].toString());
      }
    });

    _socket?.on('session:ended', (data) {
      if (data is Map) {
        _sessionEndedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('error', (data) {
      print('[RadioSocketService] Received server error event: $data');
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message'].toString());
      } else if (data is String) {
        _errorController.add(data);
      }
    });

    // WebRTC Signaling Listeners
    _socket?.on('callin:status', (data) {
      print('[RadioSocketService] Received callin:status event: $data');
      if (data is Map) {
        _callinStatusController.add(CallInRequest.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    _socket?.on('callin:offer', (data) {
      if (data is Map) {
        _callinOfferController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('callin:answer', (data) {
      if (data is Map) {
        _callinAnswerController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('callin:ice-candidate', (data) {
      if (data is Map) {
        _callinIceCandidateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('callin:mute', (data) {
      if (data is Map && data['callId'] != null) {
        _callinMuteController.add(data['callId'].toString());
      }
    });

    _socket?.on('callin:hangup', (data) {
      if (data is Map) {
        _callinHangupController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendChat(String message) {
    print('[RadioSocketService] sendChat called with message: "$message"');
    if (_socket == null) {
      print('[RadioSocketService] ERROR: Cannot send chat because _socket is NULL');
      return;
    }
    if (!(_socket!.connected)) {
      print('[RadioSocketService] WARNING: Socket is NOT connected (connected=false)');
    }
    if (_currentSessionId == null) {
      print('[RadioSocketService] ERROR: Cannot send chat because _currentSessionId is NULL');
      return;
    }
    print('[RadioSocketService] Emitting chat:send for sessionId: $_currentSessionId');
    _socket?.emit('chat:send', {
      'sessionId': _currentSessionId,
      'message': message,
    });
  }

  void sendReaction(String emoji) {
    print('[RadioSocketService] sendReaction called with emoji: "$emoji"');
    if (_socket == null) {
      print('[RadioSocketService] ERROR: Cannot send reaction because _socket is NULL');
      return;
    }
    if (!(_socket!.connected)) {
      print('[RadioSocketService] WARNING: Socket is NOT connected (connected=false)');
    }
    if (_currentSessionId == null) {
      print('[RadioSocketService] ERROR: Cannot send reaction because _currentSessionId is NULL');
      return;
    }
    print('[RadioSocketService] Emitting reaction:send for sessionId: $_currentSessionId');
    _socket?.emit('reaction:send', {
      'sessionId': _currentSessionId,
      'emoji': emoji,
    });
  }

  void sendSongRequest(String requestText) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('song_request:send', {
        'sessionId': _currentSessionId,
        'requestText': requestText,
      });
    }
  }

  void deleteMessage(String messageId) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('moderation:delete_message', {
        'sessionId': _currentSessionId,
        'messageId': messageId,
      });
    }
  }

  void updateSongRequestStatus(String requestId, String status) {
    print('[RadioSocketService] updateSongRequestStatus: requestId=$requestId, status=$status');
    if (_socket == null) {
      print('[RadioSocketService] ERROR: _socket is NULL in updateSongRequestStatus');
      return;
    }
    if (!(_socket!.connected)) {
      print('[RadioSocketService] WARNING: Socket is NOT connected (connected=false) in updateSongRequestStatus');
    }
    if (_currentSessionId == null) {
      print('[RadioSocketService] ERROR: _currentSessionId is NULL in updateSongRequestStatus');
      return;
    }
    print('[RadioSocketService] Emitting song_request:update_status for sessionId: $_currentSessionId');
    _socket?.emit('song_request:update_status', {
      'sessionId': _currentSessionId,
      'requestId': requestId,
      'status': status,
    });
  }

  // WebRTC Signaling Emitters
  void sendCallInOffer(String targetUserId, dynamic payload) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('callin:offer', {
        'sessionId': _currentSessionId,
        'targetUserId': targetUserId,
        'payload': payload,
      });
    }
  }

  void sendCallInAnswer(String targetUserId, dynamic payload) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('callin:answer', {
        'sessionId': _currentSessionId,
        'targetUserId': targetUserId,
        'payload': payload,
      });
    }
  }

  void sendCallInIceCandidate(String targetUserId, dynamic payload) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('callin:ice-candidate', {
        'sessionId': _currentSessionId,
        'targetUserId': targetUserId,
        'payload': payload,
      });
    }
  }

  void sendCallInHangup(String targetUserId) {
    if (_socket != null && _currentSessionId != null) {
      _socket?.emit('callin:hangup', {
        'sessionId': _currentSessionId,
        'targetUserId': targetUserId,
      });
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket?.emit('leave_session');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
    _currentSessionId = null;
  }
}
