import 'package:share_plus/share_plus.dart';

import '/app_constants.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/cart_pages/checkout_page_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/dialogs/book_review_bottom_sheet/book_review_bottom_sheet_widget.dart';
import '/pages/empty_components/blank_component/blank_component_widget.dart';
import '/pages/home_pages/about_publisher_page/about_publisher_page_widget.dart';
import '/pages/shimmers/book_detail_shimmer/book_detail_shimmer_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import '/providers/cart_provider.dart';
import '/services/local_download_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'book_detailspage_model.dart';
export 'book_detailspage_model.dart';

enum BookMasterFormatTab { ebook, audiobook, hardcopy }

class BookDetailspageWidget extends StatefulWidget {
  const BookDetailspageWidget({
    super.key,
    required this.name,
    required this.price,
    required this.image,
    required this.id,
  });

  final String? name;
  final String? image;
  final String? price;
  final String? id;

  static String routeName = 'BookDetailspage';
  static String routePath = '/bookDetailspage';

  @override
  State<BookDetailspageWidget> createState() => _BookDetailspageWidgetState();
}

class _BookDetailspageWidgetState extends State<BookDetailspageWidget> {
  late BookDetailspageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  BookMasterFormatTab _activeFormatTab = BookMasterFormatTab.ebook;
  bool _isOpeningReader = false;
  bool _lastEbookAuthError = false;
  final Set<String> _purchasedFormatKeys = <String>{};
  int? _walletCoinBalance;
  bool _isDownloadingEbook = false;
  bool _isBookmarkBusy = false;
  bool _isEbookDownloaded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BookDetailspageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().isLogin) {
        await _checkIfPurchased();
        await _loadBookmarkStatus();
        await _refreshWalletCoinBalance();
        await _checkDownloadStatus();
      }
      safeSetState(() {});
    });
  }

  Future<void> _checkDownloadStatus() async {
    final d = await LocalDownloadService.getDownloadByBookId(widget.id ?? '');
    if (mounted) {
      safeSetState(() {
        _isEbookDownloaded = d != null;
      });
    }
  }

  Future<void> _loadBookmarkStatus() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    final bid = (widget.id ?? '').trim();
    if (bid.isEmpty) return;
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bid/bookmark');
      final res = await http.get(uri, headers: _apiHeaders(authRequired: true));
      if (res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        _model.isFavorite = decoded['bookmarked'] == true;
        _model.isFavoriteInitialized = true;
        if (mounted) safeSetState(() {});
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmarkStatus() async {
    if (_isBookmarkBusy) return;
    if (!FFAppState().isLogin) {
      FFAppState().favChange = true;
      FFAppState().bookId = widget.id ?? '';
      FFAppState().update(() {});
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    final bid = (widget.id ?? '').trim();
    if (bid.isEmpty) return;
    _isBookmarkBusy = true;
    safeSetState(() => _model.isFavoriteLoading = true);
    try {
      final target = !(_model.isFavorite == true);
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bid/bookmark');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({'bookmarked': target}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _model.isFavorite = target;
        await actions.showCustomToastBottom(target ? FFAppState().favText : FFAppState().unFavText);
      }
    } catch (_) {} finally {
      _isBookmarkBusy = false;
      if (mounted) {
        safeSetState(() => _model.isFavoriteLoading = false);
      }
    }
  }

  Future<void> _checkIfPurchased() async {
    try {
      if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
      final headers = _apiHeaders(authRequired: true);
      final purchasesUri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/library/purchases');
      final unlocksUri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/library/unlocks');

      final purchasesRes = await http.get(purchasesUri, headers: headers);
      final unlocksRes = await http.get(unlocksUri, headers: headers);

      final ids = <String>{};
      final keys = <String>{};

      void absorbRows(dynamic rows) {
        if (rows is! List) return;
        for (final row in rows) {
          if (row is! Map) continue;
          final m = Map<String, dynamic>.from(row);
          final bookId = (m['book_id'] ?? m['bookId'] ?? m['books']?['id'])
              ?.toString()
              .trim();
          final format = (m['format'] ?? '').toString().toLowerCase().trim();
          if (bookId != null && bookId.isNotEmpty) {
            ids.add(bookId);
          }
          if (bookId != null &&
              bookId.isNotEmpty &&
              (format == 'ebook' || format == 'audiobook' || format == 'hardcopy')) {
            keys.add('${bookId.toLowerCase()}::$format');
          }
        }
      }

      if (purchasesRes.statusCode == 200) {
        final decoded = jsonDecode(purchasesRes.body);
        if (decoded is Map) {
          absorbRows(decoded['purchases']);
          absorbRows(decoded['items']);
        }
      }
      if (unlocksRes.statusCode == 200) {
        final decoded = jsonDecode(unlocksRes.body);
        if (decoded is Map) absorbRows(decoded['unlocks']);
      }

      _model.purchasedBookIds = ids.toList();
      _model.isPurchased = _model.purchasedBookIds.contains(widget.id);
      _purchasedFormatKeys
        ..clear()
        ..addAll(keys);
      safeSetState(() {});
    } catch (e) {
      debugPrint('Error checking purchased status: $e');
    }
  }

  Future<void> _openBook({
    required String path,
    required String bookName,
    required String bookImage,
    required String authorName,
  }) async {
    if (_isOpeningReader) return;
    safeSetState(() => _isOpeningReader = true);

    try {
      await context.pushNamed(
        ReadBookCustomPageWidget.routeName,
        queryParameters: {
          'pdf': serializeParam(path, ParamType.String),
          'id': serializeParam(widget.id, ParamType.String),
          'name': serializeParam(bookName, ParamType.String),
          'author': serializeParam(authorName, ParamType.String),
          'image': serializeParam(bookImage, ParamType.String),
        }.withoutNulls,
      );
    } catch (e) {
      debugPrint('Open book failed: $e');
      await actions.showCustomToastBottom('Failed to open book');
    } finally {
      if (mounted) {
        safeSetState(() => _isOpeningReader = false);
      }
    }
  }


  List<Map<String, dynamic>> _formatsFromResponse(dynamic responseJson) {
    final raw = getJsonField(responseJson, r'''$.data.bookDetails[0].formats''');
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _pickFormat(
    List<Map<String, dynamic>> formats,
    String name,
  ) {
    final n = name.toLowerCase();
    for (final f in formats) {
      final format = (f['format'] ?? '').toString().toLowerCase();
      final available = f['is_available'] != false;
      if (format == n && available) return f;
    }
    return null;
  }

  double _formatPrice(Map<String, dynamic>? format) {
    if (format == null) return 0;
    final p = format['price'];
    if (p is num) return p.toDouble();
    return double.tryParse((p ?? '0').toString()) ?? 0;
  }

  int _formatCoinPrice(Map<String, dynamic>? format) {
    if (format == null) return 0;
    final c = format['coin_price'];
    if (c is num) return c.toInt();
    return int.tryParse((c ?? '0').toString()) ?? 0;
  }

  int _previewPercent(Map<String, dynamic>? format) {
    final raw = format?['preview_percentage'];
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse('${raw ?? ''}');
    if (parsed == null || parsed <= 0) return 15;
    return parsed;
  }

  bool _hasLocalFormatAccess({
    required String bookId,
    required String format,
    required bool isFree,
    required double price,
  }) {
    if (isFree || price <= 0) return true;
    return _purchasedFormatKeys
        .contains('${bookId.toLowerCase()}::${format.toLowerCase().trim()}');
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

  Future<bool> _hasFormatAccess({
    required String bookId,
    required String format,
  }) async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      return false;
    }
    final formatKey = '${bookId.toLowerCase()}::${format.toLowerCase().trim()}';
    if (_purchasedFormatKeys.contains(formatKey)) {
      return true;
    }
    final body = await _postV2(
      'access/check',
      body: {'book_id': bookId, 'format': format},
      authRequired: true,
    );
    if (body?['has_access'] == true) return true;
    await _checkIfPurchased();
    return _purchasedFormatKeys.contains(formatKey);
  }

  Future<String?> _fetchEbookSignedUrl(String bookId) async {
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({'book_id': bookId}),
      );
      final decoded = jsonDecode(res.body);
      final body = decoded is Map<String, dynamic> ? decoded : null;
      _lastEbookAuthError = _isAuthErrorBody(body);
      final url = _extractUrlFromBody(body);
      if (url != null && url.trim().isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  String? _extractUrlFromBody(Map<String, dynamic>? body) {
    if (body == null) return null;
    final direct = body['signed_url'] ??
        body['url'] ??
        body['ebook_url'] ??
        body['file_url'] ??
        body['pdf_url'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    final nested = body['data'];
    if (nested is Map) {
      final nestedUrl = nested['signed_url'] ??
          nested['url'] ??
          nested['ebook_url'] ??
          nested['file_url'] ??
          nested['pdf_url'];
      if (nestedUrl != null && nestedUrl.toString().trim().isNotEmpty) {
        return nestedUrl.toString().trim();
      }
    }
    return null;
  }

  bool _isAuthErrorBody(Map<String, dynamic>? body) {
    if (body == null) return false;
    final msg = (body['error'] ??
            body['message'] ??
            body['msg'] ??
            body['detail'] ??
            '')
        .toString()
        .toLowerCase();
    if (msg.isEmpty) return false;
    return msg.contains('session expired') ||
        msg.contains('session has expired') ||
        msg.contains('jwt expired') ||
        msg.contains('token expired') ||
        msg.contains('invalid token') ||
        msg.contains('refresh token') ||
        msg.contains('login again');
  }

  String? _extractEbookUrlFromDetails(dynamic responseJson) {
    final candidates = <dynamic>[
      getJsonField(responseJson, r'''$.data.bookDetails[0].pdf'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].preview_pdf'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].ebook_url'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].file_url'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].raw.pdf_url'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].raw.ebook_url'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].raw.file_url'''),
    ];
    for (final c in candidates) {
      final v = c?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  String? _extractEbookPreviewUrlFromDetails(dynamic responseJson) {
    final candidates = <dynamic>[
      getJsonField(responseJson, r'''$.data.bookDetails[0].preview_pdf'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].preview_url'''),
      getJsonField(responseJson, r'''$.data.bookDetails[0].raw.preview_pdf'''),
    ];
    for (final c in candidates) {
      final v = c?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  Future<String?> _fetchEbookSignedUrlGuestAware(String bookId) async {
    // Try guest first for free items; fall back to auth when logged in.
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final guestRes = await http.post(
        uri,
        headers: _apiHeaders(authRequired: false),
        body: jsonEncode({'book_id': bookId}),
      );
      final decoded = jsonDecode(guestRes.body);
      final guestBody = decoded is Map<String, dynamic> ? decoded : null;
      _lastEbookAuthError = _isAuthErrorBody(guestBody);
      final guestUrl = _extractUrlFromBody(guestBody);
      if (guestUrl != null && guestUrl.trim().isNotEmpty) return guestUrl;
    } catch (_) {}
    if (!FFAppState().isLogin) return null;
    return _fetchEbookSignedUrl(bookId);
  }

  Future<List<Map<String, dynamic>>> _fetchAudioTracks(String bookId) async {
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bookId/tracks');
      final res = await http.get(
        uri,
        headers: _apiHeaders(authRequired: false),
      );
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const [];
      final raw = decoded['tracks'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<int?> _walletBalance() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/wallet');
      final res = await http.get(uri, headers: _apiHeaders(authRequired: true));
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

  Future<void> _refreshWalletCoinBalance() async {
    final balance = await _walletBalance();
    if (!mounted) return;
    safeSetState(() => _walletCoinBalance = balance);
  }

  Future<bool> _unlockWithCoins({
    required String bookId,
    required String format,
    required int coinCost,
  }) async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      context.pushNamed(SignInPageWidget.routeName);
      return false;
    }
    try {
      final uri = Uri.parse('${FFAppConstants.mobileApiBaseUrl}/wallet/unlock');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({
          'book_id': bookId,
          'format': format,
          'coin_cost': coinCost,
        }),
      );
      final decoded = jsonDecode(res.body);
      final body = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      if (res.statusCode == 200) {
        _purchasedFormatKeys
            .add('${bookId.toLowerCase()}::${format.toLowerCase().trim()}');
        if (!_model.purchasedBookIds.contains(bookId)) {
          _model.purchasedBookIds.add(bookId);
        }
        await _refreshWalletCoinBalance();
        final msg = body?['message']?.toString() ?? 'Unlocked successfully';
        await actions.showCustomToastBottom(msg);
        return true;
      }
      final err = body?['error']?.toString() ??
          body?['message']?.toString() ??
          'Wallet unlock failed';
      await actions.showCustomToastBottom(err);
      return false;
    } catch (_) {
      await actions.showCustomToastBottom('Wallet unlock failed');
      return false;
    }
  }

  Future<bool> _confirmAndUnlockWithCoins({
    required String bookName,
    required String bookId,
    required String format,
    required int coinCost,
  }) async {
    final balance = await _walletBalance();
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Unlock with Coins'),
              content: Text(
                balance == null
                    ? 'Unlock "$bookName" for $coinCost coins?'
                    : 'Unlock "$bookName" for $coinCost coins?\nYour balance: $balance',
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
            );
          },
        ) ??
        false;
    if (!confirmed) return false;
    return _unlockWithCoins(bookId: bookId, format: format, coinCost: coinCost);
  }

  Future<Map<String, dynamic>?> _fallbackAudioTrack(String bookId) async {
    final guestUrl = await _fetchAudioTrackSignedUrl(
      bookId: bookId,
      trackNumber: 1,
      authRequired: false,
    );
    final authUrl = guestUrl ??
        (FFAppState().isLogin
            ? await _fetchAudioTrackSignedUrl(
                bookId: bookId,
                trackNumber: 1,
                authRequired: true,
              )
            : null);
    if (authUrl == null || authUrl.isEmpty) return null;
    return <String, dynamic>{
      'track_number': 1,
      'title': 'Episode 1',
      'duration': '',
      'is_preview': true,
      'signed_url': authUrl,
    };
  }

  Future<String?> _fetchAudioTrackSignedUrl({
    required String bookId,
    required int trackNumber,
    required bool authRequired,
  }) async {
    final body = await _postV2(
      'content/audio-url',
      body: {'book_id': bookId, 'track_number': trackNumber},
      authRequired: authRequired,
    );
    final url = body?['signed_url']?.toString();
    if (url != null && url.trim().isNotEmpty) return url;
    return null;
  }

  Future<Map<String, dynamic>> _fetchBatchAudioUrls(String bookId) async {
    final body = await _postV2(
      'content/batch-audio-urls',
      body: {'book_id': bookId},
      authRequired: true,
    );
    if (body is Map<String, dynamic>) {
      return body;
    }
    return <String, dynamic>{};
  }

  Future<bool> _openAudiobookPlayerFromV2({
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool hasFullAccess,
    int previewPercent = 15,
  }) async {
    final tracks = await _fetchAudioTracks(bookId);
    final effectiveTracks = List<Map<String, dynamic>>.from(tracks);
    if (effectiveTracks.isEmpty) {
      final fallback = await _fallbackAudioTrack(bookId);
      if (fallback != null) {
        effectiveTracks.add(fallback);
      } else {
        await actions.showCustomToastBottom('No tracks available');
        return false;
      }
    }

    final chapters = <Map<String, dynamic>>[];
    Map<String, dynamic> urlsMap = const <String, dynamic>{};
    if (hasFullAccess && FFAppState().isLogin) {
      final batch = await _fetchBatchAudioUrls(bookId);
      final rawUrls = batch['urls'];
      if (rawUrls is Map) {
        urlsMap = Map<String, dynamic>.from(rawUrls);
      }
    }

    final previewCount = hasFullAccess
        ? effectiveTracks.length
        : (((effectiveTracks.length * (previewPercent / 100)).ceil())
              .clamp(1, effectiveTracks.length));
    for (var i = 0; i < effectiveTracks.length; i++) {
      final track = effectiveTracks[i];
      final isTrackPreview = track['is_preview'] == true || i < previewCount;
      final trackNumber = (track['track_number'] is num)
          ? (track['track_number'] as num).toInt()
          : (i + 1);
      String? signedUrl;
      if (urlsMap.isNotEmpty) {
        final candidate = urlsMap['$trackNumber'];
        if (candidate is Map) {
          signedUrl = candidate['signed_url']?.toString();
        }
      }
      signedUrl ??= track['signed_url']?.toString();
      signedUrl ??= await _fetchAudioTrackSignedUrl(
        bookId: bookId,
        trackNumber: trackNumber,
        authRequired: hasFullAccess && FFAppState().isLogin,
      );
      if (signedUrl == null || signedUrl.isEmpty) {
        if (!hasFullAccess && !isTrackPreview) {
          continue;
        }
        continue;
      }
      if (!hasFullAccess && !isTrackPreview) {
        continue;
      }
      chapters.add({
        'title': track['title']?.toString() ?? 'Track $trackNumber',
        'file': signedUrl,
        'track_number': trackNumber,
        'duration': track['duration']?.toString() ?? '',
        'isLocked': hasFullAccess ? false : !isTrackPreview,
        'isPreview': !hasFullAccess ? true : (track['is_preview'] == true),
      });
    }

    if (chapters.isEmpty) {
      await actions.showCustomToastBottom(
        hasFullAccess
            ? 'Unable to load audiobook tracks'
            : 'No preview tracks available',
      );
      return false;
    }

    if (!hasFullAccess) {
      await actions.showCustomToastBottom(
          'Preview limit: $previewPercent%. Buy or unlock to listen full audiobook.');
    }

    await context.pushNamed(
      AudioPlayerPageWidget.routeName,
      extra: <String, dynamic>{
        'audiobook': {
          '_id': bookId,
          'id': bookId,
          'name': bookName,
          'title': bookName,
          'image': bookImage,
          'author': {'name': authorName},
          'chapters': chapters,
        },
        'chapter': chapters.first,
      },
    );
    return true;
  }

  Future<void> _addToCartAndCheckout({
    required String bookId,
    required String bookName,
    required String bookImage,
    required double price,
    required String type,
    int? coinPrice,
  }) async {
    if (!FFAppState().isLogin) {
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(
      bookId,
      bookName,
      bookImage,
      price,
      increment: false,
      type: type,
      coinPrice: coinPrice,
    );
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CheckoutPageWidget(),
      ),
    );
  }

  Future<void> _handleMasterAction({
    required BookMasterFormatTab tab,
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool isBookFree,
    required Map<String, dynamic>? ebookFormat,
    required Map<String, dynamic>? audiobookFormat,
    required Map<String, dynamic>? hardcopyFormat,
    required dynamic responseJson,
    bool forceBuy = false,
  }) async {
    if (tab == BookMasterFormatTab.ebook) {
      _lastEbookAuthError = false;
      if (ebookFormat == null || ebookFormat['is_available'] == false) {
        await actions.showCustomToastBottom(
            'eBook format is not available for this book');
        return;
      }
      final ebookPrice = _formatPrice(ebookFormat);
      final ebookCoinPrice = _formatCoinPrice(ebookFormat);
      final ebookPreviewPercent = _previewPercent(ebookFormat);
      final isEbookFree = isBookFree || ebookPrice <= 0;
      final hasAccessByApi = FFAppState().isLogin
          ? await _hasFormatAccess(bookId: bookId, format: 'ebook')
          : false;
      final hasAccess = isEbookFree || hasAccessByApi;

      // URL-first strategy: sometimes /access/check can be stale while URL is available.
      String? url;
      if (FFAppState().isLogin) {
        url = await _fetchEbookSignedUrl(bookId);
      }
      if ((url == null || url.isEmpty) && isEbookFree) {
        url = await _fetchEbookSignedUrlGuestAware(bookId);
      }
      url ??= _extractEbookUrlFromDetails(responseJson);

      if (hasAccess && url != null && url.trim().isNotEmpty) {
        final finalUrl = url;
        void performRead() async {
          await _openBook(
            path: finalUrl,
            bookName: bookName,
            bookImage: bookImage,
            authorName: authorName,
          );
        }

        if (isEbookFree) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => custom_widgets.AdRewardDialog(
              bookImage: bookImage,
              onWatchAd: performRead,
            ),
          );
        } else {
          performRead();
        }
        return;
      }

      if (_lastEbookAuthError) {
        await actions.showCustomToastBottom('Please login to read this ebook');
        context.pushNamed(SignInPageWidget.routeName);
        return;
      }

      if (hasAccess) {
        await actions.showCustomToastBottom(
            'Access Denied. Please login and try again.');
        return;
      }

      final previewUrl = _extractEbookPreviewUrlFromDetails(responseJson);
      if (!forceBuy && previewUrl != null && previewUrl.trim().isNotEmpty) {
        await _openBook(
          path: previewUrl,
          bookName: '$bookName (Preview)',
          bookImage: bookImage,
          authorName: authorName,
        );
        await actions.showCustomToastBottom(
            'Preview limit: $ebookPreviewPercent%. Buy or unlock to read full book.');
        return;
      }

      if (!FFAppState().isLogin) {
        await actions.showCustomToastBottom('Sign in to buy/read this ebook');
        context.pushNamed(SignInPageWidget.routeName);
        return;
      }
      if (ebookCoinPrice > 0) {
        final unlocked = await _confirmAndUnlockWithCoins(
          bookName: bookName,
          bookId: bookId,
          format: 'ebook',
          coinCost: ebookCoinPrice,
        );
        if (unlocked) {
          String? unlockedUrl = await _fetchEbookSignedUrl(bookId);
          unlockedUrl ??= await _fetchEbookSignedUrlGuestAware(bookId);
          unlockedUrl ??= _extractEbookUrlFromDetails(responseJson);
          if (unlockedUrl != null && unlockedUrl.trim().isNotEmpty) {
            await _openBook(
              path: unlockedUrl,
              bookName: bookName,
              bookImage: bookImage,
              authorName: authorName,
            );
            return;
          }
          await actions.showCustomToastBottom(
              'Unlocked, but unable to fetch ebook URL right now.');
          return;
        }
      }
      await _addToCartAndCheckout(
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        price: ebookPrice,
        type: 'ebook',
        coinPrice: ebookCoinPrice > 0 ? ebookCoinPrice : null,
      );
      return;
    }

    if (tab == BookMasterFormatTab.audiobook) {
      if (audiobookFormat == null || audiobookFormat['is_available'] == false) {
        await actions.showCustomToastBottom(
            'Audiobook format is not available for this book');
        return;
      }
      final audiobookPrice = _formatPrice(audiobookFormat);
      final audiobookCoinPrice = _formatCoinPrice(audiobookFormat);
      final audiobookPreviewPercent = _previewPercent(audiobookFormat);
      final isAudiobookFree = isBookFree || audiobookPrice <= 0;
      final hasAccess = isAudiobookFree ||
          (FFAppState().isLogin &&
              await _hasFormatAccess(bookId: bookId, format: 'audiobook'));
      if (hasAccess) {
        final opened = await _openAudiobookPlayerFromV2(
          bookId: bookId,
          bookName: bookName,
          bookImage: bookImage,
          authorName: authorName,
          hasFullAccess: hasAccess,
          previewPercent: audiobookPreviewPercent,
        );
        if (!opened && !FFAppState().isLogin && !isAudiobookFree) {
          context.pushNamed(SignInPageWidget.routeName);
        }
        return;
      }
      if (FFAppState().isLogin && audiobookCoinPrice > 0) {
        final unlocked = await _confirmAndUnlockWithCoins(
          bookName: bookName,
          bookId: bookId,
          format: 'audiobook',
          coinCost: audiobookCoinPrice,
        );
        if (unlocked) {
          await _openAudiobookPlayerFromV2(
            bookId: bookId,
            bookName: bookName,
            bookImage: bookImage,
            authorName: authorName,
            hasFullAccess: true,
            previewPercent: audiobookPreviewPercent,
          );
          return;
        }
      }
      await _addToCartAndCheckout(
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        price: audiobookPrice,
        type: 'audiobook',
        coinPrice: audiobookCoinPrice > 0 ? audiobookCoinPrice : null,
      );
      return;
    }
    if (hardcopyFormat == null || hardcopyFormat['is_available'] == false) {
      await actions.showCustomToastBottom(
          'Hardcopy format is not available for this book');
      return;
    }
    final hasHardcopyAccess = FFAppState().isLogin &&
        await _hasFormatAccess(bookId: bookId, format: 'hardcopy');
    if (hasHardcopyAccess) {
      context.pushNamed(OrdersPageWidget.routeName);
      return;
    }
    await _addToCartAndCheckout(
      bookId: bookId,
      bookName: bookName,
      bookImage: bookImage,
      price: _formatPrice(hardcopyFormat),
      type: 'hardcopy',
    );
  }

  Future<void> _downloadEbookForOffline({
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool isBookFree,
  }) async {
    if (_isDownloadingEbook) return;
    if (!FFAppState().isLogin) {
      await actions.showCustomToastBottom('Sign in to download');
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    safeSetState(() => _isDownloadingEbook = true);
    final hasAccess = isBookFree ||
        await _hasFormatAccess(bookId: bookId, format: 'ebook');
    safeSetState(() => _isDownloadingEbook = false);

    if (!hasAccess) {
      await actions.showCustomToastBottom(
          'Buy or unlock ebook before download');
      return;
    }

    void performDownload() async {
      safeSetState(() => _isDownloadingEbook = true);
      try {
        String? url = await _fetchEbookSignedUrl(bookId);
        url ??= await _fetchEbookSignedUrlGuestAware(bookId);
        if (url == null || url.trim().isEmpty) {
          await actions.showCustomToastBottom('Unable to fetch download URL');
          return;
        }
        await LocalDownloadService.downloadBook(
          bookId: bookId,
          name: bookName,
          image: bookImage,
          author: authorName,
          remoteUrl: url,
        );
        await actions.showCustomToastBottom('Book downloaded successfully');
        await _checkDownloadStatus();
      } catch (_) {
        await actions.showCustomToastBottom('Download failed');
      } finally {
        if (mounted) safeSetState(() => _isDownloadingEbook = false);
      }
    }

    if (isBookFree) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => custom_widgets.AdRewardDialog(
          bookImage: bookImage,
          onWatchAd: performDownload,
        ),
      );
    } else {
      performDownload();
    }
  }

  // ── Audiobook tracks / episodes ────────────────────────────────────────────
  List<Map<String, dynamic>>? _tracks;
  bool _tracksLoading = false;

  Future<void> _loadTracks(String bookId) async {
    if (_tracksLoading || _tracks != null) return;
    if (mounted) safeSetState(() => _tracksLoading = true);
    try {
      final uri = Uri.parse(
          '${FFAppConstants.mobileApiBaseUrl}/books/$bookId/tracks');
      final res =
          await http.get(uri, headers: _apiHeaders(authRequired: false));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map?;
        final raw = body?['tracks'];
        if (raw is List) {
          final parsed = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (parsed.isEmpty) {
            final fallback = await _fallbackAudioTrack(bookId);
            if (fallback != null) {
              if (mounted) {
                safeSetState(() => _tracks = <Map<String, dynamic>>[
                      {
                        'track_number': fallback['track_number'],
                        'title': fallback['title'],
                        'duration': fallback['duration'],
                        'is_preview': true,
                      }
                    ]);
              }
              if (mounted) safeSetState(() => _tracksLoading = false);
              return;
            }
          }
          if (mounted) {
            safeSetState(() => _tracks = parsed);
          }
        } else {
          if (mounted) safeSetState(() => _tracks = []);
        }
      } else {
        if (mounted) safeSetState(() => _tracks = []);
      }
    } catch (_) {
      if (mounted) safeSetState(() => _tracks = []);
    }
    if (mounted) safeSetState(() => _tracksLoading = false);
  }

  /// Person-card row used for author / narrator / publisher
  Widget _buildPersonRow({
    required String label,
    required String name,
    required String imageUrl,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 48.0,
              height: 48.0,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/error_image.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // Name + label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      style: theme.bodySmall.override(
                        fontFamily: 'SF Pro Display',
                        color: theme.secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                      ),
                    ),
                ],
              ),
            ),
            // Label badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                label,
                style: theme.bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  color: theme.primary,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesInAudioTab(String bookId) {
    // Trigger load on first render.
    if (_tracks == null && !_tracksLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTracks(bookId));
    }
    final tracks = _tracks ?? [];
    final trackCount = tracks.length;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _tracksLoading ? 'Episodes' : 'Episodes ($trackCount)',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                    ),
              ),
              if (_tracksLoading)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_tracksLoading && trackCount == 0)
            Text(
              'No episodes available.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'SF Pro Display',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                  ),
            ),
          ...tracks.map((track) {
            final isPreview = track['is_preview'] == true;
            final num = track['track_number'];
            final title = track['title']?.toString() ?? '';
            final dur = track['duration']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 2.0),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                    child: Text(
                      '${num ?? ''}',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 13.0,
                          letterSpacing: 0.0,
                        ),
                  ),
                  subtitle: dur.isNotEmpty
                      ? Text(
                          dur,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 11.0,
                                letterSpacing: 0.0,
                              ),
                        )
                      : null,
                  trailing: isPreview
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _showLegacyEpisodesSection() {
    // Kept for staged cleanup while new in-tab episodes UI is active.
    return false;
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<ApiCallResponse>(
      future: EbookGroup.getbookdetailsApiCall.call(
        bookId: widget.id,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              child: BookDetailShimmerWidget(),
            ),
          );
        }
        final bookDetailspageGetbookdetailsApiResponse = snapshot.data!;
        String bookId = valueOrDefault<String>(
            EbookGroup.getbookdetailsApiCall
                    .id(
                      bookDetailspageGetbookdetailsApiResponse.jsonBody,
                    )
                    ?.toString() ??
                "",
            "");
        String bookName = valueOrDefault<String>(
            EbookGroup.getbookdetailsApiCall.name(
              bookDetailspageGetbookdetailsApiResponse.jsonBody,
            ),
            widget.name ?? "Book");
        String? apiRawImage = EbookGroup.getbookdetailsApiCall
            .image(bookDetailspageGetbookdetailsApiResponse.jsonBody);
        String bookImage = (apiRawImage != null && apiRawImage.isNotEmpty)
            ? "${FFAppConstants.bookImagesUrl}$apiRawImage"
            : (widget.image ?? "");
        final authorName = valueOrDefault<String>(
          EbookGroup.getbookdetailsApiCall.authorName(
            bookDetailspageGetbookdetailsApiResponse.jsonBody,
          ),
          '',
        );
        final formats = _formatsFromResponse(
          bookDetailspageGetbookdetailsApiResponse.jsonBody,
        );
        final isBookFree = getJsonField(
              bookDetailspageGetbookdetailsApiResponse.jsonBody,
              r'''$.data.bookDetails[0].is_free''',
            ) ==
            true;
        final ebookFormat = _pickFormat(formats, 'ebook');
        final audiobookFormat = _pickFormat(formats, 'audiobook');
        final hardcopyFormat = _pickFormat(formats, 'hardcopy');
        final availableTabs = <BookMasterFormatTab>[
          if (ebookFormat != null) BookMasterFormatTab.ebook,
          if (audiobookFormat != null) BookMasterFormatTab.audiobook,
          if (hardcopyFormat != null) BookMasterFormatTab.hardcopy,
        ];
        var activeTab = _activeFormatTab;
        if (availableTabs.isNotEmpty && !availableTabs.contains(activeTab)) {
          activeTab = availableTabs.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            safeSetState(() => _activeFormatTab = activeTab);
          });
        }
        Map<String, dynamic>? selectedFormat;
        String selectedLabel = '';
        if (activeTab == BookMasterFormatTab.ebook) {
          selectedFormat = ebookFormat;
          selectedLabel = 'eBook';
        } else if (activeTab == BookMasterFormatTab.audiobook) {
          selectedFormat = audiobookFormat;
          selectedLabel = 'Audiobook';
        } else {
          selectedFormat = hardcopyFormat;
          selectedLabel = 'Hardcopy';
        }
        final previewPercent = _previewPercent(selectedFormat);
        final ebookPrice = _formatPrice(ebookFormat);
        final hasEbookAccess = _hasLocalFormatAccess(
          bookId: bookId,
          format: 'ebook',
          isFree: isBookFree,
          price: ebookPrice,
        );
        final isEbookPremium = !isBookFree && ebookPrice > 0;

        final showPreviewBadge = activeTab != BookMasterFormatTab.hardcopy &&
            !_hasLocalFormatAccess(
              bookId: bookId,
              format: activeTab == BookMasterFormatTab.ebook
                  ? 'ebook'
                  : 'audiobook',
              isFree: isBookFree,
              price: _formatPrice(selectedFormat),
            );

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: Builder(
            builder: (context) {
              if (EbookGroup.getbookdetailsApiCall.success(
                    bookDetailspageGetbookdetailsApiResponse.jsonBody,
                  ) ==
                  2) {
                return Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(
                        EbookGroup.getbookdetailsApiCall.message(
                          bookDetailspageGetbookdetailsApiResponse.jsonBody,
                        ),
                        'Message',
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            lineHeight: 1.5,
                          ),
                    ),
                  ),
                );
              } else {
                return FutureBuilder<ApiCallResponse>(
                  future: (_model.apiRequestCompleter1 ??=
                          Completer<ApiCallResponse>()
                            ..complete(
                              ApiCallResponse(
                                {'ok': true},
                                const {},
                                200,
                              ),
                            ))
                      .future,
                  builder: (context, snapshot) {
                    // Customize what your widget looks like when it's loading.
                    if (!snapshot.hasData) {
                      return Container(
                        width: double.infinity,
                        child: BookDetailShimmerWidget(),
                      );
                    }
                    final columnGetFavouriteBookResponse = snapshot.data!;

                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            key: Key('RefreshIndicator_dqubpoxi'),
                            color: FlutterFlowTheme.of(context).primary,
                            onRefresh: () async {
                              safeSetState(() {
                                FFAppState().clearGetReviewCacheCacheKey(
                                    _model.apiRequestLastUniqueKey2);
                                _model.apiRequestCompleted2 = false;
                              });
                              await _model.waitForApiRequestCompleted2();
                            },
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                0,
                                0,
                                16.0,
                              ),
                              scrollDirection: Axis.vertical,
                              children: [
                                // Teal App Bar
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primary, // Teal color
                                  ),
                                  child: SafeArea(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 8.0, 16.0, 8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              context.safePop();
                                            },
                                            child: Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Icon(
                                                Icons.arrow_back,
                                                color: Colors.white,
                                                size: 20.0,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              valueOrDefault<String>(
                                                bookName,
                                                'Book',
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color: Colors.white,
                                                        fontSize: 18.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        lineHeight: 1.2,
                                                      ),
                                            ),
                                          ),
                                          // Row(
                                          //   mainAxisSize: MainAxisSize.min,
                                          //   children: [
                                          //     InkWell(
                                          //       splashColor: Colors.transparent,
                                          //       focusColor: Colors.transparent,
                                          //       hoverColor: Colors.transparent,
                                          //       highlightColor: Colors.transparent,
                                          //       onTap: () async {
                                          //         // Shopping cart action
                                          //       },
                                          //       child: Container(
                                          //         width: 40.0,
                                          //         height: 40.0,
                                          //         decoration: BoxDecoration(
                                          //           color: Colors.white.withOpacity(0.2),
                                          //           shape: BoxShape.circle,
                                          //         ),
                                          //         alignment: AlignmentDirectional(0.0, 0.0),
                                          //         child: Icon(
                                          //           Icons.shopping_cart,
                                          //           color: Colors.white,
                                          //           size: 20.0,
                                          //         ),
                                          //       ),
                                          //     ),
                                          //     SizedBox(width: 8.0),
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              await SharePlus.instance.share(
                                                  ShareParams(
                                                      uri: Uri.parse(
                                                          "${FFAppConstants.webUrl}/b/${bookId}")));
                                            },
                                            child: Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Icon(
                                                Icons.share,
                                                color: Colors.white,
                                                size: 20.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Book Information Section
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 20.0, 16.0, 20.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Book Cover
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              PageTransition(
                                                type: PageTransitionType.fade,
                                                child:
                                                    FlutterFlowExpandedImageView(
                                                  image: CachedNetworkImage(
                                                    fadeInDuration: Duration(
                                                        milliseconds: 200),
                                                    fadeOutDuration: Duration(
                                                        milliseconds: 200),
                                                    imageUrl: bookImage,
                                                    fit: BoxFit.contain,
                                                    alignment:
                                                        Alignment(0.0, 0.0),
                                                    errorWidget: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Image.asset(
                                                      'assets/images/error_image.png',
                                                      fit: BoxFit.contain,
                                                      alignment:
                                                          Alignment(0.0, 0.0),
                                                    ),
                                                  ),
                                                  allowRotation: false,
                                                  useHeroAnimation: false,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 120.0,
                                                height: 160.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius: 8.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .shadowColor,
                                                      offset: Offset(0.0, 2.0),
                                                    )
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: CachedNetworkImage(
                                                    fadeInDuration: Duration(
                                                        milliseconds: 200),
                                                    fadeOutDuration: Duration(
                                                        milliseconds: 200),
                                                    imageUrl: bookImage,
                                                    width: 120.0,
                                                    height: 160.0,
                                                    fit: BoxFit.fill,
                                                    alignment:
                                                        Alignment(0.0, 0.0),
                                                    errorWidget: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Icon(
                                                     Icons.photo_outlined,
                                                     color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.4),
                                                      size: 120.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (_model.isPurchased)
                                                Positioned(
                                                  top: 8.0,
                                                  right: 8.0,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8.0,
                                                            vertical: 4.0),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    child: Text(
                                                      'Purchased',
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 10.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                              ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16.0),
                                        // Book Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Primary title
                                              Text(
                                                valueOrDefault<String>(
                                                  bookName,
                                                  'Book',
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 20.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          lineHeight: 1.3,
                                                        ),
                                              ),
                                              // English subtitle (title_en from v2)
                                              Builder(builder: (context) {
                                                final titleEn = getJsonField(
                                                      bookDetailspageGetbookdetailsApiResponse
                                                          .jsonBody,
                                                      r'''$.data.bookDetails[0].slug''',
                                                    )
                                                    ?.toString()
                                                    .replaceAll('-', ' ') ??
                                                    '';
                                                if (titleEn.isEmpty) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2.0),
                                                  child: Text(
                                                    titleEn,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .secondaryText,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                );
                                              }),
                                              SizedBox(height: 8.0),
                                              // Author name
                                              Text(
                                                'By ${EbookGroup.getbookdetailsApiCall.authorName(
                                                  bookDetailspageGetbookdetailsApiResponse
                                                      .jsonBody,
                                                ) ?? ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      fontSize: 13.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      lineHeight: 1.3,
                                                    ),
                                              ),
                                              SizedBox(height: 12.0),

                                              // Rating + reads row
                                              Row(
                                                children: [
                                                  Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 14.0),
                                                  const SizedBox(width: 3.0),
                                                  Text(
                                                    valueOrDefault<String>(
                                                      EbookGroup
                                                          .getbookdetailsApiCall
                                                          .averageRating(
                                                            bookDetailspageGetbookdetailsApiResponse
                                                                .jsonBody,
                                                          )
                                                          ?.toStringAsFixed(1),
                                                      '0.0',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12.0),
                                                  Icon(Icons.auto_stories,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 14.0),
                                                  const SizedBox(width: 3.0),
                                                  Text(
                                                    '${getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r"$.data.bookDetails[0].total_reads") ?? 0} reads',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .secondaryText,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: 10.0),
                                              // Wishlist + Share row
                                              Row(
                                                children: [
                                                  // Add to Wishlist button
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: _toggleBookmarkStatus,
                                                      icon: _model
                                                                  .isFavoriteLoading ==
                                                              true
                                                          ? SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor: AlwaysStoppedAnimation(
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary),
                                                              ),
                                                            )
                                                          : Icon(
                                                              _model.isFavorite!
                                                                  ? Icons
                                                                      .favorite
                                                                  : Icons
                                                                      .favorite_border,
                                                              size: 16.0,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                            ),
                                                      label: Text(
                                                        _model.isFavorite!
                                                            ? 'Wishlisted'
                                                            : 'Wishlist',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              fontSize: 12.0,
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                      ),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        side: BorderSide(
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary
                                                                  .withOpacity(
                                                                      0.5),
                                                        ),
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                ],
                                              ),
                                             
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // ── Format switch buttons + selected format details ──
                                if (availableTabs.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 44,
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: ebookFormat == null
                                                      ? null
                                                      : () => safeSetState(() =>
                                                          _activeFormatTab =
                                                              BookMasterFormatTab
                                                                  .ebook),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: activeTab ==
                                                              BookMasterFormatTab
                                                                  .ebook
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Opacity(
                                                      opacity: ebookFormat == null
                                                          ? 0.45
                                                          : 1,
                                                      child: Text(
                                                        'eBook',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color: activeTab ==
                                                                      BookMasterFormatTab
                                                                          .ebook
                                                                  ? Colors.white
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing: 0.0,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: audiobookFormat == null
                                                      ? null
                                                      : () => safeSetState(() =>
                                                          _activeFormatTab =
                                                              BookMasterFormatTab
                                                                  .audiobook),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: activeTab ==
                                                              BookMasterFormatTab
                                                                  .audiobook
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Opacity(
                                                      opacity: audiobookFormat ==
                                                              null
                                                          ? 0.45
                                                          : 1,
                                                      child: Text(
                                                        'Audiobook',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color: activeTab ==
                                                                      BookMasterFormatTab
                                                                          .audiobook
                                                                  ? Colors.white
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing: 0.0,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: hardcopyFormat == null
                                                      ? null
                                                      : () => safeSetState(() =>
                                                          _activeFormatTab =
                                                              BookMasterFormatTab
                                                                  .hardcopy),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: activeTab ==
                                                              BookMasterFormatTab
                                                                  .hardcopy
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Opacity(
                                                      opacity: hardcopyFormat ==
                                                              null
                                                          ? 0.45
                                                          : 1,
                                                      child: Text(
                                                        'Hardcopy',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color: activeTab ==
                                                                      BookMasterFormatTab
                                                                          .hardcopy
                                                                  ? Colors.white
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing: 0.0,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context)
                                                  .primary
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    selectedLabel,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    'Price: ৳${_formatPrice(selectedFormat).toStringAsFixed(_formatPrice(selectedFormat).truncateToDouble() == _formatPrice(selectedFormat) ? 0 : 2)}',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                if (selectedFormat?['pages'] !=
                                                    null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      'Pages: ${selectedFormat?['pages']}',
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ),
                                                if (selectedFormat?['duration'] !=
                                                    null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      'Duration: ${selectedFormat?['duration']}',
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ),
                                                if (activeTab ==
                                                        BookMasterFormatTab
                                                            .hardcopy &&
                                                    selectedFormat?['in_stock'] !=
                                                        null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      selectedFormat?['in_stock'] ==
                                                              true
                                                          ? 'In stock (${selectedFormat?['stock_count'] ?? 0})'
                                                          : 'Out of stock',
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (FFAppState().isLogin)
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: FlutterFlowTheme.of(context)
                                                    .alternate,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet_rounded,
                                                  size: 16,
                                                  color: FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _walletCoinBalance == null
                                                      ? 'Available coins: --'
                                                      : 'Available coins: $_walletCoinBalance',
                                                  style:
                                                      FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 0.0,
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (activeTab == BookMasterFormatTab.ebook)
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!hasEbookAccess)
                                                // Premium & Not Owned -> Row with Preview and Buy Now
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: FFButtonWidget(
                                                        onPressed: () =>
                                                            _handleMasterAction(
                                                          tab: activeTab,
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          authorName:
                                                              authorName,
                                                          isBookFree:
                                                              isBookFree,
                                                          ebookFormat:
                                                              ebookFormat,
                                                          audiobookFormat:
                                                              audiobookFormat,
                                                          hardcopyFormat:
                                                              hardcopyFormat,
                                                          responseJson:
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                          forceBuy: false,
                                                        ),
                                                        text:
                                                            'Preview ($previewPercent%)',
                                                        icon: Icon(
                                                          Icons
                                                              .menu_book_rounded,
                                                          color: Colors.white,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 48,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: FFButtonWidget(
                                                        onPressed: () =>
                                                            _handleMasterAction(
                                                          tab: activeTab,
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          authorName:
                                                              authorName,
                                                          isBookFree:
                                                              isBookFree,
                                                          ebookFormat:
                                                              ebookFormat,
                                                          audiobookFormat:
                                                              audiobookFormat,
                                                          hardcopyFormat:
                                                              hardcopyFormat,
                                                          responseJson:
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                          forceBuy: true,
                                                        ),
                                                        text: 'Buy Now',
                                                        icon: Icon(
                                                          Icons
                                                              .shopping_cart_rounded,
                                                          color: Colors.white,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 48,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else if (_isEbookDownloaded)
                                                // Owned/Free & Already Downloaded -> Only Read Now
                                                FFButtonWidget(
                                                  onPressed: () =>
                                                      _handleMasterAction(
                                                    tab: activeTab,
                                                    bookId: bookId,
                                                    bookName: bookName,
                                                    bookImage: bookImage,
                                                    authorName: authorName,
                                                    isBookFree: isBookFree,
                                                    ebookFormat: ebookFormat,
                                                    audiobookFormat:
                                                        audiobookFormat,
                                                    hardcopyFormat:
                                                        hardcopyFormat,
                                                    responseJson:
                                                        bookDetailspageGetbookdetailsApiResponse
                                                            .jsonBody,
                                                  ),
                                                  text: 'Read Now',
                                                  icon: Icon(
                                                    Icons.menu_book_rounded,
                                                    color: Colors.white,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: double.infinity,
                                                    height: 48,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                )
                                              else
                                                // Owned/Free & Not Downloaded -> Row with Read and Download
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: FFButtonWidget(
                                                        onPressed: () =>
                                                            _handleMasterAction(
                                                          tab: activeTab,
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          authorName:
                                                              authorName,
                                                          isBookFree:
                                                              isBookFree,
                                                          ebookFormat:
                                                              ebookFormat,
                                                          audiobookFormat:
                                                              audiobookFormat,
                                                          hardcopyFormat:
                                                              hardcopyFormat,
                                                          responseJson:
                                                              bookDetailspageGetbookdetailsApiResponse
                                                                  .jsonBody,
                                                        ),
                                                        text: 'Read Now',
                                                        icon: Icon(
                                                          Icons
                                                              .menu_book_rounded,
                                                          color: Colors.white,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 48,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: FFButtonWidget(
                                                        onPressed:
                                                            _isDownloadingEbook
                                                                ? null
                                                                : () async {
                                                                    await _downloadEbookForOffline(
                                                                      bookId:
                                                                          bookId,
                                                                      bookName:
                                                                          bookName,
                                                                      bookImage:
                                                                          bookImage,
                                                                      authorName:
                                                                          authorName,
                                                                      isBookFree:
                                                                          isBookFree,
                                                                    );
                                                                  },
                                                        text: _isDownloadingEbook
                                                            ? '...'
                                                            : 'Download',
                                                        icon: Icon(
                                                          Icons
                                                              .download_rounded,
                                                          color: Colors.white,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 48,
                                                          color: FlutterFlowTheme.of(context)
                                                              .primary,
                                                          textStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleSmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          )
                                        else
                                            Builder(builder: (context) {
                                              if (activeTab ==
                                                  BookMasterFormatTab
                                                      .audiobook) {
                                                final hasAudioAccess =
                                                    _hasLocalFormatAccess(
                                                  bookId: bookId,
                                                  format: 'audiobook',
                                                  isFree: isBookFree,
                                                  price: _formatPrice(
                                                      audiobookFormat),
                                                );
                                                if (hasAudioAccess) {
                                                  return FFButtonWidget(
                                                    onPressed: () =>
                                                        _handleMasterAction(
                                                      tab: activeTab,
                                                      bookId: bookId,
                                                      bookName: bookName,
                                                      bookImage: bookImage,
                                                      authorName: authorName,
                                                      isBookFree: isBookFree,
                                                      ebookFormat: ebookFormat,
                                                      audiobookFormat:
                                                          audiobookFormat,
                                                      hardcopyFormat:
                                                          hardcopyFormat,
                                                      responseJson:
                                                          bookDetailspageGetbookdetailsApiResponse
                                                              .jsonBody,
                                                    ),
                                                    text: 'Listen Now',
                                                    icon: Icon(
                                                      Icons.headphones_rounded,
                                                      color: Colors.white,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 48,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  );
                                                } else {
                                                  // Premium Audiobook -> Row with Preview and Buy
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Expanded(
                                                        child: FFButtonWidget(
                                                          onPressed: () =>
                                                              _handleMasterAction(
                                                            tab: activeTab,
                                                            bookId: bookId,
                                                            bookName: bookName,
                                                            bookImage:
                                                                bookImage,
                                                            authorName:
                                                                authorName,
                                                            isBookFree:
                                                                isBookFree,
                                                            ebookFormat:
                                                                ebookFormat,
                                                            audiobookFormat:
                                                                audiobookFormat,
                                                            hardcopyFormat:
                                                                hardcopyFormat,
                                                            responseJson:
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                            forceBuy: false,
                                                          ),
                                                          text:
                                                              'Listen Preview ($previewPercent%)',
                                                          icon: Icon(
                                                            Icons
                                                                .headphones_rounded,
                                                            color: Colors.white,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            height: 48,
                                                            color:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: FFButtonWidget(
                                                          onPressed: () =>
                                                              _handleMasterAction(
                                                            tab: activeTab,
                                                            bookId: bookId,
                                                            bookName: bookName,
                                                            bookImage:
                                                                bookImage,
                                                            authorName:
                                                                authorName,
                                                            isBookFree:
                                                                isBookFree,
                                                            ebookFormat:
                                                                ebookFormat,
                                                            audiobookFormat:
                                                                audiobookFormat,
                                                            hardcopyFormat:
                                                                hardcopyFormat,
                                                            responseJson:
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                            forceBuy: true,
                                                          ),
                                                          text: 'Buy Now',
                                                          icon: Icon(
                                                            Icons
                                                                .shopping_cart_rounded,
                                                            color: Colors.white,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            height: 48,
                                                            color:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              } else {
                                                // Hardcopy logic
                                                final hasHardcopyAccess =
                                                    _hasLocalFormatAccess(
                                                  bookId: bookId,
                                                  format: 'hardcopy',
                                                  isFree: isBookFree,
                                                  price: _formatPrice(
                                                      hardcopyFormat),
                                                );
                                                return FFButtonWidget(
                                                  onPressed: () =>
                                                      _handleMasterAction(
                                                    tab: activeTab,
                                                    bookId: bookId,
                                                    bookName: bookName,
                                                    bookImage: bookImage,
                                                    authorName: authorName,
                                                    isBookFree: isBookFree,
                                                    ebookFormat: ebookFormat,
                                                    audiobookFormat:
                                                        audiobookFormat,
                                                    hardcopyFormat:
                                                        hardcopyFormat,
                                                    responseJson:
                                                        bookDetailspageGetbookdetailsApiResponse
                                                            .jsonBody,
                                                  ),
                                                  text: hasHardcopyAccess
                                                      ? 'View Orders'
                                                      : 'Buy Hardcopy',
                                                  icon: Icon(
                                                    Icons.shopping_bag_rounded,
                                                    color: Colors.white,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: double.infinity,
                                                    height: 48,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                );
                                              }
                                            }),
                                      ],
                                    ),
                                  ),
                                if (activeTab ==
                                        BookMasterFormatTab.audiobook &&
                                    audiobookFormat != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 12.0),
                                    child: _buildEpisodesInAudioTab(bookId),
                                  ),
                                // Book Description Section
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 20.0, 16.0, 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'About the book',
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                      SizedBox(height: 12.0),
                                      Container(
                                        width: double.infinity,
                                        child: custom_widgets.ReadMoreHtml(
                                          width: double.infinity,
                                          height: 80.0,
                                          htmlContent: EbookGroup
                                              .getbookdetailsApiCall
                                              .description(
                                            bookDetailspageGetbookdetailsApiResponse
                                                .jsonBody,
                                          ),
                                          maxLength: 150,
                                        ),
                                      ),
                                      SizedBox(height: 16.0),
                                      // Genre Tags
                                      // Row(
                                      //   children: [
                                      //     Container(
                                      //       padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      //       decoration: BoxDecoration(
                                      //         color: FlutterFlowTheme.of(context).secondaryBackground,
                                      //         borderRadius: BorderRadius.circular(20.0),
                                      //       ),
                                      //       child: Text(
                                      //         'Contemporary',
                                      //         style: FlutterFlowTheme.of(context)
                                      //             .bodyMedium
                                      //             .override(
                                      //               fontFamily: 'SF Pro Display',
                                      //               fontSize: 12.0,
                                      //               letterSpacing: 0.0,
                                      //               fontWeight: FontWeight.normal,
                                      //             ),
                                      //       ),
                                      //     ),
                                      //     SizedBox(width: 8.0),
                                      //     Container(
                                      //       padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      //       decoration: BoxDecoration(
                                      //         color: FlutterFlowTheme.of(context).secondaryBackground,
                                      //         borderRadius: BorderRadius.circular(20.0),
                                      //       ),
                                      //       child: Text(
                                      //         'Romance',
                                      //         style: FlutterFlowTheme.of(context)
                                      //             .bodyMedium
                                      //             .override(
                                      //               fontFamily: 'SF Pro Display',
                                      //               fontSize: 12.0,
                                      //               letterSpacing: 0.0,
                                      //               fontWeight: FontWeight.normal,
                                      //             ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 8.0, 16.0, 16.0),
                                  child: Text(
                                    'Information',
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 16.0,
                                          color: FlutterFlowTheme.of(context)
                                              .shadowColor,
                                          offset: Offset(
                                            0.0,
                                            4.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 16.0, 19.0, 15.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Language',
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                                Text(
                                                  valueOrDefault<String>(
                                                    EbookGroup
                                                        .getbookdetailsApiCall
                                                        .language(
                                                      bookDetailspageGetbookdetailsApiResponse
                                                          .jsonBody,
                                                    ),
                                                    'Language',
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        fontSize: 17.0,
                                                        letterSpacing: 0.0,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                              ].divide(SizedBox(height: 8.0)),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rating',
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        fontSize: 15.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0.0),
                                                      child: Image.asset(
                                                        'assets/images/star.png',
                                                        width: 21.0,
                                                        height: 21.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  2.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        valueOrDefault<String>(
                                                          EbookGroup
                                                              .getbookdetailsApiCall
                                                              .averageRating(
                                                                bookDetailspageGetbookdetailsApiResponse
                                                                    .jsonBody,
                                                              )
                                                              ?.toString(),
                                                          '5',
                                                        ),
                                                        maxLines: 1,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 17.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ].divide(SizedBox(height: 8.0)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // ── Author / Narrator / Publisher ──────────────────
                                Builder(builder: (context) {
                                  final aName = EbookGroup
                                          .getbookdetailsApiCall
                                          .authorName(
                                            bookDetailspageGetbookdetailsApiResponse
                                                .jsonBody,
                                          ) ??
                                      '';
                                  final aImage =
                                      '${FFAppConstants.imageUrl}${EbookGroup.getbookdetailsApiCall.authorimage(bookDetailspageGetbookdetailsApiResponse.jsonBody) ?? ''}';
                                  final aId = EbookGroup.getbookdetailsApiCall
                                          .authorid(
                                            bookDetailspageGetbookdetailsApiResponse
                                                .jsonBody,
                                          ) ??
                                      '';

                                  // Extract narrator from audiobook format
                                  final narratorRaw =
                                      audiobookFormat?['narrators'] ??
                                          audiobookFormat?['narrator'];
                                  final narratorObj = (narratorRaw is List &&
                                          narratorRaw.isNotEmpty)
                                      ? narratorRaw.first
                                      : (narratorRaw is Map
                                          ? narratorRaw
                                          : null);

                                  final narName =
                                      narratorObj?['name']?.toString() ?? '';
                                  final narImageRaw =
                                      narratorObj?['avatar_url']?.toString() ??
                                          '';
                                  final narImage = narImageRaw.isEmpty
                                      ? ''
                                      : (narImageRaw.startsWith('http')
                                          ? narImageRaw
                                          : '${FFAppConstants.imageUrl}$narImageRaw');
                                  final narId =
                                      narratorObj?['id']?.toString() ?? '';

                                  final publisherName =
                                      getJsonField(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                        r'''$.data.bookDetails[0].publisher.name''',
                                      )?.toString() ??
                                          '';
                                  final publisherImageRaw =
                                      getJsonField(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                        r'''$.data.bookDetails[0].publisher.image''',
                                      )?.toString() ??
                                          '';
                                  final publisherId =
                                      getJsonField(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                        r'''$.data.bookDetails[0].publisher._id''',
                                      )?.toString() ??
                                          '';
                                  final publisherImage = publisherImageRaw
                                          .isEmpty
                                      ? ''
                                      : (publisherImageRaw.startsWith('http')
                                          ? publisherImageRaw
                                          : '${FFAppConstants.imageUrl}$publisherImageRaw');
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Section title
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(16.0, 16.0, 16.0, 12.0),
                                        child: Text(
                                          'People',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.0,
                                                lineHeight: 1.5,
                                              ),
                                        ),
                                      ),

                                      // Author row
                                      if (aName.isNotEmpty)
                                        _buildPersonRow(
                                          label: 'Author',
                                          name: aName,
                                          imageUrl: aImage,
                                          subtitle: '',
                                          onTap: () => context.pushNamed(
                                            AboutAuthorPageWidget.routeName,
                                            queryParameters: {
                                              'name': serializeParam(
                                                  aName, ParamType.String),
                                              'authorImage': serializeParam(
                                                  aImage, ParamType.String),
                                              'authorId': serializeParam(
                                                  aId, ParamType.String),
                                            }.withoutNulls,
                                          ),
                                        ),

                                      // Narrator row (audiobook only)
                                      if (narName.isNotEmpty)
                                        _buildPersonRow(
                                          label: 'Narrator',
                                          name: narName,
                                          imageUrl: narImage,
                                          subtitle: '',
                                          onTap: () {
                                            if (narId.isNotEmpty) {
                                              context.pushNamed(
                                                AboutNarratorPageWidget
                                                    .routeName,
                                                queryParameters: {
                                                  'name': serializeParam(
                                                      narName,
                                                      ParamType.String),
                                                  'narratorImage':
                                                      serializeParam(narImage,
                                                          ParamType.String),
                                                  'narratorId': serializeParam(
                                                      narId, ParamType.String),
                                                }.withoutNulls,
                                              );
                                            }
                                          },
                                        ),

                                      if (publisherName.isNotEmpty)
                                        _buildPersonRow(
                                          label: 'Publisher',
                                          name: publisherName,
                                          imageUrl: publisherImage,
                                          subtitle: '',
                                          onTap: () {
                                            if (publisherId.isNotEmpty) {
                                              context.pushNamed(
                                                AboutPublisherPageWidget.routeName,
                                                queryParameters: {
                                                  'name': serializeParam(
                                                      publisherName,
                                                      ParamType.String),
                                                  'publisherImage':
                                                      serializeParam(
                                                          publisherImage,
                                                          ParamType.String),
                                                  'publisherId': serializeParam(
                                                      publisherId,
                                                      ParamType.String),
                                                }.withoutNulls,
                                              );
                                            }
                                          },
                                        ),

                                      // Narrator audiobook card (price + play)
                                     
                                    ],
                                  );
                                }),

                                // ── Episodes (tracks) section ──────────────────
                                if (_showLegacyEpisodesSection() &&
                                    activeTab == BookMasterFormatTab.audiobook &&
                                    audiobookFormat != null)
                                  Builder(builder: (context) {
                                    // Trigger load on first render
                                    if (_tracks == null && !_tracksLoading) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                              (_) => _loadTracks(bookId));
                                    }

                                    final tracks = _tracks ?? [];
                                    final trackCount = tracks.length;

                                    return Padding(
                                      padding: const EdgeInsetsDirectional
                                          .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title row
                                          Row(
                                            children: [
                                              Text(
                                                _tracksLoading
                                                    ? 'Episodes'
                                                    : 'Episodes ($trackCount)',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 18.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.0,
                                                          lineHeight: 1.5,
                                                        ),
                                              ),
                                              if (_tracksLoading)
                                                Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .only(start: 8.0),
                                                  child: SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8.0),

                                          if (!_tracksLoading && trackCount == 0)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                'No episodes available.',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                            ),

                                          // Track list
                                          ...tracks.map((track) {
                                            final isPreview =
                                                track['is_preview'] == true;
                                            final num = track['track_number'];
                                            final title =
                                                track['title']?.toString() ??
                                                    '';
                                            final dur =
                                                track['duration']?.toString() ??
                                                    '';
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12.0,
                                                          vertical: 4.0),
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary
                                                            .withOpacity(0.12),
                                                    child: Text(
                                                      '${num ?? ''}',
                                                      style: TextStyle(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 14.0,
                                                              letterSpacing:
                                                                  0.0,
                                                            ),
                                                  ),
                                                  subtitle: dur.isNotEmpty
                                                      ? Text(
                                                          dur,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodySmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                fontSize: 12.0,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                        )
                                                      : null,
                                                  trailing: isPreview
                                                      ? Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8,
                                                                  vertical: 3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.green,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: const Text(
                                                            'Free',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.lock_outline,
                                                          size: 16,
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .secondaryText,
                                                        ),
                                                ),
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 8.0),
                                        ],
                                      ),
                                    );
                                  }),

                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .getReviewCache(
                                    uniqueQueryKey: valueOrDefault<String>(
                                      widget.id,
                                      '0',
                                    ),
                                    requestFn: () =>
                                        EbookGroup.getreviewApiCall.call(
                                      bookId: widget.id,
                                      token: FFAppState().token,
                                    ),
                                  )
                                      .then((result) {
                                    try {
                                      _model.apiRequestCompleted2 = true;
                                      _model.apiRequestLastUniqueKey2 =
                                          valueOrDefault<String>(
                                        widget.id,
                                        '0',
                                      );
                                    } finally {}
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return Container(
                                        width: 0.0,
                                        height: 0.0,
                                        child: BlankComponentWidget(),
                                      );
                                    }
                                    final containerGetreviewApiResponse =
                                        snapshot.data!;

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Builder(
                                        builder: (context) {
                                          if (EbookGroup.getreviewApiCall
                                                  .success(
                                                containerGetreviewApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 16.0,
                                                          16.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Reviews',
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          context.pushNamed(
                                                            RecentReviewsPageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'reviewId':
                                                                  serializeParam(
                                                                widget.id,
                                                                ParamType
                                                                    .String,
                                                              ),
                                                              'bookId':
                                                                  serializeParam(
                                                                widget.id,
                                                                ParamType
                                                                    .String,
                                                              ),
                                                            }.withoutNulls,
                                                          );
                                                        },
                                                        child: Text(
                                                          'View all',
                                                          textAlign:
                                                              TextAlign.end,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                ),
                                                Builder(
                                                  builder: (context) {
                                                    final reviewList = (EbookGroup
                                                                .getreviewApiCall
                                                                .reviewsList(
                                                                  containerGetreviewApiResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [])
                                                        .take(2)
                                                        .toList();

                                                    return SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: List.generate(
                                                                reviewList
                                                                    .length,
                                                                (reviewListIndex) {
                                                          final reviewListItem =
                                                              reviewList[
                                                                  reviewListIndex];
                                                          return Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        16.0,
                                                                        0.0,
                                                                        16.0),
                                                            child: Container(
                                                              width: 320.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    blurRadius:
                                                                        16.0,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .shadowColor,
                                                                    offset:
                                                                        Offset(
                                                                      0.0,
                                                                      4.0,
                                                                    ),
                                                                  )
                                                                ],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12.0),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            16.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          16.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                48.0,
                                                                            height:
                                                                                48.0,
                                                                            clipBehavior:
                                                                                Clip.antiAlias,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                CachedNetworkImage(
                                                                              fadeInDuration: Duration(milliseconds: 200),
                                                                              fadeOutDuration: Duration(milliseconds: 200),
                                                                              imageUrl: () {
                                                                                final img = getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.userDetails.image''',
                                                                                )?.toString() ?? '';
                                                                                if (img.isEmpty) return '';
                                                                                return img.startsWith('http')
                                                                                    ? img
                                                                                    : '${FFAppConstants.imageUrl}$img';
                                                                              }(),
                                                                              fit: BoxFit.cover,
                                                                              errorWidget: (context, error, stackTrace) => Image.asset(
                                                                                'assets/images/error_image.png',
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      reviewListItem,
                                                                                      r'''$.userDetails.name''',
                                                                                    ).toString(),
                                                                                    maxLines: 1,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 16.0,
                                                                                          letterSpacing: 0.0,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                  Text(
                                                                                    getJsonField(
                                                                                      reviewListItem,
                                                                                      r'''$.date''',
                                                                                    ).toString(),
                                                                                    maxLines: 1,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).secondaryText,
                                                                                          fontSize: 15.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.normal,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                ].divide(SizedBox(height: 4.0)),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                                child: ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(0.0),
                                                                                  child: Image.asset(
                                                                                    'assets/images/star.png',
                                                                                    width: 16.0,
                                                                                    height: 16.0,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.rating''',
                                                                                ).toString(),
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 15.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.normal,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      getJsonField(
                                                                        reviewListItem,
                                                                        r'''$.description''',
                                                                      ).toString(),
                                                                      maxLines:
                                                                          3,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'SF Pro Display',
                                                                            fontSize:
                                                                                17.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                            .divide(SizedBox(
                                                                width: 16.0))
                                                            .addToStart(
                                                                SizedBox(
                                                                    width:
                                                                        16.0))
                                                            .addToEnd(SizedBox(
                                                                width: 16.0)),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 12.0,
                                                          16.0, 0.0),
                                                  child: FFButtonWidget(
                                                    onPressed: () async {
                                                      await showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        enableDrag: false,
                                                        context: context,
                                                        builder: (context) {
                                                          return Padding(
                                                            padding: MediaQuery
                                                                .viewInsetsOf(
                                                                    context),
                                                            child: Container(
                                                              height: 489.0,
                                                              child:
                                                                  BookReviewBottomSheetWidget(
                                                                bookId:
                                                                    widget.id!,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ).then((value) =>
                                                          safeSetState(() {}));
                                                    },
                                                    text: 'Write a Review',
                                                    icon: Icon(
                                                      Icons.rate_review_rounded,
                                                      color: Colors.white,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 50.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                      elevation: 2.0,
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 16.0,
                                                          16.0, 0.0),
                                                  child: Text(
                                                    'Reviews',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 20.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 12.0,
                                                          16.0, 0.0),
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                      border: Border.all(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryText
                                                            .withOpacity(0.2),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(24.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .rate_review_outlined,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryText,
                                                            size: 48.0,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        12.0,
                                                                        0.0,
                                                                        4.0),
                                                            child: Text(
                                                              'No reviews yet',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyLarge
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        24.0),
                                                            child: Text(
                                                              'Be the first to share your thoughts!',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelMedium,
                                                            ),
                                                          ),
                                                          FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              await showModalBottomSheet(
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                enableDrag:
                                                                    false,
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return Padding(
                                                                    padding: MediaQuery
                                                                        .viewInsetsOf(
                                                                            context),
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          489.0,
                                                                      child:
                                                                          BookReviewBottomSheetWidget(
                                                                        bookId:
                                                                            widget.id!,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ).then((value) =>
                                                                  safeSetState(
                                                                      () {}));
                                                            },
                                                            text:
                                                                'Write a Review',
                                                            options:
                                                                FFButtonOptions(
                                                              width: 200.0,
                                                              height: 45.0,
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              iconPadding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              textStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                              elevation: 2.0,
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 16.0, 0.0, 0.0),
                                  child: FutureBuilder<ApiCallResponse>(
                                    future: FFAppState().getBookbyCategoryCache(
                                      uniqueQueryKey: valueOrDefault<String>(
                                        widget.id,
                                        'id',
                                      ),
                                      requestFn: () => EbookGroup
                                          .getbookbycategoryApiCall
                                          .call(
                                        categoryId: EbookGroup
                                            .getbookdetailsApiCall
                                            .categoryId(
                                          bookDetailspageGetbookdetailsApiResponse
                                              .jsonBody,
                                        ),
                                      ),
                                    ),
                                    builder: (context, snapshot) {
                                      // Customize what your widget looks like when it's loading.
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: SizedBox(
                                            width: 50.0,
                                            height: 50.0,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      final columnGetbookbycategoryApiResponse =
                                          snapshot.data!;

                                      return Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (EbookGroup
                                                  .getbookbycategoryApiCall
                                                  .success(
                                                columnGetbookbycategoryApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1)
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 0.0, 16.0),
                                              child: Text(
                                                'You might also like',
                                                textAlign: TextAlign.start,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 18.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          lineHeight: 1.5,
                                                        ),
                                              ),
                                            ),
                                          if (EbookGroup
                                                  .getbookbycategoryApiCall
                                                  .success(
                                                columnGetbookbycategoryApiResponse
                                                    .jsonBody,
                                              ) ==
                                              1)
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 0.0),
                                              child: Builder(
                                                builder: (context) {
                                                  final authorRelatedbookDetailslist =
                                                      EbookGroup
                                                              .getbookbycategoryApiCall
                                                              .bookDetailsList(
                                                                columnGetbookbycategoryApiResponse
                                                                    .jsonBody,
                                                              )
                                                              ?.toList() ??
                                                          [];

                                                  return SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Row(
                                                      spacing: 5.0,
                                                      // runSpacing: 16.0,
                                                      // alignment:
                                                      //     WrapAlignment.start,
                                                      // crossAxisAlignment:
                                                      //     WrapCrossAlignment
                                                      //         .start,
                                                      // direction: Axis.horizontal,
                                                      // runAlignment:
                                                          // WrapAlignment.start,
                                                      verticalDirection:
                                                          VerticalDirection.down,
                                                      // clipBehavior: Clip.none,
                                                      children: List.generate(
                                                          authorRelatedbookDetailslist
                                                              .length,
                                                          (authorRelatedbookDetailslistIndex) {
                                                        final authorRelatedbookDetailslistItem =
                                                            authorRelatedbookDetailslist[
                                                                authorRelatedbookDetailslistIndex];
                                                        return wrapWithModel(
                                                          model: _model
                                                              .mainBookComponentModels
                                                              .getModel(
                                                            getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            authorRelatedbookDetailslistIndex,
                                                          ),
                                                          updateCallback: () =>
                                                              safeSetState(() {}),
                                                          child:
                                                              MainBookComponentWidget(
                                                            key: Key(
                                                              'Keybek_${getJsonField(
                                                                authorRelatedbookDetailslistItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            image:
                                                                '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.image''',
                                                            ).toString()}',
                                                            bookName:
                                                                getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.name''',
                                                            ).toString(),
                                                            id: getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$._id''',
                                                            ).toString(),
                                                            isPurchased: _model
                                                                .purchasedBookIds
                                                                .contains(
                                                              getJsonField(
                                                                authorRelatedbookDetailslistItem,
                                                                r'''$._id''',
                                                              ).toString(),
                                                            ),
                                                            price: getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.price''',
                                                            ).toString(),
                                                            bookType: getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.type''',
                                                            )?.toString(),
                                                            discountAmount:
                                                                getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.discount_amount''',
                                                            ).toString(),
                                                            discountPercentage:
                                                                getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.discount_percentage''',
                                                            ).toString(),
                                                            authorsName:
                                                                getJsonField(
                                                              authorRelatedbookDetailslistItem,
                                                              r'''$.author.name''',
                                                            ).toString(),
                                                            isFav: functions.checkFavOrNot(
                                                                    EbookGroup.getFavouriteBookCall
                                                                        .favouriteBookDetailsList(
                                                                          columnGetFavouriteBookResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList(),
                                                                    getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$._id''',
                                                                    ).toString()) ==
                                                                true,
                                                            indicator: (authorRelatedbookDetailslistIndex ==
                                                                    _model
                                                                        .relatedIndex) &&
                                                                (_model.isRelated ==
                                                                    true),
                                                            isFavAction:
                                                                () async {
                                                              if (FFAppState()
                                                                      .isLogin ==
                                                                  true) {
                                                                _model.isRelated =
                                                                    true;
                                                                _model.relatedIndex =
                                                                    authorRelatedbookDetailslistIndex;
                                                                safeSetState(
                                                                    () {});
                                                                if (functions.checkFavOrNot(
                                                                        EbookGroup.getFavouriteBookCall
                                                                            .favouriteBookDetailsList(
                                                                              columnGetFavouriteBookResponse.jsonBody,
                                                                            )
                                                                            ?.toList(),
                                                                        getJsonField(
                                                                          authorRelatedbookDetailslistItem,
                                                                          r'''$._id''',
                                                                        ).toString()) ==
                                                                    true) {
                                                                  _model.getPopularDetete =
                                                                      await EbookGroup
                                                                          .removeFavouritebookCall
                                                                          .call(
                                                                    userId:
                                                                        FFAppState()
                                                                            .userId,
                                                                    token:
                                                                        FFAppState()
                                                                            .token,
                                                                    bookId:
                                                                        getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$._id''',
                                                                    ).toString(),
                                                                  );
                                                    
                                                                  safeSetState(() =>
                                                                      _model.apiRequestCompleter1 =
                                                                          null);
                                                                  await _model
                                                                      .waitForApiRequestCompleted1();
                                                                  await actions
                                                                      .showCustomToastBottom(
                                                                    FFAppState()
                                                                        .unFavText,
                                                                  );
                                                                } else {
                                                                  _model.getPopularAdd =
                                                                      await EbookGroup
                                                                          .addFavouriteBookApiCall
                                                                          .call(
                                                                    userId:
                                                                        FFAppState()
                                                                            .userId,
                                                                    token:
                                                                        FFAppState()
                                                                            .token,
                                                                    bookId:
                                                                        getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$._id''',
                                                                    ).toString(),
                                                                  );
                                                    
                                                                  safeSetState(() =>
                                                                      _model.apiRequestCompleter1 =
                                                                          null);
                                                                  await _model
                                                                      .waitForApiRequestCompleted1();
                                                                  await actions
                                                                      .showCustomToastBottom(
                                                                    FFAppState()
                                                                        .favText,
                                                                  );
                                                                }
                                                    
                                                                FFAppState()
                                                                    .clearGetFavouriteBookCacheCache();
                                                                _model.isRelated =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              } else {
                                                                FFAppState()
                                                                        .favChange =
                                                                    true;
                                                                FFAppState()
                                                                        .bookId =
                                                                    getJsonField(
                                                                  authorRelatedbookDetailslistItem,
                                                                  r'''$._id''',
                                                                ).toString();
                                                                FFAppState()
                                                                    .update(
                                                                        () {});
                                                    
                                                                context.pushNamed(
                                                                    SignInPageWidget
                                                                        .routeName);
                                                              }
                                                    
                                                              safeSetState(() {});
                                                            },
                                                            isMainTap: () async {
                                                              context.pushNamed(
                                                                BookDetailspageWidget
                                                                    .routeName,
                                                                queryParameters: {
                                                                  'name':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'image':
                                                                      serializeParam(
                                                                    '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$.image''',
                                                                    ).toString()}',
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                  'id':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      authorRelatedbookDetailslistItem,
                                                                      r'''$._id''',
                                                                    ).toString(),
                                                                    ParamType
                                                                        .String,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // FutureBuilder<ApiCallResponse>(
                        //   future:
                        //       EbookGroup.usersubscriptionvalidityApiCall.call(
                        //     userId: FFAppState().userId,
                        //     token: FFAppState().token,
                        //   ),
                        //   builder: (context, snapshot) {
                        //     // Customize what your widget looks like when it's loading.
                        //     if (!snapshot.hasData) {
                        //       return Container(
                        //         width: double.infinity,
                        //         height: 88.0,
                        //         child: ButtonDetailPageShimmerWidget(),
                        //       );
                        //     }
                        //     final _ = snapshot.data!;

                        //     return Container(
                        //       width: double.infinity,
                        //       decoration: BoxDecoration(
                        //         color: FlutterFlowTheme.of(context)
                        //             .secondaryBackground,
                        //         boxShadow: [
                        //           BoxShadow(
                        //             blurRadius: 16.0,
                        //             color: FlutterFlowTheme.of(context)
                        //                 .shadowColor,
                        //             offset: Offset(
                        //               0.0,
                        //               4.0,
                        //             ),
                        //           )
                        //         ],
                        //       ),
                        //       child: FutureBuilder<ApiCallResponse>(
                        //         future: (_model.apiRequestCompleter3 ??=
                        //                 Completer<ApiCallResponse>()
                        //                   ..complete(EbookGroup
                        //                       .downloadhistoryApiCall
                        //                       .call(
                        //                     userId: FFAppState().userId,
                        //                     token: FFAppState().token,
                        //                   )))
                        //             .future,
                        //         builder: (context, snapshot) {
                        //           // Customize what your widget looks like when it's loading.
                        //           if (!snapshot.hasData) {
                        //             return Container(
                        //               width: double.infinity,
                        //               height: 88.0,
                        //               child: ButtonDetailPageShimmerWidget(),
                        //             );
                        //           }
                        //           final _ = snapshot.data!;

                        //           return Container(
                        //             decoration: BoxDecoration(),
                        //             child: Padding(
                        //               padding: EdgeInsets.all(16.0),
                        //               child: Builder(
                        //                 builder: (context) {
                        //                   // Check if book is free or paid
                        //                   final accessType = EbookGroup.getbookdetailsApiCall.accesstype(
                        //                     bookDetailspageGetbookdetailsApiResponse.jsonBody,
                        //                   );

                        //                   if (accessType == 'free') {
                        //                     // Free book - show "Read Book" button
                        //                     return FFButtonWidget(
                        //                       onPressed: () async {
                        //                         context.pushNamed(
                        //                           ReadBookCustomPageWidget.routeName,
                        //                           queryParameters: {
                        //                             'pdf': serializeParam(
                        //                               '${FFAppConstants.pdfUrl}${EbookGroup.getbookdetailsApiCall.pdf(
                        //                                 bookDetailspageGetbookdetailsApiResponse.jsonBody,
                        //                               )}',
                        //                               ParamType.String,
                        //                             ),
                        //                             'id': serializeParam(
                        //                               widget.id,
                        //                               ParamType.String,
                        //                             ),
                        //                             'name': serializeParam(
                        //                               widget.name,
                        //                               ParamType.String,
                        //                             ),
                        //                             'image': serializeParam(
                        //                               widget.image,
                        //                               ParamType.String,
                        //                             ),
                        //                           }.withoutNulls,
                        //                         );

                        //                         if (widget.id == FFAppState().homePageBookId) {
                        //                           FFAppState().totalPages = 1;
                        //                           FFAppState().update(() {});
                        //                         } else {
                        //                           FFAppState().totalPages = 1;
                        //                           FFAppState().homePageCurrentPdfIndex = 1;
                        //                           FFAppState().update(() {});
                        //                         }
                        //                       },
                        //                       text: 'Read Book',
                        //                       options: FFButtonOptions(
                        //                         width: double.infinity,
                        //                         height: 56.0,
                        //                         padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        //                         iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        //                         color: FlutterFlowTheme.of(context).primary,
                        //                         textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        //                           fontFamily: 'SF Pro Display',
                        //                           color: FlutterFlowTheme.of(context).primaryBackground,
                        //                           fontSize: 16.0,
                        //                           letterSpacing: 0.0,
                        //                           fontWeight: FontWeight.bold,
                        //                           lineHeight: 1.2,
                        //                         ),
                        //                         elevation: 0.0,
                        //                         borderSide: BorderSide(
                        //                           color: Colors.transparent,
                        //                           width: 1.0,
                        //                         ),
                        //                         borderRadius: BorderRadius.circular(12.0),
                        //                       ),
                        //                     );
                        //                   } else {
                        //                     // Paid book - show Preview, Add to Cart, and Buy Now buttons
                        //                     return Column(
                        //                       mainAxisSize: MainAxisSize.min,
                        //                       children: [
                        //                         // Preview button
                        //                         FFButtonWidget(
                        //                           onPressed: () async {

                        //                             context.pushNamed(
                        //                               ReadBookCustomPageWidget.routeName,
                        //                               queryParameters: {
                        //                                 'pdf': serializeParam(
                        //                                   '${FFAppConstants.pdfUrl}${EbookGroup.getbookdetailsApiCall.previewPdf(
                        //                                     bookDetailspageGetbookdetailsApiResponse.jsonBody,
                        //                                   )}',
                        //                                   ParamType.String,
                        //                                 ),
                        //                                 'id': serializeParam(
                        //                                   widget.id,
                        //                                   ParamType.String,
                        //                                 ),
                        //                                 'name': serializeParam(
                        //                                   bookName,
                        //                                   ParamType.String,
                        //                                 ),
                        //                                 'image': serializeParam(
                        //                                   bookImage,
                        //                                   ParamType.String,
                        //                                 ),

                        //                               }.withoutNulls,
                        //                             );
                        //                           },
                        //                           text: 'Preview',
                        //                           options: FFButtonOptions(
                        //                             width: double.infinity,
                        //                             height: 48.0,
                        //                             padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        //                             iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        //                             color: FlutterFlowTheme.of(context).secondaryBackground,
                        //                             textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        //                               fontFamily: 'SF Pro Display',
                        //                               color: FlutterFlowTheme.of(context).primaryText,
                        //                               fontSize: 14.0,
                        //                               letterSpacing: 0.0,
                        //                               fontWeight: FontWeight.w500,
                        //                               lineHeight: 1.2,
                        //                             ),
                        //                             elevation: 0.0,
                        //                             borderSide: BorderSide(
                        //                               color: FlutterFlowTheme.of(context).primary,
                        //                               width: 1.0,
                        //                             ),
                        //                             borderRadius: BorderRadius.circular(12.0),
                        //                           ),
                        //                         ),
                        //                         SizedBox(height: 12.0),
                        //                         // Add to Cart and Buy Now buttons
                        //                         Consumer<CartProvider>(
                        //                           builder: (context, cart, child) {
                        //                             final isInCart = cart.items.containsKey(widget.id ?? "");
                        //                             final quantity = isInCart ? cart.items[widget.id ?? ""]?.quantity ?? 0 : 0;

                        //                             return Row(
                        //                               mainAxisSize: MainAxisSize.max,
                        //                               children: [
                        //                                 if (quantity > 0) ...[
                        //                                   // Quantity controls when item is in cart
                        //                                   Expanded(
                        //                                     child: Padding(
                        //                                       padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                        //                                       child: Container(
                        //                                         height: 48.0,
                        //                                         decoration: BoxDecoration(
                        //                                           color: FlutterFlowTheme.of(context).secondaryBackground,
                        //                                           border: Border.all(
                        //                                             color: FlutterFlowTheme.of(context).primary,
                        //                                             width: 1.0,
                        //                                           ),
                        //                                           borderRadius: BorderRadius.circular(12.0),
                        //                                         ),
                        //                                         child: Row(
                        //                                           mainAxisAlignment: MainAxisAlignment.center,
                        //                                           children: [
                        //                                             // Decrement button
                        //                                             InkWell(
                        //                                               onTap: () async{
                        //                                                 cart.removeSingleItem(widget.id ?? "");
                        //                                                await actions.showCustomToastBottom('Quantity decreased!');
                        //                                               },
                        //                                               child: Container(
                        //                                                 width: 36.0,
                        //                                                 height: 36.0,
                        //                                                 decoration: BoxDecoration(
                        //                                                   color: FlutterFlowTheme.of(context).primary,
                        //                                                   shape: BoxShape.circle,
                        //                                                 ),
                        //                                                 child: Icon(
                        //                                                   Icons.remove,
                        //                                                   color: FlutterFlowTheme.of(context).primaryBackground,
                        //                                                   size: 20.0,
                        //                                                 ),
                        //                                               ),
                        //                                             ),
                        //                                             // Quantity display
                        //                                             Container(
                        //                                               padding: EdgeInsets.symmetric(horizontal: 10),
                        //                                               child: Text(
                        //                                                 quantity.toString(),
                        //                                                 textAlign: TextAlign.center,
                        //                                                 style: FlutterFlowTheme.of(context).bodyMedium.override(
                        //                                                   fontFamily: 'SF Pro Display',
                        //                                                   fontSize: 16.0,
                        //                                                   fontWeight: FontWeight.bold,
                        //                                                   color: FlutterFlowTheme.of(context).primaryText,
                        //                                                 ),
                        //                                               ),
                        //                                             ),
                        //                                             // Increment button
                        //                                             InkWell(
                        //                                               onTap: ()async {
                        //                                                 cart.addItem(
                        //                                                   widget.id!,
                        //                                                   widget.name!,
                        //                                                   widget.image!,
                        //                                                  double.tryParse(widget.price!)??0.0,

                        //                                                 );
                        //                                                 await actions.showCustomToastBottom('Quantity increased!');
                        //                                               },
                        //                                               child: Container(
                        //                                                 width: 36.0,
                        //                                                 height: 36.0,
                        //                                                 decoration: BoxDecoration(
                        //                                                   color: FlutterFlowTheme.of(context).primary,
                        //                                                   shape: BoxShape.circle,
                        //                                                 ),
                        //                                                 child: Icon(
                        //                                                   Icons.add,
                        //                                                   color: FlutterFlowTheme.of(context).primaryBackground,
                        //                                                   size: 20.0,
                        //                                                 ),
                        //                                               ),
                        //                                             ),
                        //                                           ],
                        //                                         ),
                        //                                       ),
                        //                                     ),
                        //                                   ),
                        //                                 ] else ...[
                        //                                   // Add to Cart button when item is not in cart
                        //                                   Expanded(
                        //                                     child: Padding(
                        //                                       padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                        //                                       child: FFButtonWidget(
                        //                                         onPressed: () async {
                        //                                           cart.addItem(
                        //                                             widget.id!,
                        //                                             widget.name!,
                        //                                             widget.image!,
                        //                                             double.tryParse(widget.price!)??0.0,
                        //                                           );
                        //                                           ScaffoldMessenger.of(context).showSnackBar(
                        //                                             SnackBar(
                        //                                               content: Text(
                        //                                                 'Book added to cart!',
                        //                                                 style: TextStyle(
                        //                                                   color: FlutterFlowTheme.of(context).primaryText,
                        //                                                 ),
                        //                                               ),
                        //                                               duration: Duration(milliseconds: 2000),
                        //                                               backgroundColor: FlutterFlowTheme.of(context).secondary,
                        //                                             ),
                        //                                           );
                        //                                         },
                        //                                         text: 'Add to Cart',
                        //                                         options: FFButtonOptions(
                        //                                           width: double.infinity,
                        //                                           height: 48.0,
                        //                                           padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        //                                           iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        //                                           color: FlutterFlowTheme.of(context).secondaryBackground,
                        //                                           textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        //                                             fontFamily: 'SF Pro Display',
                        //                                             color: FlutterFlowTheme.of(context).primaryText,
                        //                                             fontSize: 14.0,
                        //                                             letterSpacing: 0.0,
                        //                                             fontWeight: FontWeight.w600,
                        //                                             lineHeight: 1.2,
                        //                                           ),
                        //                                           elevation: 0.0,
                        //                                           borderSide: BorderSide(
                        //                                             color: FlutterFlowTheme.of(context).primary,
                        //                                             width: 1.0,
                        //                                           ),
                        //                                           borderRadius: BorderRadius.circular(12.0),
                        //                                         ),
                        //                                       ),
                        //                                     ),
                        //                                   ),
                        //                                 ],
                        //                             Expanded(
                        //                               child: Padding(
                        //                                 padding: EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 0.0, 0.0),
                        //                                 child: FFButtonWidget(
                        //                                   onPressed: () async {
                        //                                     if(FFAppState()
                        //                                         .isLogin ==
                        //                                     true){
                        //                                        final cart = Provider.of<CartProvider>(context, listen: false);
                        //                                     cart.addItem(
                        //                                       widget.id!,
                        //                                       widget.name!,
                        //                                       widget.image!,
                        //                                      double.tryParse(widget.price!)??0.0,
                        //                                     );
                        //                                  Navigator.push<void>(
                        //                                    context,
                        //                                    MaterialPageRoute<void>(
                        //                                      builder: (BuildContext context) =>  CheckoutPageWidget(),
                        //                                    ),
                        //                                  );
                        //                                     }else{
                        //                                                                                                 context.pushNamed(
                        //                                       SignInPageWidget
                        //                                           .routeName);
                        //                                     }

                        //                                   },
                        //                                   text: 'Buy Now',
                        //                                   options: FFButtonOptions(
                        //                                     width: double.infinity,
                        //                                     height: 48.0,
                        //                                     padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        //                                     iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        //                                     color: FlutterFlowTheme.of(context).primary,
                        //                                     textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        //                                       fontFamily: 'SF Pro Display',
                        //                                       color: FlutterFlowTheme.of(context).primaryBackground,
                        //                                       fontSize: 14.0,
                        //                                       letterSpacing: 0.0,
                        //                                       fontWeight: FontWeight.w600,
                        //                                       lineHeight: 1.2,
                        //                                     ),
                        //                                     elevation: 0.0,
                        //                                     borderSide: BorderSide(
                        //                                       color: Colors.transparent,
                        //                                       width: 1.0,
                        //                                     ),
                        //                                     borderRadius: BorderRadius.circular(12.0),
                        //                                   ),
                        //                                 ),
                        //                               ),
                        //                             ),
                        //                           ],
                        //                         );})
                        //                       ],
                        //                     );
                        //                   }
                        //                 },
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //     );
                        //   },
                        // ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}

