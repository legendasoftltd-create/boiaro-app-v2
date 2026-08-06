import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app_constants.dart';
import '../../app_state.dart';
import '../../models/radio/radio_station.dart';
import '../../models/radio/live_session.dart';
import '../../models/radio/rj_profile.dart';
import '../../models/radio/radio_chat.dart';

class RadioApiService {
  static final RadioApiService _instance = RadioApiService._internal();
  factory RadioApiService() => _instance;
  RadioApiService._internal();

  String get _baseUrl => FFAppConstants.mobileApiBaseUrl;

  Map<String, String> _getHeaders({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = FFAppState().token;
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- 1. Streaming ---

  Future<List<RadioStation>> getStations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/stations'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['stations'] as List? ?? [];
        return list.map((e) => RadioStation.fromJson(e)).toList();
      }
    } catch (e) {
      print('RadioApiService.getStations error: $e');
    }
    return [];
  }

  Future<LiveSession?> getLiveSession() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/live'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['live'] != null) {
          return LiveSession.fromJson(data['live']);
        }
      }
    } catch (e) {
      print('RadioApiService.getLiveSession error: $e');
    }
    return null;
  }

  Future<List<ShowSchedule>> getSchedules() async {
    final urlsToTry = [
      '${FFAppConstants.webUrl}/api/trpc/rj.showSchedules',
      '${FFAppConstants.webUrl}/trpc/rj.showSchedules',
      '$_baseUrl/radio/schedules',
      '$_baseUrl/rj/showSchedules',
    ];

    for (final url in urlsToTry) {
      try {
        print('[RadioApiService] getSchedules trying URL: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: _getHeaders(auth: true),
        );
        print('[RadioApiService] getSchedules status=${response.statusCode} for $url');
        if (response.statusCode == 200) {
          print('[RadioApiService] getSchedules response body: ${response.body}');
          final dynamic decoded = jsonDecode(response.body);
          List rawList = [];

          if (decoded is List) {
            if (decoded.isNotEmpty && decoded[0] is Map && decoded[0]['result'] != null) {
              final data = decoded[0]['result']['data'];
              if (data is List) rawList = data;
            } else {
              rawList = decoded;
            }
          } else if (decoded is Map<String, dynamic>) {
            if (decoded['result'] != null && decoded['result']['data'] != null) {
              final data = decoded['result']['data'];
              if (data is List) rawList = data;
            } else if (decoded['schedules'] != null && decoded['schedules'] is List) {
              rawList = decoded['schedules'];
            } else if (decoded['schedule'] != null && decoded['schedule'] is List) {
              rawList = decoded['schedule'];
            } else if (decoded['data'] != null && decoded['data'] is List) {
              rawList = decoded['data'];
            }
          }

          if (rawList.isNotEmpty) {
            return rawList.map((e) => ShowSchedule.fromJson(Map<String, dynamic>.from(e))).toList();
          }
        }
      } catch (e) {
        print('[RadioApiService] getSchedules error for $url: $e');
      }
    }
    return [];
  }

  // --- 3. Chat & Song Requests REST ---

  Future<List<ChatMessage>> getChatHistory(String sessionId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/live/$sessionId/chat?limit=$limit'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['messages'] as List? ?? []);
        return list.map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      print('RadioApiService.getChatHistory error: $e');
    }
    return [];
  }

  Future<bool> deleteChatMessage(String sessionId, String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/radio/live/$sessionId/chat/$messageId'),
        headers: _getHeaders(auth: true),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('RadioApiService.deleteChatMessage error: $e');
      return false;
    }
  }

  Future<bool> sendSongRequest(String sessionId, String requestText) async {
    try {
      print('[RadioApiService] sendSongRequest: sessionId=$sessionId, text="$requestText"');
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/live/$sessionId/song-request'),
        headers: _getHeaders(auth: true),
        body: jsonEncode({'request_text': requestText}),
      );
      print('[RadioApiService] sendSongRequest status=${response.statusCode}, body=${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[RadioApiService] sendSongRequest error: $e');
      return false;
    }
  }

  Future<List<SongRequest>> getSongRequests(String sessionId) async {
    try {
      print('[RadioApiService] getSongRequests: sessionId=$sessionId');
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/live/$sessionId/song-requests'),
        headers: _getHeaders(auth: true),
      );
      print('[RadioApiService] getSongRequests status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['requests'] as List? ?? []);
        return list.map((e) => SongRequest.fromJson(e)).toList();
      }
    } catch (e) {
      print('[RadioApiService] getSongRequests error: $e');
    }
    return [];
  }

  Future<bool> updateSongRequestStatus(String sessionId, String requestId, String status) async {
    try {
      final url = '$_baseUrl/radio/live/$sessionId/song-requests/$requestId';
      print('[RadioApiService] updateSongRequestStatus: URL=$url, status=$status');
      final response = await http.patch(
        Uri.parse(url),
        headers: _getHeaders(auth: true),
        body: jsonEncode({'status': status}),
      );
      print('[RadioApiService] updateSongRequestStatus status=${response.statusCode}, body=${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('[RadioApiService] updateSongRequestStatus error: $e');
      return false;
    }
  }

  Future<int> getListenerCount(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/live/$sessionId/listener-count'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
    } catch (e) {
      print('RadioApiService.getListenerCount error: $e');
    }
    return 0;
  }

  // --- 5. Catch-up / Podcast Archive ---

  Future<Map<String, dynamic>> getCatchupRecordings({int limit = 20, String? cursor}) async {
    try {
      var url = '$_baseUrl/radio/catchup?limit=$limit';
      if (cursor != null && cursor.isNotEmpty) {
        url += '&cursor=$cursor';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['sessions'] as List? ?? [];
        final items = rawList.map((e) => CatchupRecording.fromJson(e)).toList();
        return {
          'sessions': items,
          'next_cursor': data['next_cursor']?.toString(),
        };
      }
    } catch (e) {
      print('RadioApiService.getCatchupRecordings error: $e');
    }
    return {'sessions': <CatchupRecording>[], 'next_cursor': null};
  }

  Future<CatchupProgress?> getCatchupProgress(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/catchup/$sessionId/progress'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['progress'] != null) {
          return CatchupProgress.fromJson(data['progress']);
        }
      }
    } catch (e) {
      print('RadioApiService.getCatchupProgress error: $e');
    }
    return null;
  }

  Future<void> recordCatchupPlay(String sessionId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/radio/catchup/$sessionId/play'),
        headers: _getHeaders(auth: true),
      );
    } catch (e) {
      print('RadioApiService.recordCatchupPlay error: $e');
    }
  }

  Future<void> saveCatchupProgress(String sessionId, {required int positionSeconds, int? durationSeconds}) async {
    try {
      final body = <String, dynamic>{'position_seconds': positionSeconds};
      if (durationSeconds != null) {
        body['duration_seconds'] = durationSeconds;
      }
      await http.post(
        Uri.parse('$_baseUrl/radio/catchup/$sessionId/progress'),
        headers: _getHeaders(auth: true),
        body: jsonEncode(body),
      );
    } catch (e) {
      print('RadioApiService.saveCatchupProgress error: $e');
    }
  }

  Future<List<CatchupRecording>> getCatchupHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/catchup/history'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['history'] as List? ?? []);
        return list.map((e) => CatchupRecording.fromJson(e)).toList();
      }
    } catch (e) {
      print('RadioApiService.getCatchupHistory error: $e');
    }
    return [];
  }

  // --- 6. RJ Profiles ---

  Future<List<RJProfile>> getRJProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/rj/profiles'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['profiles'] as List? ?? []);
        return list.map((e) => RJProfile.fromJson(e)).toList();
      }
    } catch (e) {
      print('RadioApiService.getRJProfiles error: $e');
    }
    return [];
  }

  // --- 7. Moderation & Reports ---

  Future<bool> reportContent(String sessionId, {required String targetType, required String targetId, required String reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/live/$sessionId/report'),
        headers: _getHeaders(auth: true),
        body: jsonEncode({
          'target_type': targetType,
          'target_id': targetId,
          'reason': reason,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('RadioApiService.reportContent error: $e');
      return false;
    }
  }

  Future<bool> muteOrBanUser(String sessionId, {required String userId, String? reason, int? durationMinutes, String type = 'mute'}) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'type': type,
      };
      if (reason != null) body['reason'] = reason;
      if (durationMinutes != null) body['duration_minutes'] = durationMinutes;

      final response = await http.post(
        Uri.parse('$_baseUrl/radio/live/$sessionId/mute'),
        headers: _getHeaders(auth: true),
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('RadioApiService.muteOrBanUser error: $e');
      return false;
    }
  }

  Future<bool> unmuteUser(String sessionId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/radio/live/$sessionId/mute/$userId'),
        headers: _getHeaders(auth: true),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('RadioApiService.unmuteUser error: $e');
      return false;
    }
  }

  // --- 8. RJ / Going Live Lifecycle ---

  Future<Map<String, dynamic>> getBroadcastTokenInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/rj/broadcast-token'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('RadioApiService.getBroadcastTokenInfo error: $e');
    }
    return {'has_token': false};
  }

  Future<String?> regenerateBroadcastToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/rj/broadcast-token/regenerate'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token']?.toString();
      }
    } catch (e) {
      print('RadioApiService.regenerateBroadcastToken error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> getTermsStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/rj/terms'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('RadioApiService.getTermsStatus error: $e');
    }
    return {'needs_acceptance': true};
  }

  Future<bool> acceptTerms() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/rj/terms/accept'),
        headers: _getHeaders(auth: true),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('RadioApiService.acceptTerms error: $e');
      return false;
    }
  }

  Future<LiveSession?> getMyLiveSession() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/rj/live/my-session'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['session'] != null) {
          return LiveSession.fromJson(data['session']);
        }
      }
    } catch (e) {
      print('RadioApiService.getMyLiveSession error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> startLiveSession({
    required String streamUrl,
    required String showTitle,
    required String broadcastToken,
    String? stationId,
    String? category,
    bool isTest = false,
    bool chatEnabled = true,
    bool requestsEnabled = true,
    bool recordingEnabled = true,
    bool callinEnabled = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'stream_url': streamUrl,
        'show_title': showTitle,
        'broadcast_token': broadcastToken,
        'is_test': isTest,
        'chat_enabled': chatEnabled,
        'requests_enabled': requestsEnabled,
        'recording_enabled': recordingEnabled,
        'callin_enabled': callinEnabled,
      };
      if (stationId != null) body['station_id'] = stationId;
      if (category != null) body['category'] = category;

      final response = await http.post(
        Uri.parse('$_baseUrl/radio/rj/live/start'),
        headers: _getHeaders(auth: true),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'session': LiveSession.fromJson(data['session'] ?? data)};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to start session'};
      }
    } catch (e) {
      print('RadioApiService.startLiveSession error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> endLiveSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/rj/live/$sessionId/end'),
        headers: _getHeaders(auth: true),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('RadioApiService.endLiveSession error: $e');
      return false;
    }
  }

  Future<bool> sendHeartbeat(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/radio/rj/live/$sessionId/heartbeat'),
        headers: _getHeaders(auth: true),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('RadioApiService.sendHeartbeat error: $e');
      return false;
    }
  }

  // --- 9. Listener Call-in REST ---

  Future<List<IceServerConfig>> getIceServers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/radio/callin/ice-servers'),
        headers: _getHeaders(auth: true),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['ice_servers'] as List? ?? [];
        return list.map((e) => IceServerConfig.fromJson(e)).toList();
      }
    } catch (e) {
      print('RadioApiService.getIceServers error: $e');
    }
    return [
      IceServerConfig(urls: ['stun:stun.l.google.com:19302'])
    ];
  }

  Future<CallInRequest?> requestCallIn(String sessionId) async {
    try {
      final url = '$_baseUrl/radio/live/$sessionId/callin/request';
      print('[RadioApiService] requestCallIn calling: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(auth: true),
        body: jsonEncode({'consent_given': true}),
      );
      print('[RadioApiService] requestCallIn status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null) {
          final callMap = (data['call'] as Map<String, dynamic>?) ?? (data is Map<String, dynamic> ? data : null);
          if (callMap != null) {
            return CallInRequest.fromJson(callMap);
          }
        }
      }
    } catch (e) {
      print('[RadioApiService] requestCallIn error: $e');
    }
    return null;
  }

  Future<CallInRequest?> getMyCallInStatus(String sessionId) async {
    try {
      final url = '$_baseUrl/radio/live/$sessionId/callin/my-status';
      print('[RadioApiService] getMyCallInStatus calling: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(auth: true),
      );
      print('[RadioApiService] getMyCallInStatus status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          final callMap = (data['call'] as Map<String, dynamic>?) ?? (data is Map<String, dynamic> ? data : null);
          if (callMap != null && (callMap['status'] != null || callMap['id'] != null)) {
            return CallInRequest.fromJson(callMap);
          }
        }
      }
    } catch (e) {
      print('[RadioApiService] getMyCallInStatus error: $e');
    }
    return null;
  }

  Future<List<CallInRequest>> getCallInQueue(String sessionId) async {
    try {
      final url = '$_baseUrl/radio/live/$sessionId/callin/queue';
      print('[RadioApiService] getCallInQueue calling: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(auth: true),
      );
      print('[RadioApiService] getCallInQueue status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List
            ? data
            : (data['calls'] as List? ?? data['queue'] as List? ?? data['requests'] as List? ?? []);
        return list.map((e) => CallInRequest.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      print('[RadioApiService] getCallInQueue error: $e');
    }
    return [];
  }

  Future<bool> updateCallInStatus(String callId, String action) async {
    // action: "accept", "reject", "on-air", "mute", "remove", "end"
    try {
      final url = '$_baseUrl/radio/callin/$callId/$action';
      print('[RadioApiService] updateCallInStatus ($action) calling: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(auth: true),
      );
      print('[RadioApiService] updateCallInStatus ($action) status=${response.statusCode}, body=${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('[RadioApiService] updateCallInStatus ($action) error: $e');
      return false;
    }
  }
}
