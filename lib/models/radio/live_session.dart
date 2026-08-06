import 'radio_station.dart';
import 'rj_profile.dart';

class LiveSession {
  final String id;
  final String rjUserId;
  final String showTitle;
  final String streamUrl;
  final String status; // "live" or "reconnecting"
  final DateTime startedAt;
  final String? category;
  final bool chatEnabled;
  final bool requestsEnabled;
  final bool callinEnabled;
  final bool recordingEnabled;
  final bool isTest;
  final RadioStation? station;
  final RJProfile? rjProfile;
  final int listenerCount;

  LiveSession({
    required this.id,
    required this.rjUserId,
    required this.showTitle,
    required this.streamUrl,
    required this.status,
    required this.startedAt,
    this.category,
    this.chatEnabled = true,
    this.requestsEnabled = true,
    this.callinEnabled = false,
    this.recordingEnabled = true,
    this.isTest = false,
    this.station,
    this.rjProfile,
    this.listenerCount = 0,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id']?.toString() ?? '',
      rjUserId: json['rj_user_id']?.toString() ?? '',
      showTitle: json['show_title']?.toString() ?? 'Live Show',
      streamUrl: json['stream_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'live',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ?? DateTime.now(),
      category: json['category']?.toString(),
      chatEnabled: json['chat_enabled'] ?? true,
      requestsEnabled: json['requests_enabled'] ?? true,
      callinEnabled: json['callin_enabled'] ?? false,
      recordingEnabled: json['recording_enabled'] ?? true,
      isTest: json['is_test'] ?? false,
      station: json['station'] != null ? RadioStation.fromJson(json['station']) : null,
      rjProfile: json['rj_profile'] != null ? RJProfile.fromJson(json['rj_profile']) : null,
      listenerCount: json['listener_count'] ?? 0,
    );
  }

  bool get isReconnecting => status == 'reconnecting';
  bool get isLive => status == 'live';

  LiveSession copyWith({
    String? status,
    int? listenerCount,
    bool? chatEnabled,
    bool? requestsEnabled,
    bool? callinEnabled,
  }) {
    return LiveSession(
      id: id,
      rjUserId: rjUserId,
      showTitle: showTitle,
      streamUrl: streamUrl,
      status: status ?? this.status,
      startedAt: startedAt,
      category: category,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      requestsEnabled: requestsEnabled ?? this.requestsEnabled,
      callinEnabled: callinEnabled ?? this.callinEnabled,
      recordingEnabled: recordingEnabled,
      isTest: isTest,
      station: station,
      rjProfile: rjProfile,
      listenerCount: listenerCount ?? this.listenerCount,
    );
  }
}
