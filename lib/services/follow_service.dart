import '/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowState {
  const FollowState({
    required this.isFollowing,
    this.followersCount,
  });

  final bool isFollowing;
  final int? followersCount;
}

class FollowService {
  static const bool supportsFollowEndpoints = true;

  static Map<String, String> _headers({required String token}) => {
        'apikey': FFAppConstants.supabaseAnonApiKey,
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static bool _readIsFollowing(Map<String, dynamic> body) {
    final raw = body['is_following'] ??
        body['following'] ??
        body['isFollowing'] ??
        body['followed'];
    if (raw is bool) return raw;
    final txt = (raw ?? '').toString().toLowerCase();
    return txt == 'true' || txt == '1' || txt == 'yes';
  }

  static int? _readFollowersCount(Map<String, dynamic> body) {
    final raw = body['followers_count'] ??
        body['follower_count'] ??
        body['followers'] ??
        body['count'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static Future<FollowState?> fetchState({
    required String entityType,
    required String entityId,
    required String token,
  }) async {
    if (!supportsFollowEndpoints) return null;
    final base = FFAppConstants.mobileApiBaseUrl;
    final type = entityType.toLowerCase().trim();
    final singular = type.endsWith('s') ? type.substring(0, type.length - 1) : type;
    final plural = singular.endsWith('s') ? singular : '${singular}s';
    final id = entityId.trim();
    if (id.isEmpty) return null;
    final headers = _headers(token: token);
    final urls = <String>['$base/$plural/$id', '$base/$singular/$id'];
    for (final u in urls) {
      try {
        final res = await http.get(Uri.parse(u), headers: headers);
        if (res.statusCode != 200) continue;
        final decoded = jsonDecode(res.body);
        if (decoded is! Map) continue;
        final body = Map<String, dynamic>.from(decoded);
        return FollowState(
          isFollowing: _readIsFollowing(body),
          followersCount: _readFollowersCount(body),
        );
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> setFollow({
    required String entityType,
    required String entityId,
    required String token,
    required bool follow,
  }) async {
    if (!supportsFollowEndpoints) return false;
    final base = FFAppConstants.mobileApiBaseUrl;
    final type = entityType.toLowerCase().trim();
    final singular = type.endsWith('s') ? type.substring(0, type.length - 1) : type;
    final plural = singular.endsWith('s') ? singular : '${singular}s';
    final id = entityId.trim();
    if (id.isEmpty) return false;
    final headers = _headers(token: token);
    final action = follow ? 'follow' : 'unfollow';
    final uri = Uri.parse('$base/$plural/$id/$action');
    try {
      final res = await http.post(uri, headers: headers);
      return res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
