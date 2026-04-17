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
  // v2 documentation currently does not define follow/unfollow endpoints
  // for authors/narrators/publishers.
  static const bool supportsFollowEndpoints = false;

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
    final urls = <String>[
      '$base/$plural/$id/follow/status',
      '$base/$plural/$id/is-following',
      '$base/$plural/$id',
      '$base/$singular/$id/follow/status',
      '$base/$singular/$id/is-following',
      '$base/$singular/$id',
      '$base/follows/check?entity_type=$singular&entity_id=$id',
      '$base/follows/check?type=$singular&id=$id',
    ];
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
    final followUrls = <String>[
      '$base/$plural/$id/follow',
      '$base/$plural/follow',
      '$base/$plural/$id',
      '$base/$singular/$id/follow',
      '$base/$singular/follow',
      '$base/$singular/$id',
      '$base/follows',
    ];
    final unfollowUrls = <String>[
      '$base/$plural/$id/unfollow',
      '$base/$plural/$id/follow',
      '$base/$plural/unfollow',
      '$base/$plural/follow',
      '$base/$plural/$id',
      '$base/$singular/$id/follow',
      '$base/$singular/$id/unfollow',
      '$base/$singular/unfollow',
      '$base/$singular/follow',
      '$base/$singular/$id',
      '$base/follows',
    ];
    final urls = follow ? followUrls : unfollowUrls;

    List<Map<String, dynamic>> payloadsFor(bool targetFollow) => <Map<String, dynamic>>[
          {'entity_type': singular, 'entity_id': id, 'follow': targetFollow},
          {'entity_type': singular, 'entity_id': id, 'action': targetFollow ? 'follow' : 'unfollow'},
          {'type': singular, 'id': id, 'follow': targetFollow},
          {'type': singular, 'id': id, 'action': targetFollow ? 'follow' : 'unfollow'},
          {'${singular}_id': id, 'follow': targetFollow},
          {'${singular}_id': id, 'action': targetFollow ? 'follow' : 'unfollow'},
          {'id': id, 'follow': targetFollow},
          {'id': id, 'action': targetFollow ? 'follow' : 'unfollow'},
        ];

    for (final u in urls) {
      try {
        final uri = Uri.parse(u);
        final payloads = payloadsFor(follow);

        // Try POST variants first (most common in edge-function APIs).
        for (final payload in payloads) {
          final postRes =
              await http.post(uri, headers: headers, body: jsonEncode(payload));
          if (postRes.statusCode == 200 ||
              postRes.statusCode == 201 ||
              postRes.statusCode == 204) {
            return true;
          }
        }

        // Try method-specific fallback for unfollow.
        if (!follow) {
          for (final payload in payloadsFor(false)) {
            final delRes =
                await http.delete(uri, headers: headers, body: jsonEncode(payload));
            if (delRes.statusCode == 200 ||
                delRes.statusCode == 201 ||
                delRes.statusCode == 204) {
              return true;
            }
          }
        }
      } catch (_) {}
    }
    return false;
  }
}
