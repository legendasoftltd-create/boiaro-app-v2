import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import '/pages/cart_pages/checkout_page_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/dialogs/book_review_bottom_sheet/book_review_bottom_sheet_widget.dart';
import '/providers/cart_provider.dart';
import 'audiobook_details_page_model.dart';
export 'audiobook_details_page_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/custom_code/ad_manager.dart';
import '/custom_code/widgets/ad_reward_dialog.dart';

class AudiobookDetailsPageWidget extends StatefulWidget {
  const AudiobookDetailsPageWidget({
    super.key,
    required this.audiobook,
  });

  final Map<String, dynamic> audiobook;

  static String routeName = 'AudiobookDetailsPage';
  static String routePath = '/audiobookDetailsPage';

  @override
  State<AudiobookDetailsPageWidget> createState() =>
      _AudiobookDetailsPageWidgetState();
}

class _AudiobookDetailsPageWidgetState extends State<AudiobookDetailsPageWidget>
    with TickerProviderStateMixin {
  late AudiobookDetailsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late String _bookId;
  late Future<ApiCallResponse> _detailsFuture;
  late Future<ApiCallResponse> _relatedFuture;
  Future<ApiCallResponse>? _authorBooksFuture;
  Future<ApiCallResponse>? _reviewsFuture;
  bool _isPurchased = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  List<String> _purchasedBookIds = [];
  List<Map<String, dynamic>> _v2Tracks = [];
  bool _v2TracksLoading = false;
  bool _hasAudioAccess = false;
  String? _tracksLoadedForBookId;

  final animationsMap = {
    'containerOnPageLoadAnimation1': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effectsBuilder: () => [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
        MoveEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: Offset(0.0, 30.0),
          end: Offset(0.0, 0.0),
        ),
      ],
    ),
    'rowOnPageLoadAnimation': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effectsBuilder: () => [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 200.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
        MoveEffect(
          curve: Curves.easeInOut,
          delay: 200.ms,
          duration: 600.ms,
          begin: Offset(0.0, 20.0),
          end: Offset(0.0, 0.0),
        ),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudiobookDetailsPageModel());
    _bookId = _extractBookId(widget.audiobook);
    _detailsFuture = EbookGroup.getbookdetailsApiCall.call(
      bookId: _bookId,
      type: 'audiobook',
    );
    _relatedFuture = EbookGroup.getRelatedBooksApiCall.call(
      bookId: _bookId,
      type: 'audiobook',
    );
    _reviewsFuture = EbookGroup.getreviewApiCall.call(
      bookId: _bookId,
      token: FFAppState().token,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadV2Tracks();
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
        await _loadFavoriteStatus();
        await _refreshAudioAccess();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _extractBookId(Map<String, dynamic> audiobook) {
    final id = audiobook['id'] ??
        audiobook['_id'] ??
        getJsonField(audiobook, r'''$.id''') ??
        getJsonField(audiobook, r'''$._id''');
    if (id != null && id.toString().trim().isNotEmpty) {
      return id.toString();
    }
    // Route payload sometimes nests original object under `raw`.
    final rawId = getJsonField(audiobook, r'''$.raw.id''') ??
        getJsonField(audiobook, r'''$.raw._id''');
    return rawId?.toString() ?? '';
  }

  String _extractBookIdFromDetails(dynamic details) {
    final id = getJsonField(details, r'''$._id''') ??
        getJsonField(details, r'''$.id''') ??
        getJsonField(details, r'''$.book_id''');
    return id?.toString().trim() ?? '';
  }

  Map<String, String> _apiHeaders({required bool authRequired}) {
    final h = <String, String>{
      'apikey': FFAppConstants.supabaseAnonApiKey,
      'Content-Type': 'application/json',
    };
    if (authRequired && FFAppState().token.trim().isNotEmpty) {
      h['Authorization'] = 'Bearer ${FFAppState().token}';
    }
    return h;
  }

  Future<Map<String, dynamic>?> _postV2(
    String path, {
    required Map<String, dynamic> body,
    required bool authRequired,
  }) async {
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/$path');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: authRequired),
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> _loadV2Tracks() async {
    if (_v2TracksLoading || _bookId.isEmpty) return;
    if (_tracksLoadedForBookId == _bookId && _v2Tracks.isNotEmpty) return;
    setState(() => _v2TracksLoading = true);
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$_bookId/tracks');
      final res = await http.get(
        uri,
        headers: _apiHeaders(authRequired: false),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['tracks'] is List) {
          _v2Tracks = (decoded['tracks'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _tracksLoadedForBookId = _bookId;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _v2TracksLoading = false);
  }

  Future<void> _refreshAudioAccess() async {
    if (!FFAppState().isLogin || _bookId.isEmpty) return;
    final body = await _postV2(
      'access/check',
      body: {'book_id': _bookId, 'format': 'audiobook'},
      authRequired: true,
    );
    _hasAudioAccess = body?['has_access'] == true;
    if (mounted) setState(() {});
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _audiobookCoinPrice(dynamic details, Map<String, dynamic> fallback) {
    int pickFrom(dynamic rawFormats) {
      if (rawFormats is! List) return 0;
      for (final row in rawFormats) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        if ((m['format']?.toString().toLowerCase() ?? '') == 'audiobook') {
          final coin = _toInt(m['coin_price']);
          if (coin > 0) return coin;
        }
      }
      return 0;
    }

    final fromDetails = pickFrom(getJsonField(details, r'''$.formats'''));
    if (fromDetails > 0) return fromDetails;
    final fromFallback = pickFrom(fallback['formats']);
    if (fromFallback > 0) return fromFallback;
    return _toInt(getJsonField(details, r'''$.coin_price'''));
  }

  Future<int?> _walletBalance() async {
    if (!FFAppState().isLogin) return null;
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/wallet');
      final res = await http.get(
        uri,
        headers: _apiHeaders(authRequired: true),
      );
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final balance = decoded['balance'];
      if (balance is num) return balance.toInt();
      return int.tryParse(balance?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _unlockWithCoins(int coinCost) async {
    final body = await _postV2(
      'wallet/unlock',
      body: {'book_id': _bookId, 'format': 'audiobook', 'coin_cost': coinCost},
      authRequired: true,
    );
    if (body == null) {
      await actions.showCustomToastBottom('Wallet unlock failed');
      return false;
    }
    final err = body['error']?.toString();
    if (err != null && err.trim().isNotEmpty) {
      await actions.showCustomToastBottom(err);
      return false;
    }
    await actions.showCustomToastBottom(
      body['message']?.toString() ?? 'Unlocked successfully',
    );
    return true;
  }

  Future<bool> _confirmAndUnlockWithCoins({
    required String title,
    required int coinCost,
  }) async {
    final balance = await _walletBalance();
    if (!mounted) return false;
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unlock with Coins'),
            content: Text(
              balance == null
                  ? 'Unlock "$title" for $coinCost coins?'
                  : 'Unlock "$title" for $coinCost coins?\nYour balance: $balance',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Unlock'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return false;
    return _unlockWithCoins(coinCost);
  }

  Future<String?> _audioSignedUrl(int trackNumber) async {
    final body = await _postV2(
      'content/audio-url',
      body: {'book_id': _bookId, 'track_number': trackNumber},
      authRequired: false,
    );
    final url = body?['signed_url']?.toString();
    if (url != null && url.trim().isNotEmpty) return url;
    return null;
  }

  Future<List<Map<String, dynamic>>> _buildPlayableChapters({
    required bool hasAccess,
  }) async {
    if (_v2Tracks.isEmpty) {
      await _loadV2Tracks();
    }
    if (_v2Tracks.isEmpty) {
      final fallbackUrl = await _audioSignedUrl(1);
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return <Map<String, dynamic>>[
          {
            'title': 'Episode 1',
            'duration': '--:--',
            'track_number': 1,
            'isLocked': false,
            'isPreview': true,
            'file': fallbackUrl,
            'raw': <String, dynamic>{},
          }
        ];
      }
    }
    final out = <Map<String, dynamic>>[];
    final previewTrackCount =
        _v2Tracks.where((t) => t['is_preview'] == true).length;
    final previewPercent = _v2Tracks.isEmpty
        ? 15
        : ((previewTrackCount / _v2Tracks.length) * 100).round().clamp(1, 100);
    for (var i = 0; i < _v2Tracks.length; i++) {
      final t = _v2Tracks[i];
      final trackNumber = (t['track_number'] is num)
          ? (t['track_number'] as num).toInt()
          : i + 1;
      final isPreview = t['is_preview'] == true;
      if (!hasAccess && !isPreview) continue;
      final signed = await _audioSignedUrl(trackNumber);
      if (signed == null || signed.isEmpty) continue;
      out.add({
        'title': t['title']?.toString() ?? 'Chapter $trackNumber',
        'duration': t['duration']?.toString() ?? '--:--',
        'track_number': trackNumber,
        'isLocked': false,
        'isPreview': isPreview,
        'previewFraction': 1.0,
        'file': signed,
        'raw': t,
      });
    }
    if (!hasAccess && out.isNotEmpty) {
      for (final chapter in out) {
        chapter['previewPercent'] = previewPercent;
      }
    }
    return out;
  }

  Future<void> _openAudioPlayerFromV2({
    required Map<String, dynamic> audiobook,
    required bool hasAccess,
    int? startTrackNumber,
    bool isFree = false,
  }) async {
    final chapters = await _buildPlayableChapters(hasAccess: hasAccess);
    if (chapters.isEmpty) {
      await actions.showCustomToastBottom(
        hasAccess
            ? 'Unable to load audiobook tracks'
            : 'No free preview tracks available',
      );
      return;
    }
    Map<String, dynamic> startChapter = chapters.first;
    if (startTrackNumber != null) {
      final i = chapters.indexWhere(
          (c) => (c['track_number']?.toString() ?? '') == '$startTrackNumber');
      if (i >= 0) startChapter = chapters[i];
    }
    context.pushNamed(
      AudioPlayerPageWidget.routeName,
      extra: <String, dynamic>{
        'audiobook': {
          ...audiobook,
          'chapters': chapters,
          'isPreviewMode': !hasAccess,
          'previewPercent': chapters.isNotEmpty
              ? (chapters.first['previewPercent'] as int?) ?? 15
              : 15,
          'isFree': isFree,
        },
        'chapter': startChapter,
      },
    );
  }

  Future<void> _loadPurchasedBooks() async {
    try {
      final response = await EbookGroup.userBookPurchaseRecordsApiCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      );
      if (EbookGroup.userBookPurchaseRecordsApiCall.success(
            response.jsonBody ?? '',
          ) ==
          1) {
        _purchasedBookIds = EbookGroup.userBookPurchaseRecordsApiCall.bookId(
              response.jsonBody ?? '',
            ) ??
            [];
        _isPurchased = _purchasedBookIds.contains(_bookId);
        if (mounted) {
          safeSetState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading purchased audiobooks: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final response = await EbookGroup.getFavouriteBookCall.call(
        userId: FFAppState().userId,
        token: FFAppState().token,
      );
      _isFavorite = functions.checkFavOrNot(
            EbookGroup.getFavouriteBookCall
                .favouriteBookDetailsList(response.jsonBody)
                ?.toList(),
            _bookId,
          ) ==
          true;
      if (mounted) {
        safeSetState(() {});
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
    if (!FFAppState().isLogin) {
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    safeSetState(() => _isFavoriteLoading = true);
    try {
      if (_isFavorite) {
        final response = await EbookGroup.removeFavouritebookCall.call(
          bookId: _bookId,
          userId: FFAppState().userId,
          token: FFAppState().token,
        );
        if (response.succeeded) {
          _isFavorite = false;
          await actions.showCustomToastBottom(FFAppState().unFavText);
        }
      } else {
        final response = await EbookGroup.addFavouriteBookApiCall.call(
          bookId: _bookId,
          userId: FFAppState().userId,
          token: FFAppState().token,
        );
        if (response.succeeded) {
          _isFavorite = true;
          await actions.showCustomToastBottom(FFAppState().favText);
        }
      }
    } catch (e) {
      debugPrint('Favorite toggle failed: $e');
    } finally {
      if (mounted) {
        safeSetState(() => _isFavoriteLoading = false);
      }
    }
  }

  String _resolveAccessType(dynamic details, Map<String, dynamic> fallback) {
    final access = getJsonField(details, r'''$.access_type''') ??
        getJsonField(details, r'''$.accessType''') ??
        getJsonField(details, r'''$.book_access_type''') ??
        fallback['access_type'] ??
        fallback['accessType'];
    return (access?.toString() ?? '').toLowerCase();
  }

  num? _toNum(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  num? _calculateOfferPrice(
      dynamic price, dynamic discountAmount, dynamic discountPercentage) {
    final priceNum = _toNum(price);
    if (priceNum == null) {
      return null;
    }
    final discountAmountNum = _toNum(discountAmount);
    if (discountAmountNum != null && discountAmountNum > 0) {
      return (priceNum - discountAmountNum).clamp(0, priceNum);
    }
    final discountPercentageNum = _toNum(discountPercentage);
    if (discountPercentageNum != null && discountPercentageNum > 0) {
      return (priceNum - (priceNum * discountPercentageNum / 100))
          .clamp(0, priceNum);
    }
    return null;
  }

  String _resolveBookImage(String? imagePath) {
    final trimmed = (imagePath ?? '').trim();
    if (trimmed.isEmpty) {
      return 'https://picsum.photos/seed/audiobook-detail/800/1200';
    }
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${FFAppConstants.bookImagesUrl}$trimmed';
  }

  String _sanitizeText(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      return '';
    }
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Map<String, dynamic> _normalizeBookDetails(
      dynamic bookDetails, Map<String, dynamic> fallback) {
    final imagePath =
        getJsonField(bookDetails, r'''$.image''') ?? fallback['image'];
    final price =
        getJsonField(bookDetails, r'''$.price''') ?? fallback['price'];
    final discountAmount = getJsonField(bookDetails, r'''$.discount_amount''');
    final discountPercentage =
        getJsonField(bookDetails, r'''$.discount_percentage''');
    final offerPrice =
        _calculateOfferPrice(price, discountAmount, discountPercentage) ??
            fallback['offerPrice'];
    final rating = _toNum(getJsonField(bookDetails, r'''$.averageRating''')) ??
        _toNum(fallback['rating']) ??
        0;
    final previewAudio = getJsonField(bookDetails, r'''$.preview_audio''') ??
        getJsonField(bookDetails, r'''$.previewAudio''') ??
        fallback['preview_audio'] ??
        fallback['previewAudio'];
    final reviewsList = getJsonField(bookDetails, r'''$.reviews''', true);
    return {
      'id': getJsonField(bookDetails, r'''$._id''')?.toString() ??
          fallback['id'] ??
          fallback['_id'] ??
          '',
      'title': getJsonField(bookDetails, r'''$.name''')?.toString() ??
          fallback['title'] ??
          fallback['name'] ??
          'Untitled',
      'author': getJsonField(bookDetails, r'''$.author.name''')?.toString() ??
          fallback['author'] ??
          '',
      'category':
          getJsonField(bookDetails, r'''$.category.name''')?.toString() ??
              fallback['category'] ??
              '',
      'image': _resolveBookImage(imagePath?.toString()),
      'price': _toNum(price) ?? fallback['price'],
      'offerPrice': offerPrice,
      'rating': rating,
      'reviewsCount': (reviewsList is List) ? reviewsList.length : 0,
      'language': getJsonField(bookDetails, r'''$.language''')?.toString() ??
          fallback['language'] ??
          '',
      'description': _sanitizeText(
        getJsonField(bookDetails, r'''$.description''') ??
            fallback['description'],
      ),
      'previewAudio': previewAudio,
      'raw': bookDetails ?? fallback,
    };
  }

  List<Map<String, dynamic>> _normalizeChapters(
    dynamic bookDetails,
    List<dynamic> fallback, {
    required bool hasAccess,
  }) {
    final rawChapters =
        (getJsonField(bookDetails, r'''$.chapters''', true) ?? fallback)
            .toList();
    final List<Map<String, dynamic>> chapters = [];
    for (var i = 0; i < rawChapters.length; i++) {
      final chapter = rawChapters[i];
      final title = getJsonField(chapter, r'''$.title''')?.toString() ??
          getJsonField(chapter, r'''$.name''')?.toString() ??
          'Chapter ${i + 1}';
      final duration = getJsonField(chapter, r'''$.duration''')?.toString() ??
          getJsonField(chapter, r'''$.length''')?.toString() ??
          '--:--';
      final rawLocked = getJsonField(chapter, r'''$.isLocked''') ??
          getJsonField(chapter, r'''$.is_locked''') ??
          false;
      final isLocked = hasAccess ? (rawLocked == true) : true;
      final file = getJsonField(chapter, r'''$.file''') ??
          getJsonField(chapter, r'''$.audio''');
      chapters.add({
        'title': title,
        'duration': duration,
        'isLocked': isLocked == true,
        'file': file,
        'raw': chapter,
      });
    }
    return chapters;
  }

  List<Map<String, dynamic>> _normalizeRelatedBooks(ApiCallResponse? response) {
    if (response == null) {
      return [];
    }
    final rawList = (getJsonField(
              response.jsonBody,
              r'''$.data.bookDetails''',
              true,
            ) ??
            [])
        .toList();
    return rawList.map<Map<String, dynamic>>((book) {
      final image =
          _resolveBookImage(getJsonField(book, r'''$.image''')?.toString());
      return {
        'id': getJsonField(book, r'''$._id''')?.toString() ?? '',
        'title': getJsonField(book, r'''$.name''')?.toString() ?? 'Untitled',
        'author': getJsonField(book, r'''$.author.name''')?.toString() ?? '',
        'image': image,
        'rating': _toNum(getJsonField(book, r'''$.averageRating''')) ?? 0,
        'price': _toNum(getJsonField(book, r'''$.price''')),
        'discountAmount':
            getJsonField(book, r'''$.discount_amount''')?.toString(),
        'discountPercentage':
            getJsonField(book, r'''$.discount_percentage''')?.toString(),
        'offerPrice': _calculateOfferPrice(
          getJsonField(book, r'''$.price'''),
          getJsonField(book, r'''$.discount_amount'''),
          getJsonField(book, r'''$.discount_percentage'''),
        ),
        'raw': book,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.audiobook;

    return FutureBuilder<ApiCallResponse>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final detailsList = snapshot.hasData
            ? EbookGroup.getbookdetailsApiCall
                .bookDetails(snapshot.data!.jsonBody)
            : null;
        final details = (detailsList != null && detailsList.isNotEmpty)
            ? detailsList.first
            : null;
        // Hydrate UUID from details when route payload did not contain a usable id.
        final detailBookId = _extractBookIdFromDetails(details);
        if (detailBookId.isNotEmpty && detailBookId != _bookId) {
          _bookId = detailBookId;
          _v2Tracks = [];
          _tracksLoadedForBookId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _loadV2Tracks();
            if (FFAppState().isLogin) {
              await _refreshAudioAccess();
            }
          });
        }
        final book = _normalizeBookDetails(details, fallback);
        final accessType = _resolveAccessType(details, fallback);
        final basePrice = (_toNum(book['price']) ?? 0).toDouble();
        final audiobookCoinPrice = _audiobookCoinPrice(details, fallback);
        final isFreeAccess = accessType.contains('free') || basePrice <= 0;
        final hasAccess = isFreeAccess || _isPurchased || _hasAudioAccess;
        final priceLabel =
            basePrice <= 0 ? 'Free' : '৳${book['offerPrice'] ?? book['price']}';
        var chapters = _v2Tracks.isNotEmpty
            ? _v2Tracks.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                final trackNumber = (t['track_number'] is num)
                    ? (t['track_number'] as num).toInt()
                    : (i + 1);
                final isPreview = t['is_preview'] == true;
                return <String, dynamic>{
                  'title': t['title']?.toString() ?? 'Chapter $trackNumber',
                  'duration': t['duration']?.toString() ?? '--:--',
                  'track_number': trackNumber,
                  'isLocked': hasAccess ? false : !isPreview,
                  'isPreview': isPreview,
                  'raw': t,
                };
              }).toList()
            : _normalizeChapters(
                details,
                (fallback['chapters'] as List?) ?? [],
                hasAccess: hasAccess,
              );
        if (chapters.isEmpty && _bookId.isNotEmpty) {
          chapters = <Map<String, dynamic>>[
            {
              'title': 'Episode 1',
              'duration': '--:--',
              'track_number': 1,
              'isLocked': false,
              'isPreview': true,
              'raw': <String, dynamic>{},
            }
          ];
        }
        final categoryTag = book['category']?.toString() ?? '';
        final languageTag = book['language']?.toString() ?? '';
        final tags = <String>[
          if (categoryTag.trim().isNotEmpty) categoryTag,
          if (languageTag.trim().isNotEmpty) languageTag,
        ];
        final ratingLabel = (book['rating'] ?? 0).toString();
        final reviewsCount = (book['reviewsCount'] ?? 0).toString();
        final description = (book['description'] ?? '').toString();
        final authorId =
            getJsonField(details, r'''$.author._id''')?.toString() ?? '';
        if (_authorBooksFuture == null && authorId.isNotEmpty) {
          _authorBooksFuture = EbookGroup.getbookbyauthorApiCall.call(
            authorId: authorId,
            type: 'audiobook',
          );
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: CustomScrollView(
              slivers: [
                // Premium Silver App Bar with Cover Image
                SliverAppBar(
                  expandedHeight: 400.0,
                  floating: false,
                  pinned: true,
                  backgroundColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
                  automaticallyImplyLeading: false,
                  leading: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => context.safePop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.share_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () async {
                            await SharePlus.instance.share(
                              ShareParams(
                                uri: Uri.parse(
                                  "${FFAppConstants.webUrl}/product/$_bookId",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isFavoriteLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                    ),
                    if (!hasAccess && basePrice > 0)
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.shopping_cart_outlined,
                                color: Colors.white, size: 20),
                            onPressed: () async {
                              if (!FFAppState().isLogin) {
                                context.pushNamed(SignInPageWidget.routeName);
                                return;
                              }
                              final cart = Provider.of<CartProvider>(context,
                                  listen: false);
                              cart.addItem(
                                _bookId,
                                book['title']?.toString() ?? '',
                                book['image']?.toString() ?? '',
                                basePrice,
                                discountAmount: _toNum(getJsonField(
                                        details, r'''$.discount_amount'''))
                                    ?.toDouble(),
                                discountPercentage: _toNum(getJsonField(
                                        details, r'''$.discount_percentage'''))
                                    ?.toDouble(),
                                type: 'audiobook',
                                coinPrice: audiobookCoinPrice > 0
                                    ? audiobookCoinPrice
                                    : null,
                              );
                              await actions
                                  .showCustomToastBottom('Added to cart!');
                            },
                          ),
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          book['image'] ??
                              'https://picsum.photos/seed/audio/800/1200',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                        // Preview Label on Cover
                        Center(
                          child: InkWell(
                            onTap: () async {
                              await _openAudioPlayerFromV2(
                                audiobook: Map<String, dynamic>.from(book),
                                hasAccess: false,
                                startTrackNumber: 1,
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Preview',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['title'] ?? 'Title',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person_pin_circle_outlined,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        book['author'] ?? 'Author Name',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    book['category'] ?? 'Fiction',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  priceLabel,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // Stats Row
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                '$ratingLabel ★',
                                'Review ($reviewsCount)',
                              ),
                              _buildStatItem(context, 'Audio', 'Book'),
                              _buildStatItem(context,
                                  Icons.bookmark_border_rounded, 'Wishlist'),
                              _buildStatItem(
                                  context, '${chapters.length}', 'Chapters'),
                            ],
                          ),
                        ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation1']!),

                        SizedBox(height: 32),

                        // Action Button
                        InkWell(
                          onTap: chapters.isEmpty
                              ? null
                              : () async {
                                  if (hasAccess) {
                                    final playAudio = () async {
                                      await _openAudioPlayerFromV2(
                                        audiobook:
                                            Map<String, dynamic>.from(book),
                                        hasAccess: true,
                                        isFree: isFreeAccess,
                                      );
                                    };

                                    if (isFreeAccess) {
                                      final canShowAd = await AdManager.canShowAd();
                                      if (canShowAd) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) => AdRewardDialog(
                                            bookImage: book['image']?.toString() ?? '',
                                            onWatchAd: playAudio,
                                            adType: 'rewarded_interstitial',
                                          ),
                                        );
                                      } else {
                                        await playAudio();
                                      }
                                    } else {
                                      await playAudio();
                                    }
                                  } else {
                                    if (!FFAppState().isLogin) {
                                      context.pushNamed(
                                          SignInPageWidget.routeName);
                                      return;
                                    }
                                    if (audiobookCoinPrice > 0) {
                                      final unlocked =
                                          await _confirmAndUnlockWithCoins(
                                        title: book['title']?.toString() ?? '',
                                        coinCost: audiobookCoinPrice,
                                      );
                                      if (unlocked) {
                                        await _refreshAudioAccess();
                                        await _openAudioPlayerFromV2(
                                          audiobook:
                                              Map<String, dynamic>.from(book),
                                          hasAccess: true,
                                          isFree: false,
                                        );
                                        return;
                                      }
                                    }
                                    final cart = Provider.of<CartProvider>(
                                      context,
                                      listen: false,
                                    );
                                    cart.addItem(
                                      _bookId,
                                      book['title']?.toString() ?? '',
                                      book['image']?.toString() ?? '',
                                      basePrice,
                                      discountAmount: _toNum(getJsonField(
                                              details,
                                              r'''$.discount_amount'''))
                                          ?.toDouble(),
                                      discountPercentage: _toNum(getJsonField(
                                              details,
                                              r'''$.discount_percentage'''))
                                          ?.toDouble(),
                                      type: 'audiobook',
                                      coinPrice: audiobookCoinPrice > 0
                                          ? audiobookCoinPrice
                                          : null,
                                    );
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            CheckoutPageWidget(),
                                      ),
                                    );
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.headphones_rounded,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  hasAccess
                                      ? 'Listen Now'
                                      : (audiobookCoinPrice > 0
                                          ? 'Unlock with Coins'
                                          : 'Buy Now'),
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 40),

                        // Chapters Section
                        Text(
                          'Chapters',
                          style:
                              FlutterFlowTheme.of(context).titleLarge.override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = chapters[index];
                            return _buildChapterTile(
                              context,
                              book,
                              chapter,
                              index + 1,
                              hasAccess,
                              isFree: isFreeAccess,
                            );
                          },
                        ),

                        SizedBox(height: 32),

                        // Description
                        Text(
                          'Description',
                          style:
                              FlutterFlowTheme.of(context).titleLarge.override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'No description available.',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                lineHeight: 1.5,
                              ),
                        ),

                        // Tags
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags
                                .map((tag) => _buildTag(context, tag))
                                .toList(),
                          ),

                        SizedBox(height: 24),

                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reviews',
                              style: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            InkWell(
                              onTap: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      BookReviewBottomSheetWidget(
                                    bookId: _bookId,
                                  ),
                                );
                                safeSetState(() {
                                  _reviewsFuture =
                                      EbookGroup.getreviewApiCall.call(
                                    bookId: _bookId,
                                    token: FFAppState().token,
                                  );
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.rate_review_outlined,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Write Review',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        FutureBuilder<ApiCallResponse>(
                          future: _reviewsFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              );
                            }
                            final reviews = EbookGroup.getreviewApiCall
                                    .reviewsList(snapshot.data!.jsonBody) ??
                                [];
                            if (reviews.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No reviews yet',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                final review = reviews[index];
                                final rating = getJsonField(
                                      review,
                                      r'''$.rating''',
                                    ) ??
                                    0;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getJsonField(
                                                  review,
                                                  r'''$.userDetails.name''',
                                                )?.toString() ??
                                                'User',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded,
                                                  color: Color(0xFFFFC107),
                                                  size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                rating.toString(),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        getJsonField(
                                              review,
                                              r'''$.description''',
                                            )?.toString() ??
                                            '',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        SizedBox(height: 32),

                        // More from this author
                        _buildSectionHeader(context, 'More from this author'),
                        SizedBox(height: 16),
                        if (_authorBooksFuture == null)
                          SizedBox(
                            height: 120,
                            child: Center(
                              child: Text(
                                'No author data available.',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                              ),
                            ),
                          )
                        else
                          FutureBuilder<ApiCallResponse>(
                            future: _authorBooksFuture,
                            builder: (context, snapshot) {
                              final books = snapshot.hasData
                                  ? _normalizeRelatedBooks(snapshot.data)
                                  : <Map<String, dynamic>>[];
                              final filtered = books
                                  .where((item) => item['id'] != book['id'])
                                  .toList();
                              if (!snapshot.hasData) {
                                return SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          FlutterFlowTheme.of(context).primary,
                                        ),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (filtered.isEmpty) {
                                return SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      'No other audiobooks found.',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                          ),
                                    ),
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildRelatedBookComponent(
                                          filtered[index]),
                                ),
                              );
                            },
                          ),

                        SizedBox(height: 32),

                        _buildSectionHeader(context, 'Similar Audiobooks'),
                        SizedBox(height: 16),
                        FutureBuilder<ApiCallResponse>(
                          future: _relatedFuture,
                          builder: (context, snapshot) {
                            final books = snapshot.hasData
                                ? _normalizeRelatedBooks(snapshot.data)
                                : <Map<String, dynamic>>[];
                            final filtered = books
                                .where((item) => item['id'] != book['id'])
                                .toList();
                            if (!snapshot.hasData) {
                              return SizedBox(
                                height: 120,
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).primary,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (filtered.isEmpty) {
                              return SizedBox(
                                height: 120,
                                child: Center(
                                  child: Text(
                                    'No similar audiobooks found.',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildRelatedBookComponent(filtered[index]),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, dynamic value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value is String)
          Text(
            value,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          )
        else if (value is IconData)
          Icon(value,
              color: FlutterFlowTheme.of(context).primaryText, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildChapterTile(
    BuildContext context,
    Map<String, dynamic> audiobook,
    Map<String, dynamic> chapter,
    int index,
    bool hasAccess, {
    bool isFree = false,
  }) {
    final bool isLocked = chapter['isLocked'] ?? false;
    return InkWell(
      onTap: () async {
        if (isLocked) {
          await actions
              .showCustomToastBottom('Please purchase to unlock this chapter');
          return;
        }
        final startTrack = chapter['track_number'];
        final isChapterPreview = chapter['isPreview'] == true;
        final playAudio = () async {
          await _openAudioPlayerFromV2(
            audiobook: audiobook,
            hasAccess: hasAccess,
            startTrackNumber: startTrack is num ? startTrack.toInt() : null,
            isFree: !isChapterPreview && isFree,
          );
        };

        final isAdNeeded = !isChapterPreview && isFree;
        if (isAdNeeded) {
          final canShowAd = await AdManager.canShowAd();
          if (canShowAd) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AdRewardDialog(
                bookImage: audiobook['image']?.toString() ?? '',
                onWatchAd: playAudio,
                adType: 'rewarded_interstitial',
              ),
            );
          } else {
            await playAudio();
          }
        } else {
          await playAudio();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: FlutterFlowTheme.of(context).primary,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['title'] ?? 'Chapter $index',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Text(
                  //   chapter['duration'] ?? '--:--',
                  //   style: FlutterFlowTheme.of(context).bodySmall.override(
                  //         fontFamily: 'SF Pro Display',
                  //         color: FlutterFlowTheme.of(context).primary,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  // ),
                ],
              ),
            ),
            if (isLocked)
              Icon(Icons.lock_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText, size: 20)
            else
              Icon(Icons.check_circle_rounded,
                  color: FlutterFlowTheme.of(context).success, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Text(
        label,
        style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.bold,
              ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ],
    );
  }

  Widget _buildRelatedBookComponent(Map<String, dynamic> related) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
      child: MainBookComponentWidget(
        key: Key('Related_${related['id'] ?? ''}'),
        id: related['id']?.toString() ?? '',
        image: related['image']?.toString(),
        bookName: related['title']?.toString(),
        authorsName: related['author']?.toString(),
        price: (related['offerPrice'] ?? related['price'] ?? 0).toString(),
        bookType: 'audiobook',
        discountAmount: related['discountAmount']?.toString(),
        discountPercentage: related['discountPercentage']?.toString(),
        isFav: false,
        isFavAction: () async {},
        isMainTap: () async {
          context.pushNamed(
            AudiobookDetailsPageWidget.routeName,
            extra: <String, dynamic>{
              'audiobook': related['raw'] ?? related,
            },
          );
        },
      ),
    );
  }
}
