import 'radio_station.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Listener',
      avatarUrl: json['avatar_url']?.toString(),
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SongRequest {
  final String id;
  final String userId;
  final String displayName;
  final String requestText;
  final String status; // "pending", "played", "rejected"
  final DateTime createdAt;

  SongRequest({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.requestText,
    required this.status,
    required this.createdAt,
  });

  factory SongRequest.fromJson(Map<String, dynamic> json) {
    return SongRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Listener',
      requestText: json['request_text']?.toString() ?? json['requestText']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ShowSchedule {
  final String id;
  final String showTitle;
  final String scheduleType; // "recurring" or "one_time"
  final int? dayOfWeek; // 0=Sunday..6=Saturday
  final String? specificDate;
  final String startTime; // "08:00"
  final String endTime; // "09:00"
  final String status; // "active", "cancelled", "rescheduled"
  final String? category;
  final String? coverImageUrl;
  final String rjStageName;
  final String? rjAvatarUrl;
  final RadioStation? station;

  ShowSchedule({
    required this.id,
    required this.showTitle,
    required this.scheduleType,
    this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.category,
    this.coverImageUrl,
    required this.rjStageName,
    this.rjAvatarUrl,
    this.station,
  });

  factory ShowSchedule.fromJson(Map<String, dynamic> json) {
    String stageName = 'RJ';
    if (json['rj_stage_name'] != null) {
      stageName = json['rj_stage_name'].toString();
    } else if (json['rjStageName'] != null) {
      stageName = json['rjStageName'].toString();
    } else if (json['rj'] is Map && json['rj']['stage_name'] != null) {
      stageName = json['rj']['stage_name'].toString();
    }

    return ShowSchedule(
      id: json['id']?.toString() ?? '',
      showTitle: json['show_title']?.toString() ?? json['showTitle']?.toString() ?? json['title']?.toString() ?? '',
      scheduleType: json['schedule_type']?.toString() ?? json['scheduleType']?.toString() ?? 'recurring',
      dayOfWeek: json['day_of_week'] is int ? json['day_of_week'] : int.tryParse(json['day_of_week']?.toString() ?? json['dayOfWeek']?.toString() ?? ''),
      specificDate: json['specific_date']?.toString() ?? json['specificDate']?.toString(),
      startTime: json['start_time']?.toString() ?? json['startTime']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? json['endTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      category: json['category']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString() ?? json['coverImageUrl']?.toString(),
      rjStageName: stageName,
      rjAvatarUrl: json['rj_avatar_url']?.toString() ?? json['rjAvatarUrl']?.toString(),
      station: json['station'] is Map ? RadioStation.fromJson(Map<String, dynamic>.from(json['station'])) : null,
    );
  }
}

class CatchupRecording {
  final String id;
  final String showTitle;
  final String recordingUrl;
  final DateTime startedAt;
  final RadioStation? station;
  final String rjStageName;
  final String? rjAvatarUrl;

  CatchupRecording({
    required this.id,
    required this.showTitle,
    required this.recordingUrl,
    required this.startedAt,
    this.station,
    required this.rjStageName,
    this.rjAvatarUrl,
  });

  factory CatchupRecording.fromJson(Map<String, dynamic> json) {
    return CatchupRecording(
      id: json['id']?.toString() ?? '',
      showTitle: json['show_title']?.toString() ?? 'Catchup Episode',
      recordingUrl: json['recording_url']?.toString() ?? '',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ?? DateTime.now(),
      station: json['station'] != null ? RadioStation.fromJson(json['station']) : null,
      rjStageName: json['rj_stage_name']?.toString() ?? 'RJ',
      rjAvatarUrl: json['rj_avatar_url']?.toString(),
    );
  }
}

class CatchupProgress {
  final int positionSeconds;
  final int durationSeconds;
  final bool completed;
  final int totalPlays;
  final DateTime? lastPlayedAt;

  CatchupProgress({
    required this.positionSeconds,
    required this.durationSeconds,
    required this.completed,
    required this.totalPlays,
    this.lastPlayedAt,
  });

  factory CatchupProgress.fromJson(Map<String, dynamic> json) {
    return CatchupProgress(
      positionSeconds: json['position_seconds'] ?? 0,
      durationSeconds: json['duration_seconds'] ?? 0,
      completed: json['completed'] ?? false,
      totalPlays: json['total_plays'] ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.tryParse(json['last_played_at'].toString())
          : null,
    );
  }
}

class CallInRequest {
  final String callId;
  final String status; // requested, waiting, on_air, muted, ended, rejected, removed
  final String? hostUserId;
  final String? displayName;
  final String? avatarUrl;

  CallInRequest({
    required this.callId,
    required this.status,
    this.hostUserId,
    this.displayName,
    this.avatarUrl,
  });

  factory CallInRequest.fromJson(Map<String, dynamic> json) {
    return CallInRequest(
      callId: json['callId']?.toString() ?? json['id']?.toString() ?? json['call_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'requested',
      hostUserId: json['hostUserId']?.toString() ?? json['host_user_id']?.toString(),
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
    );
  }

  bool get isOnAir => status == 'on_air' || status == 'on-air';
  bool get isWaiting => status == 'waiting';
  bool get isRequested => status == 'requested';
}

class IceServerConfig {
  final List<String> urls;
  final String? username;
  final String? credential;

  IceServerConfig({
    required this.urls,
    this.username,
    this.credential,
  });

  factory IceServerConfig.fromJson(Map<String, dynamic> json) {
    var rawUrls = json['urls'];
    List<String> parsedUrls = [];
    if (rawUrls is List) {
      parsedUrls = rawUrls.map((e) => e.toString()).toList();
    } else if (rawUrls is String) {
      parsedUrls = [rawUrls];
    }
    return IceServerConfig(
      urls: parsedUrls,
      username: json['username']?.toString(),
      credential: json['credential']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'urls': urls};
    if (username != null) map['username'] = username;
    if (credential != null) map['credential'] = credential;
    return map;
  }
}

class FloatingReaction {
  final String id;
  final String emoji;
  FloatingReaction({required this.id, required this.emoji});
}
