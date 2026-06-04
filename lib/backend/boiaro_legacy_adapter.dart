import 'dart:convert';

/// Maps BoiAro mobile-api v2 JSON into the legacy `$.data.*` shapes the
/// FlutterFlow-generated UI was built for (book list cards, detail screens).
class BoiaroLegacyAdapter {
  BoiaroLegacyAdapter._();

  static Map<String, dynamic> legacyDataEnvelope({
    int success = 1,
    String message = 'Success',
    Map<String, dynamic>? extra,
  }) {
    return {
      'data': {
        'success': success,
        'message': message,
        if (extra != null) ...extra,
      },
    };
  }

  static String? v2Error(dynamic jsonBody) {
    if (jsonBody is! Map) return null;
    String? normalize(dynamic raw) {
      final text = raw?.toString().trim();
      if (text == null || text.isEmpty) return null;
      final lower = text.toLowerCase();
      if (lower.contains('email not confirmed') ||
          lower.contains('email not confimed') ||
          lower.contains('not confirmed')) {
        return 'Email not confirmed. Please verify your email from inbox/spam, then log in again.';
      }
      return text;
    }

    final e = normalize(jsonBody['error']);
    if (e != null) {
      return e;
    }
    final msg =
        normalize(jsonBody['message'] ?? jsonBody['msg'] ?? jsonBody['detail']);
    if (msg != null) {
      return msg;
    }
    return null;
  }

  /// Book card / list item: `_id`, `name`, `image` (full URL), `author`, `price`, …
  /// Minimal book row from `GET /homepage` section items.
  static Map<String, dynamic> legacyBookFromHomepageItem(
    Map<String, dynamic> m, {
    String? preferredFormat,
  }) {
    return legacyBookFromV2({
      'id': m['id'],
      'title': m['title'],
      'slug': m['slug'],
      'cover_url': m['cover_url'],
      'rating': m['rating'],
      'total_reads': m['total_reads'],
      'is_free': m['is_free'],
      'author': m['author'] ?? m['authors'],
      'authors': m['authors'] ?? m['author'],
      'category': m['category'] ?? m['categories'],
      'categories': m['categories'] ?? m['category'],
      'publisher': m['publisher'] ?? m['publishers'],
      'publishers': m['publishers'] ?? m['publisher'],
      'formats': m['formats'] ?? const [],
      'type': m['type'] ?? m['bookType'] ?? m['format'] ?? preferredFormat,
      'bookType':
          m['bookType'] ?? m['type'] ?? m['format'] ?? preferredFormat,
      'preferred_format': preferredFormat,
    });
  }

  static Map<String, dynamic> legacyBookFromV2(Map<String, dynamic> b) {
    final authors = b['author'] ?? b['authors'];
    String authorName = '';
    String authorId = '';
    String authorImage = '';
    if (authors is Map) {
      authorName = authors['name']?.toString() ?? '';
      authorId = authors['id']?.toString() ?? '';
      authorImage = authors['avatar_url']?.toString() ?? '';
    }

    final categories = b['category'] ?? b['categories'];
    String catId = '';
    String catName = '';
    if (categories is Map) {
      catId = categories['id']?.toString() ?? '';
      catName = categories['name']?.toString() ?? '';
    }

    final publishers = b['publisher'] ?? b['publishers'];
    String publisherId = '';
    String publisherName = '';
    String publisherImage = '';
    if (publishers is Map) {
      publisherId = publishers['id']?.toString() ?? '';
      publisherName = publishers['name']?.toString() ?? '';
      publisherImage =
          (publishers['logo_url'] ?? publishers['image'])?.toString() ?? '';
    }

    final id = b['id']?.toString() ?? '';
    final cover = b['cover_url']?.toString() ?? '';

    final formats = b['formats'];
    String typeStr = 'ebook';
    double price = 0;
    double? discPct;
    double? discAmt;
    if (formats is List && formats.isNotEmpty) {
      final preferred = b['preferred_format']?.toString().toLowerCase().trim();
      Map<String, dynamic>? pick;
      if (preferred != null && preferred.isNotEmpty) {
        for (final f in formats) {
          if (f is Map &&
              f['format']?.toString().toLowerCase().trim() == preferred) {
            pick = Map<String, dynamic>.from(f);
            break;
          }
        }
      }
      if (pick == null) {
        for (final f in formats) {
          if (f is Map && (f['format']?.toString() == 'ebook')) {
            pick = Map<String, dynamic>.from(f);
            break;
          }
        }
      }
      pick ??= formats.first is Map
          ? Map<String, dynamic>.from(formats.first as Map)
          : null;
      if (pick != null) {
        typeStr = pick['format']?.toString() ?? 'ebook';
        final p = pick['price'];
        price = p is num ? p.toDouble() : double.tryParse('$p') ?? 0;
        final d = pick['discount'];
        if (d is num) discPct = d.toDouble();
        final op = pick['original_price'];
        if (op is num && p is num) {
          discAmt = (op.toDouble() - p.toDouble()).clamp(0, double.infinity);
        }
      }
    }

    final rating = b['rating'];
    double? avg;
    if (rating is num) {
      avg = rating.toDouble();
    } else {
      avg = double.tryParse('$rating');
    }

    final flags = <String>[];
    if (formats is List) {
      for (final f in formats) {
        if (f is Map) {
          final ft = f['format']?.toString();
          if (ft != null && ft.isNotEmpty) flags.add(ft);
        }
      }
    }
    final typeCombined = flags.isNotEmpty ? flags.join(',') : typeStr;

    return {
      '_id': id,
      'name': b['title'] ?? b['name'] ?? '',
      'image': cover,
      'author': {
        '_id': authorId,
        'name': authorName,
        'image': authorImage,
      },
      'category': {
        '_id': catId,
        'name': catName,
      },
      'publisher': {
        '_id': publisherId,
        'name': publisherName,
        'image': publisherImage,
      },
      'price': price,
      'averageRating': avg,
      'discount_percentage': discPct,
      'discount_amount': discAmt,
      'type': typeCombined,
      'bookType': typeCombined,
      'language': b['language'],
      'slug': b['slug'],
      'formats': formats,
      'description': b['description'],
      'is_free': b['is_free'],
    };
  }

  /// Full book detail: same as list plus fields used on detail / reader.
  static Map<String, dynamic> legacyBookDetailFromV2(Map<String, dynamic> b) {
    final m = legacyBookFromV2(b);
    final descBn = (b['description_bn'] ?? '').toString().trim();
    m['description'] =
        descBn.isNotEmpty ? descBn : (b['description'] ?? '').toString();
    m['reviews_count'] = b['reviews_count'];
    m['total_reads'] = b['total_reads'];
    m['tags'] = b['tags'];
    m['coin_price'] = b['coin_price'];
    // accesstype for UI: free / purchase — purchase flow uses separate checks
    if (b['is_free'] == true) {
      m['access_type'] = 'free';
    } else {
      m['access_type'] = 'paid';
    }
    // PDF path: v2 serves via signed URL only; leave empty so UI fetches /content/ebook-url
    m['pdf'] = '';
    m['preview_pdf'] = '';
    m['chapters'] = <dynamic>[];
    return m;
  }

  static Map<String, dynamic> legacyCategoryFromV2(Map<String, dynamic> c) {
    return {
      '_id': c['id']?.toString() ?? '',
      'name': c['name'] ?? '',
      'name_en': c['name_en'],
      'image': '',
      'icon': c['icon'],
      'color': c['color'],
      'slug': c['slug'],
    };
  }

  static Map<String, dynamic> legacyAuthorFromV2(Map<String, dynamic> a) {
    final img = a['avatar_url']?.toString() ?? '';
    return {
      '_id': a['id']?.toString() ?? '',
      'name': a['name'] ?? '',
      'image': img,
      'followed': a['followed'] == true || a['is_following'] == true,
      'followers_count': a['followers_count'] ?? 0,
      'books_count': a['books_count'] ?? 0,
      'description': a['bio'] ?? '',
      'facebook_url': '',
      'instagram_url': '',
      'youtube_url': '',
      'website_url': '',
    };
  }

  static Map<String, dynamic> legacyPublisherFromV2(Map<String, dynamic> p) {
    final logo = p['logo_url']?.toString() ?? '';
    return {
      '_id': p['id']?.toString() ?? '',
      'name': p['name'] ?? '',
      'image': logo,
      'followed': p['followed'] == true || p['is_following'] == true,
      'followers_count': p['followers_count'] ?? 0,
      'books_count': p['books_count'] ?? 0,
      'description': p['description'] ?? '',
      'facebook_url': '',
      'instagram_url': '',
      'youtube_url': '',
      'website_url': '',
    };
  }

  static Map<String, dynamic> legacyNarratorFromV2(Map<String, dynamic> n) {
    final img = n['avatar_url']?.toString() ?? '';
    return {
      '_id': n['id']?.toString() ?? '',
      'name': n['name'] ?? '',
      'image': img,
      'followed': n['followed'] == true || n['is_following'] == true,
      'followers_count': n['followers_count'] ?? 0,
      'books_count': n['books_count'] ?? 0,
      'description': n['bio'] ?? '',
      'facebook_url': '',
      'instagram_url': '',
      'youtube_url': '',
      'website_url': '',
    };
  }

  static Map<String, dynamic> legacyReviewFromV2(Map<String, dynamic> r) {
    final prof = r['profiles'];
    String displayName = '';
    String avatar = '';
    if (prof is Map) {
      displayName = prof['display_name']?.toString() ?? '';
      avatar = prof['avatar_url']?.toString() ?? '';
    }
    return {
      'rating': r['rating'],
      'description': r['comment'] ?? '',
      'date': (r['created_at'] ?? '').toString().split('T').first,
      'userDetails': {
        'name': displayName,
        'image': avatar,
      },
    };
  }

  static Map<String, dynamic> legacyNotificationFromV2(Map<String, dynamic> n) {
    return {
      'id': (n['id'] ?? n['_id'] ?? '').toString(),
      'title': n['title'] ?? '',
      'description': n['message'] ?? '',
      'date': (n['created_at'] ?? '').toString().split('T').first,
    };
  }

  static Map<String, dynamic> legacyBookmarkFromV2(Map<String, dynamic> row) {
    final book = row['book'] ?? row['books'];
    Map<String, dynamic>? bmap;
    if (book is Map) {
      bmap = legacyBookFromV2(Map<String, dynamic>.from(book));
    }
    return {
      'bookDetails': bmap ?? {},
    };
  }

  static Map<String, dynamic> legacyPurchaseFromV2(Map<String, dynamic> row) {
    final book = row['books'];
    Map<String, dynamic>? bmap;
    if (book is Map) {
      bmap = legacyBookFromV2(Map<String, dynamic>.from(book));
    }
    return {
      'bookDetails': bmap ?? {},
      'format': row['format'],
    };
  }

  static String jsonEncodeBody(Map<String, dynamic> m) => json.encode(m,
      toEncodable: (o) => o is DateTime ? o.toIso8601String() : o);

  /// Maps `GET /profile` to legacy `$.data.user` used across profile screens.
  static Map<String, dynamic> legacyUserFromProfile({
    required Map<String, dynamic> account,
    required Map<String, dynamic> profile,
  }) {
    final dn = profile['display_name']?.toString() ?? '';
    final fullName = profile['full_name']?.toString() ?? '';
    final nameForSplit = fullName.trim().isNotEmpty ? fullName : dn;
    final parts = nameForSplit.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final img = profile['avatar_url']?.toString() ?? '';
    return {
      'id': account['id']?.toString() ?? profile['user_id']?.toString() ?? '',
      'firstname': first,
      'lastname': last,
      'username': dn,
      'display_name': dn,
      'full_name': fullName,
      'email': account['email']?.toString() ?? '',
      'phone': profile['phone']?.toString() ?? '',
      'image': img,
      'avatar_url': img,
      'country_code': '',
      'bio': profile['bio']?.toString() ?? '',
      'preferred_language': profile['preferred_language']?.toString() ?? '',
      'referral_code': profile['referral_code']?.toString() ?? '',
      'created_at': profile['created_at']?.toString() ??
          account['created_at']?.toString() ??
          '',
      'profile_id': profile['id']?.toString() ?? '',
      'roles': account['roles'],
      'genre': profile['genre']?.toString() ?? '',
      'specialty': profile['specialty']?.toString() ?? '',
      'experience': profile['experience']?.toString() ?? '',
      'website_url': profile['website_url']?.toString() ?? '',
      'facebook_url': profile['facebook_url']?.toString() ?? '',
      'instagram_url': profile['instagram_url']?.toString() ?? '',
      'youtube_url': profile['youtube_url']?.toString() ?? '',
      'portfolio_url': profile['portfolio_url']?.toString() ?? '',
    };
  }

  /// Parses `avatar_url` from `POST /profile/upload-image` (root, `data`, or nested profile).
  static String avatarUrlFromUploadResponse(dynamic jsonBody) {
    String? norm(String? s) {
      final t = (s ?? '').trim();
      if (t.isEmpty || t == 'null' || t == 'undefined') return null;
      return t;
    }

    String? fromMap(Map<String, dynamic> m) {
      return norm(m['avatar_url']?.toString());
    }

    if (jsonBody is Map) {
      final root = Map<String, dynamic>.from(jsonBody);
      final u = fromMap(root);
      if (u != null) return u;
      final data = root['data'];
      if (data is Map) {
        final du = fromMap(Map<String, dynamic>.from(data));
        if (du != null) return du;
        final prof = data['profile'];
        if (prof is Map) {
          final pu = fromMap(Map<String, dynamic>.from(prof));
          if (pu != null) return pu;
        }
      }
    }
    return '';
  }

  static Map<String, dynamic> legacyUserFromAuthUser(
      Map<String, dynamic> user) {
    final profile = user['profile'];
    final displayName =
        profile is Map ? profile['display_name']?.toString() ?? '' : '';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final image = profile is Map ? profile['avatar_url']?.toString() ?? '' : '';
    final phone = profile is Map ? profile['phone']?.toString() ?? '' : '';
    return {
      'id': user['id']?.toString() ?? '',
      'firstname': first,
      'lastname': last,
      'username': displayName,
      'email': user['email']?.toString() ?? '',
      'phone': phone,
      'image': image,
      'country_code': '',
      'referral_code':
          profile is Map ? profile['referral_code']?.toString() ?? '' : '',
      'profile_id': profile is Map ? profile['id']?.toString() ?? '' : '',
      'roles': user['roles'],
    };
  }

}
