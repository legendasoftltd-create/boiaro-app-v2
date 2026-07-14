import 'package:share_plus/share_plus.dart';

import '/app_constants.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/cart_pages/checkout_page_widget.dart';
import '/pages/cart_pages/cart_page_widget.dart';
import '/pages/cart_pages/payment_screen.dart';
import '/pages/cart_pages/make_payment.dart';
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
import '/custom_code/ad_manager.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:a_i_ebook_app/services/revenue_cat_service.dart';
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
    this.initialTab,
  });

  final String? name;
  final String? image;
  final String? price;
  final String? id;
  final String? initialTab;

  static String routeName = 'BookDetailspage';
  static String routePath = '/bookDetailspage';

  @override
  State<BookDetailspageWidget> createState() => _BookDetailspageWidgetState();
}

class _BookDetailspageWidgetState extends State<BookDetailspageWidget> {
  late BookDetailspageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  BookMasterFormatTab _activeFormatTab = BookMasterFormatTab.ebook;
  bool _showAllNarrators = false;
  bool _isOpeningReader = false;
  bool _lastEbookAuthError = false;
  final Set<String> _purchasedFormatKeys = <String>{};
  int? _walletCoinBalance;
  bool _isDownloadingEbook = false;
  bool _isBookmarkBusy = false;
  bool _isEbookDownloaded = false;
  bool _isEbookDownloadStale = false;
  final Map<String, Map<String, dynamic>> _narratorCache = {};
  final Set<String> _loadingNarratorIds = {};
  String? _audiobookPricingMode;
  String? _bookSlug;
  bool _isSubscribed = false;

  void _showSupportErrorDialog(String actionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  FFLocalizations.of(context).getVariableText(
                    enText: 'Error',
                    bnText: 'সমস্যাঃ',
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  FFLocalizations.of(context).getVariableText(
                    enText: 'This book is not prepared to $actionType. Please contact support or the administrator.',
                    bnText: 'এই বইটি $actionType করার জন্য প্রস্তুত নয়। অনুগ্রহ করে সহায়তা বা অ্যাডমিনের সাথে যোগাযোগ করুন।',
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 14.0,
                        lineHeight: 1.4,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          FFLocalizations.of(context).getVariableText(
                            enText: 'Close',
                            bnText: 'বন্ধ করুন',
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (FFAppState().isLogin) {
                            context.pushNamed(CreateTicketPageWidget.routeName);
                          } else {
                            context.pushNamed(SignInPageWidget.routeName);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: Text(
                          FFLocalizations.of(context).getVariableText(
                            enText: 'Support',
                            bnText: 'সহায়তা',
                          ),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkSubscriptionValidity() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      _isSubscribed = false;
      return;
    }
    try {
      final res = await EbookGroup.usersubscriptionvalidityApiCall.call(
        token: FFAppState().token,
      );
      if (res.succeeded) {
        final success = EbookGroup.usersubscriptionvalidityApiCall.success(res.jsonBody) == 1;
        final days = EbookGroup.usersubscriptionvalidityApiCall.daysLeft(res.jsonBody) ?? 0;
        _isSubscribed = success && days >= 0;
      } else {
        _isSubscribed = false;
      }
    } catch (_) {
      _isSubscribed = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BookDetailspageModel());
    if (widget.initialTab == 'audiobook') {
      _activeFormatTab = BookMasterFormatTab.audiobook;
    } else if (widget.initialTab == 'hardcopy') {
      _activeFormatTab = BookMasterFormatTab.hardcopy;
    } else {
      _activeFormatTab = BookMasterFormatTab.ebook;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bookId = (widget.id ?? '').trim();
      if (bookId.isNotEmpty) {
        _loadTracks(bookId);
      }
      if (FFAppState().isLogin) {
        await _checkSubscriptionValidity();
        await _checkIfPurchased();
        await _loadBookmarkStatus();
        await _refreshWalletCoinBalance();
        await _checkDownloadStatus();
      }
      safeSetState(() {});
    });
  }

  Future<void> _checkDownloadStatus() async {
    final bookId = (widget.id ?? '').trim();
    if (bookId.isEmpty) return;

    final d = await LocalDownloadService.getDownloadByBookId(bookId);
    if (d != null) {
      bool stale = false;
      try {
        String? liveUrl = await _fetchEbookSignedUrl(bookId);
        liveUrl ??= await _fetchEbookSignedUrlGuestAware(bookId);
        if (liveUrl != null && liveUrl.trim().isNotEmpty) {
          stale = await LocalDownloadService.isRemoteUrlChanged(
            bookId: bookId,
            newRemoteUrl: liveUrl,
          );
        }
      } catch (e) {
        debugPrint('Error checking download stale status: $e');
      }
      if (mounted) {
        safeSetState(() {
          _isEbookDownloaded = true;
          _isEbookDownloadStale = stale;
        });
      }
    } else {
      if (mounted) {
        safeSetState(() {
          _isEbookDownloaded = false;
          _isEbookDownloadStale = false;
        });
      }
    }
  }

  Future<void> _loadBookmarkStatus() async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) return;
    final bid = (widget.id ?? '').trim();
    if (bid.isEmpty) return;
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bid/bookmark');
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
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bid/bookmark');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({'bookmarked': target}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _model.isFavorite = target;
        await actions.showCustomToastBottom(
            target ? FFAppState().favText : FFAppState().unFavText);
      }
    } catch (_) {
    } finally {
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
              (format == 'ebook' ||
                  format == 'audiobook' ||
                  format == 'hardcopy')) {
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
    bool isPreviewMode = false,
    int previewPercent = 100,
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
          'isPreviewMode': serializeParam(isPreviewMode, ParamType.bool),
          'previewPercent': serializeParam(previewPercent, ParamType.int),
        }.withoutNulls,
      );
    } catch (e) {
      debugPrint('Open book failed: $e');
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to open book', bnText: 'বই খুলতে ব্যর্থ'));
    } finally {
      if (mounted) {
        safeSetState(() => _isOpeningReader = false);
      }
    }
  }

  Future<void> _loadNarratorsForIds(List<dynamic>? ids, Map<String, dynamic>? initialNarrator) async {
    if (initialNarrator != null) {
      final initId = initialNarrator['id']?.toString() ?? initialNarrator['_id']?.toString() ?? '';
      final initName = initialNarrator['name']?.toString() ?? '';
      final initImageRaw = initialNarrator['avatar_url']?.toString() ?? initialNarrator['image']?.toString() ?? '';
      final initImage = initImageRaw.isEmpty
          ? ''
          : (initImageRaw.startsWith('http')
              ? initImageRaw
              : '${FFAppConstants.imageUrl}$initImageRaw');
      if (initId.isNotEmpty && !_narratorCache.containsKey(initId)) {
        _narratorCache[initId] = {
          '_id': initId,
          'name': initName,
          'image': initImage,
        };
      }
    }

    if (ids == null || ids.isEmpty) return;
    final stringIds = ids.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    for (final id in stringIds) {
      if (_narratorCache.containsKey(id) || _loadingNarratorIds.contains(id)) {
        continue;
      }
      _loadingNarratorIds.add(id);
      EbookGroup.getnarratordetailsApiCall.call(narratorId: id).then((res) {
        _loadingNarratorIds.remove(id);
        if (res.succeeded && res.jsonBody != null) {
          final detailsList = getJsonField(res.jsonBody, r'''$.data.narratorDetails''');
          if (detailsList is List && detailsList.isNotEmpty) {
            final details = Map<String, dynamic>.from(detailsList.first);
            if (mounted) {
              safeSetState(() {
                _narratorCache[id] = details;
              });
            }
          }
        }
      }).catchError((_) {
        _loadingNarratorIds.remove(id);
      });
    }
  }

  Future<List<String>> _previewSeenBooks() async {
    final items = FFAppState().prefs.getStringList('ff_preview_seen_books');
    return items ?? <String>[];
  }

  Future<void> _markPreviewSeen(String bookId) async {
    final normalized = bookId.trim();
    if (normalized.isEmpty) return;
    final current = await _previewSeenBooks();
    if (current.contains(normalized)) return;
    await FFAppState().prefs
        .setStringList('ff_preview_seen_books', [...current, normalized]);
  }

  Future<bool> _hasSeenPreview(String bookId) async {
    final normalized = bookId.trim();
    if (normalized.isEmpty) return false;
    final current = await _previewSeenBooks();
    return current.contains(normalized);
  }

  List<Map<String, dynamic>> _formatsFromResponse(dynamic responseJson) {
    final raw =
        getJsonField(responseJson, r'''$.data.bookDetails[0].formats''');
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
    const defaultPercent = 15;
    final raw = format?['preview_percentage'];
    final v = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}') ?? 0;
    if (v <= 0) return defaultPercent;
    return v.clamp(1, 50); // never 0, never above 50%
  }

  bool _hasLocalFormatAccess({
    required String bookId,
    required String format,
    required bool isFree,
    required double price,
    bool subscriberAccess = false,
  }) {
    if (price <= 0) return true;
    if (subscriberAccess && _isSubscribed) return true;
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
      if (res.statusCode >= 400 && res.statusCode < 500) {
        final wasLoggedIn = FFAppState().isLogin;
        FFAppState().isLogin = false;
        FFAppState().token = '';
        FFAppState().refreshToken = '';
        FFAppState().favChange = false;
        FFAppState().bookId = '';
        FFAppState().homePageLiveReadBook = '';
        FFAppState().homePageCurrentPdfIndex = 1;
        FFAppState().searchList = [];
        FFAppState().userId = '';
        FFAppState().userDetail = null;
        FFAppState().update(() {});
        FFAppState().clearGetFavouriteBookCacheCache();
        if (mounted && wasLoggedIn) {
          context.pushNamed(SignInPageWidget.routeName);
        }
        return null;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<bool> _hasFormatAccess({
    required String bookId,
    required String format,
    bool subscriberAccess = false,
  }) async {
    if (!FFAppState().isLogin || FFAppState().token.trim().isEmpty) {
      return false;
    }
    final formatKey = '${bookId.toLowerCase()}::${format.toLowerCase().trim()}';
    if (_purchasedFormatKeys.contains(formatKey)) {
      return true;
    }
    if (subscriberAccess && _isSubscribed) {
      return true;
    }
    final body = await _postV2(
      'access/check',
      body: {'book_id': bookId, 'format': format},
      authRequired: true,
    );
    final isHardcopy = format.toLowerCase().trim() == 'hardcopy';
    if (isHardcopy) {
      if (body?['has_purchase'] == true) return true;
    } else {
      if (body?['has_access'] == true) return true;
    }
    await _checkIfPurchased();
    return _purchasedFormatKeys.contains(formatKey);
  }

  Future<String?> _fetchEbookSignedUrl(String bookId) async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({'book_id': bookId}),
      );
      if (res.statusCode == 401) {
        final wasLoggedIn = FFAppState().isLogin;
        FFAppState().isLogin = false;
        FFAppState().token = '';
        FFAppState().refreshToken = '';
        FFAppState().favChange = false;
        FFAppState().bookId = '';
        FFAppState().homePageLiveReadBook = '';
        FFAppState().homePageCurrentPdfIndex = 1;
        FFAppState().searchList = [];
        FFAppState().userId = '';
        FFAppState().userDetail = null;
        FFAppState().update(() {});
        FFAppState().clearGetFavouriteBookCacheCache();
        if (mounted && wasLoggedIn) {
          context.pushNamed(SignInPageWidget.routeName);
        }
        return null;
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        return null;
      }
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
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final guestRes = await http.post(
        uri,
        headers: _apiHeaders(authRequired: false),
        body: jsonEncode({'book_id': bookId}),
      );
      if (guestRes.statusCode == 401) {
        final wasLoggedIn = FFAppState().isLogin;
        FFAppState().isLogin = false;
        FFAppState().token = '';
        FFAppState().refreshToken = '';
        FFAppState().favChange = false;
        FFAppState().bookId = '';
        FFAppState().homePageLiveReadBook = '';
        FFAppState().homePageCurrentPdfIndex = 1;
        FFAppState().searchList = [];
        FFAppState().userId = '';
        FFAppState().userDetail = null;
        FFAppState().update(() {});
        FFAppState().clearGetFavouriteBookCacheCache();
        if (mounted && wasLoggedIn) {
          context.pushNamed(SignInPageWidget.routeName);
        }
        return null;
      } else if (guestRes.statusCode >= 400 && guestRes.statusCode < 500) {
        return null;
      }
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
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bookId/chapters');
      final res = await http.get(
        uri,
        headers: _apiHeaders(authRequired: FFAppState().isLogin),
      );
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const [];
      final raw = decoded['chapters'];
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
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Wallet unlock failed', bnText: 'ওয়ালেট আনলক ব্যর্থ হয়েছে'));
      return false;
    }
  }

  Future<void> _earnCoinsByWatchingAd(BuildContext context) async {
    final canShow = await AdManager.canShowAd();
    if (!canShow) {
      await actions.showCustomToastBottom(
          'Please wait 3 minutes between ads or daily limit of 20 ads reached.');
      return;
    }

    if (!AdManager.isAdLoaded) {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(
          enText: 'Loading Ad... Please wait a second.',
          bnText: 'বিজ্ঞাপন লোড হচ্ছে... অনুগ্রহ করে একটু অপেক্ষা করুন।'));
      final loaded = await AdManager.ensureAdLoaded();
      if (!loaded) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(
            enText: 'Failed to load ad. Please try again.',
            bnText: 'বিজ্ঞাপন লোড করতে ব্যর্থ। অনুগ্রহ করে আবার চেষ্টা করুন।'));
        return;
      }
    }

    AdManager.showRewardedAd(
      context: context,
      claimReward: true,
      onRewardEarned: () async {
        final res = await EbookGroup.walletClaimAdApiCall.call(
          token: FFAppState().token,
          placement: 'general',
        );
        final msg = EbookGroup.walletClaimAdApiCall.message(res.jsonBody) ?? 'Coins earned successfully!';
        await actions.showCustomToastBottom(msg);
        await _refreshWalletCoinBalance();
      },
      onAdFailed: () async {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(
            enText: 'Failed to show ad. Please try again.',
            bnText: 'বিজ্ঞাপন দেখাতে ব্যর্থ। অনুগ্রহ করে আবার চেষ্টা করুন।'));
      },
    );
  }

  Future<void> _showInsufficientCoinsDialog({
    required BuildContext context,
    required int requiredCoins,
    required int currentCoins,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                FFLocalizations.of(context).getVariableText(
                    enText: 'Insufficient Coins', bnText: 'কয়েন অপর্যাপ্ত'),
                style: FlutterFlowTheme.of(dialogContext).headlineSmall.override(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                FFLocalizations.of(context).getVariableText(
                  enText: 'You need $requiredCoins coins to unlock this content.\nYour current balance: $currentCoins coins.\n\nWatch a quick video ad to earn coins!',
                  bnText: 'এই কন্টেন্টটি আনলক করতে আপনার $requiredCoins কয়েন লাগবে।\nআপনার বর্তমান ব্যালেন্স: $currentCoins কয়েন।\n\nকয়েন অর্জন করতে একটি বিজ্ঞাপন দেখুন!',
                ),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(dialogContext).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      color: FlutterFlowTheme.of(dialogContext).secondaryText,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        FFLocalizations.of(context).getVariableText(
                            enText: 'Cancel', bnText: 'বাতিল'),
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          color: FlutterFlowTheme.of(dialogContext).secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _earnCoinsByWatchingAd(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(dialogContext).primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        FFLocalizations.of(context).getVariableText(
                            enText: 'Watch Ad', bnText: 'বিজ্ঞাপন দেখুন'),
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmAndUnlockWithCoins({
    required String bookName,
    required String bookId,
    required String format,
    required int coinCost,
  }) async {
    final balance = await _walletBalance();
    if (!mounted) return false;

    if (balance == null || balance < coinCost) {
      await _showInsufficientCoinsDialog(
        context: context,
        requiredCoins: coinCost,
        currentCoins: balance ?? 0,
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(FFLocalizations.of(context).getVariableText(enText: 'Unlock with Coins', bnText: 'কয়েন দিয়ে আনলক করুন')),
              content: Text(
                balance == null
                    ? FFLocalizations.of(context).getVariableText(enText: 'Unlock "$bookName" for $coinCost coins?', bnText: '"$bookName" আনলক করতে $coinCost কয়েন লাগবে?')
                    : FFLocalizations.of(context).getVariableText(enText: 'Unlock "$bookName" for $coinCost coins?\nYour balance: $balance', bnText: '"$bookName" আনলক করতে $coinCost কয়েন লাগবে?\nআপনার ব্যালেন্স: $balance'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Cancel', bnText: 'বাতিল করুন')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Unlock', bnText: 'আনলক করুন')),
                ),
              ],
            );
          },
        ) ?? false;
    if (!confirmed) return false;
    return _unlockWithCoins(bookId: bookId, format: format, coinCost: coinCost);
  }



  Future<void> _playAudiobookPreview({
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
  }) async {
    try {
      final uri = Uri.parse('https://boiaro.com/api/v1/books/$bookId');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to load preview metadata', bnText: 'প্রিভিউ মেটাডেটা লোড করতে ব্যর্থ'));
        return;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Invalid preview response', bnText: 'অবৈধ প্রিভিউ রেসপন্স'));
        return;
      }
      final formats = decoded['formats'];
      if (formats is! List) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Formats not found in book data', bnText: 'বইয়ের তথ্যে ফরম্যাট পাওয়া যায়নি'));
        return;
      }
      Map<String, dynamic>? audiobookFormat;
      for (final fmt in formats) {
        if (fmt is Map && fmt['format'] == 'audiobook') {
          audiobookFormat = Map<String, dynamic>.from(fmt);
          break;
        }
      }
      if (audiobookFormat == null) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Audiobook format details not found', bnText: 'অডিওবুক ফরম্যাটের বিবরণ পাওয়া যায়নি'));
        return;
      }
      final previewPercent = (audiobookFormat['preview_percentage'] as num?)?.toInt() ?? 15;
      final tracks = audiobookFormat['audiobook_tracks'];
      if (tracks is! List || tracks.isEmpty) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'No preview tracks available', bnText: 'কোনো প্রিভিউ ট্র্যাক উপলব্ধ নেই'));
        return;
      }
      final firstTrack = Map<String, dynamic>.from(tracks.first);
      final audioUrl = firstTrack['audio_url']?.toString() ?? '';
      if (audioUrl.isEmpty) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Preview audio file not found', bnText: 'প্রিভিউ অডিও ফাইল পাওয়া যায়নি'));
        return;
      }

      await _markPreviewSeen(bookId);

      await actions.showCustomToastBottom(
          'Preview limit: $previewPercent%. Buy or unlock to listen full audiobook.');

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
            'chapters': [
              {
                'title': firstTrack['title']?.toString() ?? 'Preview - Chapter 1',
                'file': audioUrl,
                'track_number': 1,
                'duration': firstTrack['duration']?.toString() ?? '',
                'isLocked': false,
                'isPreview': true,
                'previewFraction': 1.0,
                'raw': firstTrack,
              }
            ],
            'isPreviewMode': true,
            'previewPercent': previewPercent,
            'isFree': false,
            'initialTrackNumber': 1,
          },
          'chapter': {
            'title': firstTrack['title']?.toString() ?? 'Preview - Chapter 1',
            'file': audioUrl,
            'track_number': 1,
            'duration': firstTrack['duration']?.toString() ?? '',
            'isLocked': false,
            'isPreview': true,
            'previewFraction': 1.0,
            'raw': firstTrack,
          },
        },
      );
    } catch (e) {
      debugPrint('Error starting preview playback: $e');
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to load preview', bnText: 'প্রিভিউ লোড করতে ব্যর্থ'));
    }
  }



  Future<bool> _openAudiobookPlayerFromV2({
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool hasFullAccess,
    int previewPercent = 15,
    bool forceIsPreviewMode = false,
    int? initialTrackNumber,
    bool isFree = false,
    Map<String, dynamic>? audiobookFormat,
  }) async {
    debugPrint('[Audiobook V2] _openAudiobookPlayerFromV2 called');
    debugPrint('  - bookId: $bookId');
    debugPrint('  - bookName: $bookName');
    debugPrint('  - hasFullAccess: $hasFullAccess');
    debugPrint('  - previewPercent: $previewPercent');
    debugPrint('  - forceIsPreviewMode: $forceIsPreviewMode');
    debugPrint('  - initialTrackNumber: $initialTrackNumber');
    debugPrint('  - isFree: $isFree');
    debugPrint('  - audiobookFormat: ${audiobookFormat != null ? "Not Null" : "Null"}');

    if (!FFAppState().isLogin) {
      context.pushNamed(SignInPageWidget.routeName);
      return false;
    }
    final tracks = await _fetchAudioTracks(bookId);
    debugPrint('[Audiobook V2] Fetched ${tracks.length} tracks from chapters API');
    final effectiveTracks = List<Map<String, dynamic>>.from(tracks);
    if (effectiveTracks.isEmpty) {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'No tracks available', bnText: 'কোনো ট্র্যাক উপলব্ধ নেই'));
      return false;
    }

    final chapters = <Map<String, dynamic>>[];

    for (var i = 0; i < effectiveTracks.length; i++) {
      final track = effectiveTracks[i];
      final isFreeTrack = track['is_free'] == true || track['is_preview'] == true;
      final isUnlocked = track['is_unlocked'] == true;
      final isLocked = !hasFullAccess && !isFreeTrack && !isUnlocked;

      final trackNumber = (track['track_number'] is num)
          ? (track['track_number'] as num).toInt()
          : (i + 1);

      final signedUrl = track['audio_url']?.toString() ?? track['file']?.toString() ?? track['signed_url']?.toString() ?? '';

      if (signedUrl.isEmpty && !isLocked) {
        debugPrint('[Audiobook V2] Track $trackNumber has empty URL and is not locked. Skipping.');
        continue;
      }

      debugPrint('[Audiobook V2] Adding chapter $trackNumber: title="${track['title']}", file="$signedUrl", isLocked=$isLocked, isPreview=$isFreeTrack');

      chapters.add({
        'title': track['title']?.toString() ?? 'Track $trackNumber',
        'file': signedUrl,
        'track_number': trackNumber,
        'duration': track['duration']?.toString() ?? '',
        'isLocked': isLocked,
        'isPreview': isFreeTrack,
        'previewFraction': 1.0,
        'raw': track,
      });
    }

    if (chapters.isEmpty) {
      _showSupportErrorDialog('listen');
      return false;
    }

    final isPreviewMode = forceIsPreviewMode;

    if (isPreviewMode) {
      await actions.showCustomToastBottom(
          'Preview limit: $previewPercent%. Buy or unlock to listen full audiobook.');
    }

    final initialChapter = initialTrackNumber != null
        ? chapters.firstWhere(
            (ch) => ch['track_number'].toString() == initialTrackNumber.toString(),
            orElse: () => chapters.first,
          )
        : chapters.first;

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
          'slug': _bookSlug ?? '',
          'book_slug': _bookSlug ?? '',
          'chapters': chapters,
          'isPreviewMode': isPreviewMode,
          'previewPercent': previewPercent,
          'isFree': isFree,
          'initialTrackNumber': initialTrackNumber,
        },
        'chapter': initialChapter,
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

    if (Platform.isIOS && type != 'hardcopy') {
      final theme = FlutterFlowTheme.of(context);
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding: MediaQuery.viewInsetsOf(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    FFLocalizations.of(context).getVariableText(enText: 'Unlock Full Book', bnText: 'সম্পূর্ণ বই আনলক করুন'),
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${FFLocalizations.of(context).getVariableText(enText: 'Unlock', bnText: 'আনলক করুন')} "$bookName" ($type) ${FFLocalizations.of(context).getVariableText(enText: 'using Apple Pay.', bnText: 'অ্যাপল পে ব্যবহার করে।')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primaryText.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: theme.primaryText, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            FFLocalizations.of(context).getVariableText(enText: 'Pay with Apple IAP', bnText: 'অ্যাপল পে দিয়ে পে করুন'),
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      FFLocalizations.of(context).getVariableText(enText: 'Cancel', bnText: 'বাতিল করুন'),
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );

      if (confirm == true) {
        await RevenueCatService.initialize();
        final productId = RevenueCatService.getProductIdForBdtPrice(price);
        final purchaseResult = await RevenueCatService.purchaseChapter(productId);
        
        if (purchaseResult['success'] == true) {
          final transactionId = purchaseResult['transactionId'];
          final res = await EbookGroup.unlockBookWithIAPCall.call(
            bookId: bookId,
            transactionId: transactionId,
            productId: productId,
            format: type,
            token: FFAppState().token,
          );

          if (res.statusCode == 200 || res.succeeded) {
            await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Book unlocked successfully!', bnText: 'বইটি সফলভাবে আনলক করা হয়েছে!'));
            _purchasedFormatKeys.add('${bookId.toLowerCase()}::${type.toLowerCase().trim()}');
            if (!_model.purchasedBookIds.contains(bookId)) {
              _model.purchasedBookIds.add(bookId);
            }
            safeSetState(() {});
          } else {
            final msg = getJsonField(res.jsonBody, r'''$.error''') ?? 
                        getJsonField(res.jsonBody, r'''$.message''') ?? 'Unlock verification failed';
            await actions.showCustomToastBottom(msg.toString());
          }
        } else {
          final error = purchaseResult['errorMessage'];
          if (error != null) {
            await actions.showCustomToastBottom(error);
          }
        }
      }
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

  void _addToCartOnly({
    required String bookId,
    required String bookName,
    required String bookImage,
    required double price,
    required String type,
    required int? coinPrice,
  }) {
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
    actions.showCustomToastBottom(
      FFLocalizations.of(context).getVariableText(
        enText: 'Added to cart successfully',
        bnText: 'সফলভাবে কার্টে যোগ করা হয়েছে',
      ),
    );
  }

  Future<void> _handleBuyNow({
    required BookMasterFormatTab tab,
    required String bookId,
    required String bookName,
    required String bookImage,
    required Map<String, dynamic>? ebookFormat,
    required Map<String, dynamic>? audiobookFormat,
    required Map<String, dynamic>? hardcopyFormat,
  }) async {
    if (tab == BookMasterFormatTab.ebook) {
      if (ebookFormat == null || ebookFormat['is_available'] == false) {
        await actions.showCustomToastBottom(
            'eBook format is not available for this book');
        return;
      }
      await _addToCartAndCheckout(
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        price: _formatPrice(ebookFormat),
        type: 'ebook',
        coinPrice: _formatCoinPrice(ebookFormat) > 0
            ? _formatCoinPrice(ebookFormat)
            : null,
      );
      return;
    }

    if (tab == BookMasterFormatTab.audiobook) {
      if (audiobookFormat == null || audiobookFormat['is_available'] == false) {
        await actions.showCustomToastBottom(
            'Audiobook format is not available for this book');
        return;
      }
      await _addToCartAndCheckout(
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        price: _formatPrice(audiobookFormat),
        type: 'audiobook',
        coinPrice: _formatCoinPrice(audiobookFormat) > 0
            ? _formatCoinPrice(audiobookFormat)
            : null,
      );
      return;
    }

    if (hardcopyFormat == null || hardcopyFormat['is_available'] == false) {
      await actions.showCustomToastBottom(
          'Hardcopy format is not available for this book');
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
    bool forcePreview = false,
  }) async {
    if (tab == BookMasterFormatTab.ebook || tab == BookMasterFormatTab.audiobook) {
      if (!FFAppState().isLogin) {
        context.pushNamed(SignInPageWidget.routeName);
        return;
      }
    }
    // --- FORCE PREVIEW: always open in preview mode, ignore purchase status ---
    // Uses the same URL/tracks as Read Now but enforces the preview % limit
    // on the client (native epub reader / audio player).
    if (forcePreview) {
      if (tab == BookMasterFormatTab.ebook) {
        if (ebookFormat == null || ebookFormat['is_available'] == false) {
          await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'eBook format is not available', bnText: 'ই-বুক ফরম্যাট উপলব্ধ নয়'));
          return;
        }
        final safePercent = _previewPercent(ebookFormat); // 1–50, default 15

        // Fetch URL exactly the same way Read Now does
        String? url;
        if (FFAppState().isLogin) {
          url = await _fetchEbookSignedUrl(bookId);
        }
        url ??= await _fetchEbookSignedUrlGuestAware(bookId);
        url ??= _extractEbookUrlFromDetails(responseJson);

        if (url == null || url.trim().isEmpty) {
          _showSupportErrorDialog('preview');
          return;
        }
        await _markPreviewSeen(bookId);
        await _openBook(
          path: url,
          bookName: '$bookName (Preview)',
          bookImage: bookImage,
          authorName: authorName,
          isPreviewMode: true,
          previewPercent: safePercent,
        );
        return;
      }
      if (tab == BookMasterFormatTab.audiobook) {
        if (audiobookFormat == null ||
            audiobookFormat['is_available'] == false) {
          await actions
              .showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Audiobook format is not available', bnText: 'অডিওবুক ফরম্যাট উপলব্ধ নয়'));
          return;
        }
        final safePercent = _previewPercent(audiobookFormat);
        // hasFullAccess=true fetches authenticated track URLs (same as Listen Now)
        // isPreviewMode is forced true so the player enforces the limit
        await _playAudiobookPreview(
          bookId: bookId,
          bookName: bookName,
          bookImage: bookImage,
          authorName: authorName,
        );
        return;
      }
    }
    // -------------------------------------------------------------------------

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
          ? await _hasFormatAccess(
              bookId: bookId,
              format: 'ebook',
              subscriberAccess: (getJsonField(responseJson, r'''$.data.bookDetails[0].subscriber_access''') == true) || (ebookFormat?['subscriber_access'] == true),
            )
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

      if (hasAccess) {
        if (url == null || url.trim().isEmpty) {
          _showSupportErrorDialog('read');
          return;
        }
        final finalUrl = url;
        void performRead() async {
          await _openBook(
            path: finalUrl,
            bookName: bookName,
            bookImage: bookImage,
            authorName: authorName,
          );
        }

        final isAlreadyPurchased = FFAppState().isLogin &&
            _purchasedFormatKeys.contains('${bookId.toLowerCase()}::ebook');
        if (isEbookFree && !isAlreadyPurchased) {
          final canShowAd = await AdManager.canShowAd();
          if (canShowAd) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => custom_widgets.AdRewardDialog(
                bookImage: bookImage,
                onWatchAd: performRead,
                adType: 'rewarded_interstitial',
                claimReward: false,
              ),
            );
          } else {
            performRead();
          }
        } else {
          performRead();
        }
        return;
      }

      if (_lastEbookAuthError) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Please login to read this ebook', bnText: 'এই ই-বুকটি পড়তে অনুগ্রহ করে লগইন করুন'));
        context.pushNamed(SignInPageWidget.routeName);
        return;
      }
      final previewUrl =
          _extractEbookPreviewUrlFromDetails(responseJson) ?? url;
      if (previewUrl != null && previewUrl.trim().isNotEmpty) {
        await _openBook(
          path: previewUrl,
          bookName: '$bookName (Preview)',
          bookImage: bookImage,
          authorName: authorName,
          isPreviewMode: true,
          previewPercent: ebookPreviewPercent,
        );
        return;
      }

      if (!FFAppState().isLogin) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Sign in to buy/read this ebook', bnText: 'এই ই-বুকটি কিনতে/পড়তে সাইন ইন করুন'));
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
          _showSupportErrorDialog('read');
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
      final audiobookPreviewPercent = _previewPercent(audiobookFormat);
      final isAudiobookFree = _audiobookPricingMode == 'per_chapter'
          ? false
          : (isBookFree || audiobookPrice <= 0);
      final hasAccessByApi = FFAppState().isLogin &&
          await _hasFormatAccess(
            bookId: bookId,
            format: 'audiobook',
            subscriberAccess: (getJsonField(responseJson, r'''$.data.bookDetails[0].subscriber_access''') == true) || (audiobookFormat?['subscriber_access'] == true),
          );
      final hasAccess = isAudiobookFree || hasAccessByApi;
      if (hasAccess) {
        final performPlay = () async {
          final opened = await _openAudiobookPlayerFromV2(
            bookId: bookId,
            bookName: bookName,
            bookImage: bookImage,
            authorName: authorName,
            hasFullAccess: hasAccess,
            previewPercent: audiobookPreviewPercent,
            isFree: isAudiobookFree,
            audiobookFormat: audiobookFormat,
          );
          if (!opened && !FFAppState().isLogin && !isAudiobookFree) {
            context.pushNamed(SignInPageWidget.routeName);
          }
        };

        final isAlreadyPurchased = FFAppState().isLogin &&
            _purchasedFormatKeys.contains('${bookId.toLowerCase()}::audiobook');
        if (isAudiobookFree && !isAlreadyPurchased) {
          final canShowAd = await AdManager.canShowAd();
          if (canShowAd) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => custom_widgets.AdRewardDialog(
                bookImage: bookImage,
                onWatchAd: performPlay,
                adType: 'rewarded_interstitial',
                claimReward: false,
              ),
            );
          } else {
            await performPlay();
          }
        } else {
          await performPlay();
        }
        return;
      }
      await _playAudiobookPreview(
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        authorName: authorName,
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
    bool subscriberAccess = false,
  }) async {
    if (_isDownloadingEbook) return;
    if (!FFAppState().isLogin) {
      await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Sign in to download', bnText: 'ডাউনলোড করতে সাইন ইন করুন'));
      context.pushNamed(SignInPageWidget.routeName);
      return;
    }
    safeSetState(() => _isDownloadingEbook = true);
    final hasAccess =
        isBookFree || await _hasFormatAccess(bookId: bookId, format: 'ebook', subscriberAccess: subscriberAccess);
    safeSetState(() => _isDownloadingEbook = false);

    if (!hasAccess) {
      await actions
          .showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Buy or unlock ebook before download', bnText: 'ডাউনলোড করার আগে ই-বুকটি কিনুন বা আনলক করুন'));
      return;
    }

    void performDownload() async {
      safeSetState(() => _isDownloadingEbook = true);
      try {
        String? url = await _fetchEbookSignedUrl(bookId);
        url ??= await _fetchEbookSignedUrlGuestAware(bookId);
        if (url == null || url.trim().isEmpty) {
          _showSupportErrorDialog('download');
          return;
        }
        await LocalDownloadService.downloadBook(
          bookId: bookId,
          name: bookName,
          image: bookImage,
          author: authorName,
          remoteUrl: url,
        );
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Book downloaded successfully', bnText: 'বইটি সফলভাবে ডাউনলোড করা হয়েছে'));
        await _checkDownloadStatus();
      } catch (_) {
        await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Download failed', bnText: 'ডাউনলোড ব্যর্থ হয়েছে'));
      } finally {
        if (mounted) safeSetState(() => _isDownloadingEbook = false);
      }
    }

    final isAlreadyPurchased = FFAppState().isLogin &&
        _purchasedFormatKeys.contains('${bookId.toLowerCase()}::ebook');
    if (isBookFree && !isAlreadyPurchased) {
      final canShowAd = await AdManager.canShowAd();
      if (canShowAd) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => custom_widgets.AdRewardDialog(
            bookImage: bookImage,
            onWatchAd: performDownload,
            adType: 'rewarded',
            claimReward: false,
          ),
        );
      } else {
        performDownload();
      }
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
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bookId/chapters');
      final res =
          await http.get(uri, headers: _apiHeaders(authRequired: FFAppState().isLogin));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map?;
        final pricingMode = body?['pricing_mode']?.toString();
        final raw = body?['chapters'];
        if (raw is List) {
          final parsed = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (mounted) {
            safeSetState(() {
              _tracks = parsed;
              _audiobookPricingMode = pricingMode;
            });
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

  // ─────────────────────────────────────────────────────────────────────────
  // Episode card builder — premium design
  // ─────────────────────────────────────────────────────────────────────────
  static const int _episodePreviewLimit = 3;

  Widget _buildEpisodeCard({
    required Map<String, dynamic> track,
    required int index,
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool isBookFree,
    required List<Map<String, dynamic>> formats,
    required bool hasAudiobookAccess,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final audiobookFormat =
        _pickFormat(formats.cast<Map<String, dynamic>>(), 'audiobook');
    final isAlreadyPurchased = FFAppState().isLogin &&
        _purchasedFormatKeys.contains('${bookId.toLowerCase()}::audiobook');

    final isFree = track['is_free'] == true;
    final isUnlocked = track['is_unlocked'] == true;
    final isLocked = !hasAudiobookAccess && !isFree && !isUnlocked;
    final trackNum = track['track_number'];
    final title = track['title']?.toString() ?? 'Episode ${index + 1}';
    final dur = track['duration']?.toString() ?? '';

    Future<void> handlePlay() async {
      if (!FFAppState().isLogin) {
        context.pushNamed(SignInPageWidget.routeName);
        return;
      }
      if (!isLocked) {
        final audiobookFormat =
            _pickFormat(formats.cast<Map<String, dynamic>>(), 'audiobook');

        final audiobookPreviewPercent = audiobookFormat != null ? _previewPercent(audiobookFormat) : 15;
        final performPlay = () async {
          await _openAudiobookPlayerFromV2(
            bookId: bookId,
            bookName: bookName,
            bookImage: bookImage,
            authorName: authorName,
            hasFullAccess: hasAudiobookAccess,
            previewPercent: audiobookPreviewPercent,
            initialTrackNumber: trackNum,
            isFree: isFree,
            audiobookFormat: audiobookFormat,
          );
        };

        final isEpisodeFree = isFree || track['is_preview'] == true;
        if (isEpisodeFree && !isAlreadyPurchased && !_isSubscribed) {
          final canShowAd = await AdManager.canShowAd();
          if (canShowAd) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => custom_widgets.AdRewardDialog(
                bookImage: bookImage,
                onWatchAd: performPlay,
                adType: 'rewarded',
                claimReward: false,
              ),
            );
          } else {
            await performPlay();
          }
        } else {
          await performPlay();
        }
      } else {
        if (!FFAppState().isLogin) {
          context.pushNamed(SignInPageWidget.routeName);
          return;
        }

        final trackId = track['id'] ?? track['_id'] ?? '';
        final coinPrice = (track['chapter_price_coins'] as num?)?.toInt() ?? 0;
        final bdtPrice = (track['chapter_price_bdt'] as num?)?.toDouble() ?? 0.0;

        if (trackId.toString().isEmpty) {
          await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Unable to unlock: invalid chapter ID', bnText: 'আনলক করতে ব্যর্থ: অবৈধ অধ্যায় আইডি'));
          return;
        }

        final option = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final theme = FlutterFlowTheme.of(ctx);
            final brandColor = theme.primary;
            
            Widget buildUnlockOptionCard({
              required IconData icon,
              required Color iconColor,
              required String label,
              required String value,
              required VoidCallback onTap,
            }) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.alternate.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: brandColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.alternate.withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: brandColor.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: brandColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_open_rounded,
                                color: brandColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              FFLocalizations.of(context).getVariableText(enText: 'Unlock Chapter', bnText: 'অধ্যায় আনলক করুন'),
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 13,
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (coinPrice <= 0 && bdtPrice <= 0) ...[
                              buildUnlockOptionCard(
                                icon: Icons.shopping_bag_rounded,
                                iconColor: theme.primary,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Buy Full Book', bnText: 'সম্পূর্ণ বইটি কিনুন'),
                                value: FFLocalizations.of(context).getVariableText(enText: 'Buy Now', bnText: 'এখনই কিনুন'),
                                onTap: () => Navigator.of(ctx).pop('buy_full_book'),
                              ),
                              const SizedBox(height: 12),
                            ] else if (Platform.isIOS) ...[
                              buildUnlockOptionCard(
                                icon: Icons.apple,
                                iconColor: theme.primaryText,
                                label: FFLocalizations.of(context).getVariableText(enText: 'Unlock with Apple Pay', bnText: 'অ্যাপল পে দিয়ে আনলক করুন'),
                                value: FFLocalizations.of(context).getVariableText(enText: 'Apple IAP', bnText: 'অ্যাপল ইন-অ্যাপ পারচেস'),
                                onTap: () => Navigator.of(ctx).pop('apple_iap'),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              if (coinPrice > 0) ...[
                                buildUnlockOptionCard(
                                  icon: Icons.monetization_on_rounded,
                                  iconColor: const Color(0xFFFFB03A),
                                  label: FFLocalizations.of(context).getVariableText(enText: 'Use Coins', bnText: 'কয়েন ব্যবহার করুন'),
                                  value: '$coinPrice ' + FFLocalizations.of(context).getVariableText(enText: 'Coins', bnText: 'কয়েন'),
                                  onTap: () => Navigator.of(ctx).pop('coins'),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (bdtPrice > 0) ...[
                                buildUnlockOptionCard(
                                  icon: Icons.account_balance_wallet_rounded,
                                  iconColor: const Color(0xFF2EC4B6),
                                  label: FFLocalizations.of(context).getVariableText(enText: 'Pay with Cash', bnText: 'ক্যাশ পে করুন'),
                                  value: '৳${bdtPrice.toStringAsFixed(0)}',
                                  onTap: () => Navigator.of(ctx).pop('payment'),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => Navigator.of(ctx).pop('cancel'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  FFLocalizations.of(context).getVariableText(enText: 'Cancel', bnText: 'বাতিল করুন'),
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (option == 'apple_iap') {
          final productId = RevenueCatService.getProductIdForCoinCost(coinPrice);
          final purchaseResult = await RevenueCatService.purchaseChapter(productId);
          
          if (purchaseResult['success'] == true) {
            final transactionId = purchaseResult['transactionId'];
            
            final res = await EbookGroup.unlockChapterWithIAPCall.call(
              trackId: trackId.toString(),
              bookId: bookId,
              transactionId: transactionId,
              productId: productId,
              token: FFAppState().token,
            );

            if (res.statusCode == 200 || res.succeeded) {
              await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Chapter unlocked successfully!', bnText: 'অধ্যায় সফলভাবে আনলক করা হয়েছে!'));
              _tracks = null;
              await _checkIfPurchased();
              safeSetState(() {});
            } else {
              final msg = getJsonField(res.jsonBody, r'''$.error''') ?? 
                          getJsonField(res.jsonBody, r'''$.message''') ?? 'Unlock verification failed';
              await actions.showCustomToastBottom(msg.toString());
            }
          } else {
            final error = purchaseResult['errorMessage'];
            if (error != null) {
              await actions.showCustomToastBottom(error);
            }
          }
        } else if (option == 'coins') {
          final balance = await _walletBalance();
          if (balance == null || balance < coinPrice) {
            await _showInsufficientCoinsDialog(
              context: context,
              requiredCoins: coinPrice,
              currentCoins: balance ?? 0,
            );
            return;
          }
          final res = await EbookGroup.unlockChapterWithCoinsCall.call(
            trackId: trackId.toString(),
            token: FFAppState().token,
          );
          if (res.statusCode == 200 || res.succeeded) {
            await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Chapter unlocked successfully!', bnText: 'অধ্যায় সফলভাবে আনলক করা হয়েছে!'));
            _tracks = null;
            safeSetState(() {});
          } else {
            final msg = getJsonField(res.jsonBody, r'''$.message''') ?? 'Unlock failed';
            await actions.showCustomToastBottom(msg.toString());
          }
        } else if (option == 'payment') {
          final res = await EbookGroup.initiateChapterPaymentCall.call(
            trackId: trackId.toString(),
            bookId: bookId,
            token: FFAppState().token,
          );
          if (res.succeeded && res.jsonBody != null) {
            final gatewayUrl = getJsonField(res.jsonBody, r'''$.gateway_url''')?.toString() ??
                getJsonField(res.jsonBody, r'''$.GatewayPageURL''')?.toString() ?? '';
            final purchaseId = getJsonField(res.jsonBody, r'''$.purchase_id''')?.toString() ??
                getJsonField(res.jsonBody, r'''$.order_id''')?.toString() ?? '';
            if (gatewayUrl.isNotEmpty) {
              final success = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentWebView(
                    url: gatewayUrl,
                    orderId: purchaseId,
                    bookIds: [bookId],
                    purchasedFormats: ['audiobook'],
                    checkoutController: CheckoutController(
                      jwtToken: FFAppState().token,
                      userId: FFAppState().userId,
                    ),
                    isChapterUnlock: true,
                  ),
                ),
              );
              if (success == true || success == null) {
                _tracks = null;
                await _checkIfPurchased();
                safeSetState(() {});
              }
            } else {
              await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to get gateway URL', bnText: 'গেটওয়ে ইউআরএল পেতে ব্যর্থ'));
            }
          } else {
            await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to initiate payment', bnText: 'পেমেন্ট শুরু করতে ব্যর্থ'));
          }
        } else if (option == 'buy_full_book') {
          await _handleBuyNow(
            tab: BookMasterFormatTab.audiobook,
            bookId: bookId,
            bookName: bookName,
            bookImage: bookImage,
            ebookFormat: _pickFormat(formats.cast<Map<String, dynamic>>(), 'ebook'),
            audiobookFormat: audiobookFormat,
            hardcopyFormat: _pickFormat(formats.cast<Map<String, dynamic>>(), 'hardcopy'),
          );
        }
      }
    }

    return _AnimatedEpisodeCard(
      key: ValueKey('ep_$index'),
      track: track,
      index: index,
      theme: theme,
      isDark: isDark,
      isPreview: isFree,
      isLocked: isLocked,
      num: num,
      title: title,
      dur: dur,
      onTap: handlePlay,
    );
  }

  Widget _buildEpisodesInAudioTab({
    required String bookId,
    required List<Map<String, dynamic>> formats,
    required String bookName,
    required String bookImage,
    required String authorName,
    required bool isBookFree,
    required bool hasAudiobookAccess,
  }) {
    // Trigger load on first render.
    if (_tracks == null && !_tracksLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTracks(bookId));
    }
    final theme = FlutterFlowTheme.of(context);
    final tracks = _tracks ?? [];
    final trackCount = tracks.length;
    final showSeeMore = trackCount > _episodePreviewLimit;
    final displayTracks =
        showSeeMore ? tracks.take(_episodePreviewLimit).toList() : tracks;
    final isAlreadyPurchased = FFAppState().isLogin &&
        _purchasedFormatKeys.contains('${bookId.toLowerCase()}::audiobook');
    final audiobookFormat =
        _pickFormat(formats.cast<Map<String, dynamic>>(), 'audiobook');

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tracksLoading
                    ? FFLocalizations.of(context).getVariableText(enText: 'Episodes', bnText: 'পর্বসমূহ')
                    : '${FFLocalizations.of(context).getVariableText(enText: 'Episodes', bnText: 'পর্বসমূহ')}${trackCount > 0 ? ' ($trackCount)' : ''}',
                style: theme.bodyMedium.override(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
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
                      valueColor:
                          AlwaysStoppedAnimation(theme.primary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Empty state ─────────────────────────────────────────────────
          if (!_tracksLoading && trackCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.secondaryText.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_off_outlined,
                    size: 36,
                    color: theme.secondaryText.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FFLocalizations.of(context).getVariableText(enText: 'No episodes available.', bnText: 'কোনো পর্ব উপলব্ধ নেই।'),
                    style: theme.bodySmall.override(
                      fontFamily: 'SF Pro Display',
                      color: theme.secondaryText,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

          // ── Episode cards ───────────────────────────────────────────────
          ...displayTracks.asMap().entries.map((entry) {
            return _buildEpisodeCard(
              track: entry.value,
              index: entry.key,
              bookId: bookId,
              bookName: bookName,
              bookImage: bookImage,
              authorName: authorName,
              isBookFree: isBookFree,
              formats: formats,
              hasAudiobookAccess: hasAudiobookAccess,
            );
          }),

          // ── See More button ─────────────────────────────────────────────
          if (showSeeMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _SeeMoreButton(
                remaining: trackCount - _episodePreviewLimit,
                onTap: () {
                  if (!FFAppState().isLogin) {
                    context.pushNamed(SignInPageWidget.routeName);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _EpisodesListPage(
                        bookName: bookName,
                        bookImage: bookImage,
                        tracks: tracks,
                        hasAudiobookAccess: hasAudiobookAccess,
                        audiobookFormat: audiobookFormat,
                        onPlayTrack: (track) async {
                          if (!FFAppState().isLogin) {
                            context.pushNamed(SignInPageWidget.routeName);
                            return;
                          }
                          final isFree = track['is_free'] == true;
                          final isUnlocked = track['is_unlocked'] == true;
                          final isLocked = !hasAudiobookAccess && !isFree && !isUnlocked;

                          if (!isLocked) {

                            final audiobookPreviewPercent = audiobookFormat != null
                                ? _previewPercent(audiobookFormat)
                                : 15;
                            final performPlay = () async {
                              await _openAudiobookPlayerFromV2(
                                bookId: bookId,
                                bookName: bookName,
                                bookImage: bookImage,
                                authorName: authorName,
                                hasFullAccess: hasAudiobookAccess,
                                previewPercent: audiobookPreviewPercent,
                                initialTrackNumber: track['track_number'],
                                isFree: isFree,
                                audiobookFormat: audiobookFormat,
                              );
                            };

                            final isEpisodeFree = isFree || track['is_preview'] == true;
                            if (isEpisodeFree && !isAlreadyPurchased && !_isSubscribed) {
                              final canShowAd = await AdManager.canShowAd();
                              if (canShowAd) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => custom_widgets.AdRewardDialog(
                                    bookImage: bookImage,
                                    onWatchAd: performPlay,
                                    adType: 'rewarded',
                                    claimReward: false,
                                  ),
                                );
                              } else {
                                await performPlay();
                              }
                            } else {
                              await performPlay();
                            }
                          } else {
                            if (!FFAppState().isLogin) {
                              context.pushNamed(SignInPageWidget.routeName);
                              return;
                            }
                            final trackId = track['id'] ?? track['_id'] ?? '';
                            final coinPrice = (track['chapter_price_coins'] as num?)?.toInt() ?? 0;
                            final bdtPrice = (track['chapter_price_bdt'] as num?)?.toDouble() ?? 0.0;
                            final title = track['title']?.toString() ?? 'Episode';

                            if (trackId.toString().isEmpty) {
                              await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Unable to unlock: invalid chapter ID', bnText: 'আনলক করতে ব্যর্থ: অবৈধ অধ্যায় আইডি'));
                              return;
                            }

                            final option = await showDialog<String>(
                              context: context,
                              builder: (ctx) {
                                final theme = FlutterFlowTheme.of(ctx);
                                final brandColor = theme.primary;
                                
                                Widget buildUnlockOptionCard({
                                  required IconData icon,
                                  required Color iconColor,
                                  required String label,
                                  required String value,
                                  required VoidCallback onTap,
                                }) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onTap,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: theme.secondaryBackground,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: theme.alternate.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                icon,
                                                color: iconColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primaryText,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: brandColor.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: brandColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 340),
                                    decoration: BoxDecoration(
                                      color: theme.secondaryBackground,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: theme.alternate.withOpacity(0.4),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: -50,
                                            right: -50,
                                            child: Container(
                                              width: 130,
                                              height: 130,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: brandColor.withOpacity(0.08),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 54,
                                                  height: 54,
                                                  decoration: BoxDecoration(
                                                    color: brandColor.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.lock_open_rounded,
                                                    color: brandColor,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  FFLocalizations.of(context).getVariableText(enText: 'Unlock Chapter', bnText: 'অধ্যায় আনলক করুন'),
                                                  style: TextStyle(
                                                    fontFamily: 'SF Pro Display',
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.primaryText,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  title,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'SF Pro Display',
                                                    fontSize: 13,
                                                    color: theme.secondaryText,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                if (coinPrice <= 0 && bdtPrice <= 0) ...[
                                                  buildUnlockOptionCard(
                                                    icon: Icons.shopping_bag_rounded,
                                                    iconColor: theme.primary,
                                                    label: FFLocalizations.of(context).getVariableText(enText: 'Buy Full Book', bnText: 'সম্পূর্ণ বইটি কিনুন'),
                                                    value: FFLocalizations.of(context).getVariableText(enText: 'Buy Now', bnText: 'এখনই কিনুন'),
                                                    onTap: () => Navigator.of(ctx).pop('buy_full_book'),
                                                  ),
                                                  const SizedBox(height: 12),
                                                ] else if (Platform.isIOS) ...[
                                                  buildUnlockOptionCard(
                                                    icon: Icons.apple,
                                                    iconColor: theme.primaryText,
                                                    label: FFLocalizations.of(context).getVariableText(enText: 'Unlock with Apple Pay', bnText: 'অ্যাপল পে দিয়ে আনলক করুন'),
                                                    value: FFLocalizations.of(context).getVariableText(enText: 'Apple IAP', bnText: 'অ্যাপল ইন-অ্যাপ পারচেস'),
                                                    onTap: () => Navigator.of(ctx).pop('apple_iap'),
                                                  ),
                                                  const SizedBox(height: 12),
                                                ] else ...[
                                                  if (coinPrice > 0) ...[
                                                    buildUnlockOptionCard(
                                                      icon: Icons.monetization_on_rounded,
                                                      iconColor: const Color(0xFFFFB03A),
                                                      label: FFLocalizations.of(context).getVariableText(enText: 'Use Coins', bnText: 'কয়েন ব্যবহার করুন'),
                                                      value: '$coinPrice ' + FFLocalizations.of(context).getVariableText(enText: 'Coins', bnText: 'কয়েন'),
                                                      onTap: () => Navigator.of(ctx).pop('coins'),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                  if (bdtPrice > 0) ...[
                                                    buildUnlockOptionCard(
                                                      icon: Icons.account_balance_wallet_rounded,
                                                      iconColor: const Color(0xFF2EC4B6),
                                                      label: FFLocalizations.of(context).getVariableText(enText: 'Pay with Cash', bnText: 'ক্যাশ পে করুন'),
                                                      value: '৳${bdtPrice.toStringAsFixed(0)}',
                                                      onTap: () => Navigator.of(ctx).pop('payment'),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                ],
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop('cancel'),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(FFLocalizations.of(context).getVariableText(enText: 'Cancel', bnText: 'বাতিল করুন'), style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: theme.secondaryText,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                            if (option == 'apple_iap') {
                              final productId = RevenueCatService.getProductIdForCoinCost(coinPrice);
                              final purchaseResult = await RevenueCatService.purchaseChapter(productId);
                              
                              if (purchaseResult['success'] == true) {
                                final transactionId = purchaseResult['transactionId'];
                                
                                final res = await EbookGroup.unlockChapterWithIAPCall.call(
                                  trackId: trackId.toString(),
                                  bookId: bookId,
                                  transactionId: transactionId,
                                  productId: productId,
                                  token: FFAppState().token,
                                );

                                if (res.statusCode == 200 || res.succeeded) {
                                  await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Chapter unlocked successfully!', bnText: 'অধ্যায় সফলভাবে আনলক করা হয়েছে!'));
                                  _tracks = null;
                                  await _checkIfPurchased();
                                  safeSetState(() {});
                                } else {
                                  final msg = getJsonField(res.jsonBody, r'''$.error''') ?? 
                                              getJsonField(res.jsonBody, r'''$.message''') ?? 'Unlock verification failed';
                                  await actions.showCustomToastBottom(msg.toString());
                                }
                              } else {
                                final error = purchaseResult['errorMessage'];
                                if (error != null) {
                                  await actions.showCustomToastBottom(error);
                                }
                              }
                            } else if (option == 'coins') {
                              final balance = await _walletBalance();
                              if (balance == null || balance < coinPrice) {
                                await _showInsufficientCoinsDialog(
                                  context: context,
                                  requiredCoins: coinPrice,
                                  currentCoins: balance ?? 0,
                                );
                                return;
                              }
                              final res = await EbookGroup.unlockChapterWithCoinsCall.call(
                                trackId: trackId.toString(),
                                token: FFAppState().token,
                              );
                              if (res.statusCode == 200 || res.succeeded) {
                                await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Chapter unlocked successfully!', bnText: 'অধ্যায় সফলভাবে আনলক করা হয়েছে!'));
                                _tracks = null;
                                safeSetState(() {});
                              } else {
                                final msg = getJsonField(res.jsonBody, r'''$.message''') ?? 'Unlock failed';
                                await actions.showCustomToastBottom(msg.toString());
                              }
                            } else if (option == 'payment') {
                              final res = await EbookGroup.initiateChapterPaymentCall.call(
                                trackId: trackId.toString(),
                                bookId: bookId,
                                token: FFAppState().token,
                              );
                              if (res.succeeded && res.jsonBody != null) {
                                final gatewayUrl = getJsonField(res.jsonBody, r'''$.gateway_url''')?.toString() ??
                                    getJsonField(res.jsonBody, r'''$.GatewayPageURL''')?.toString() ?? '';
                                final purchaseId = getJsonField(res.jsonBody, r'''$.purchase_id''')?.toString() ??
                                    getJsonField(res.jsonBody, r'''$.order_id''')?.toString() ?? '';
                                if (gatewayUrl.isNotEmpty) {
                                  final success = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentWebView(
                                        url: gatewayUrl,
                                        orderId: purchaseId,
                                        bookIds: [bookId],
                                        purchasedFormats: ['audiobook'],
                                        checkoutController: CheckoutController(
                                          jwtToken: FFAppState().token,
                                          userId: FFAppState().userId,
                                        ),
                                        isChapterUnlock: true,
                                      ),
                                    ),
                                  );
                                  if (success == true || success == null) {
                                    _tracks = null;
                                    await _checkIfPurchased();
                                    safeSetState(() {});
                                  }
                                } else {
                                  await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to get gateway URL', bnText: 'গেটওয়ে ইউআরএল পেতে ব্যর্থ'));
                                }
                              } else {
                                await actions.showCustomToastBottom(FFLocalizations.of(context).getVariableText(enText: 'Failed to initiate payment', bnText: 'পেমেন্ট শুরু করতে ব্যর্থ'));
                              }
                            } else if (option == 'buy_full_book') {
                              await _handleBuyNow(
                                tab: BookMasterFormatTab.audiobook,
                                bookId: bookId,
                                bookName: bookName,
                                bookImage: bookImage,
                                ebookFormat: _pickFormat(formats.cast<Map<String, dynamic>>(), 'ebook'),
                                audiobookFormat: audiobookFormat,
                                hardcopyFormat: _pickFormat(formats.cast<Map<String, dynamic>>(), 'hardcopy'),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
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
        String bookSlug = valueOrDefault<String>(
            EbookGroup.getbookdetailsApiCall.slug(
              bookDetailspageGetbookdetailsApiResponse.jsonBody,
            ),
            "");
        if (bookSlug.isNotEmpty && _bookSlug != bookSlug) {
          _bookSlug = bookSlug;
        }
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
        final pricingModeVal = getJsonField(
          bookDetailspageGetbookdetailsApiResponse.jsonBody,
          r'''$.data.bookDetails[0].pricing_mode''',
        )?.toString();
        if (pricingModeVal != null && _audiobookPricingMode != pricingModeVal) {
          _audiobookPricingMode = pricingModeVal;
        }
        final isBookFree = getJsonField(
              bookDetailspageGetbookdetailsApiResponse.jsonBody,
              r'''$.data.bookDetails[0].is_free''',
            ) ==
            true;
        final ebookFormat = _pickFormat(formats, 'ebook');
        final audiobookFormat = _pickFormat(formats, 'audiobook');
        final narratorIds = audiobookFormat?['narrator_ids'];
        final initialNarrator = audiobookFormat?['narrator'];
        if ((narratorIds is List && narratorIds.isNotEmpty) || initialNarrator != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadNarratorsForIds(narratorIds, initialNarrator);
          });
        }
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
        String selectedType = '';
        if (activeTab == BookMasterFormatTab.ebook) {
          selectedType = 'ebook';
        } else if (activeTab == BookMasterFormatTab.audiobook) {
          selectedType = 'audiobook';
        } else {
          selectedType = 'hardcopy';
        }
        final double selectedPrice = _formatPrice(selectedFormat);
        final int? selectedCoinPrice = selectedFormat != null && _formatCoinPrice(selectedFormat) > 0
            ? _formatCoinPrice(selectedFormat)
            : null;
        final bool isFormatFree = selectedPrice <= 0;
        final bool hasFormatAccess = _hasLocalFormatAccess(
          bookId: bookId,
          format: selectedType,
          isFree: isBookFree,
          price: selectedPrice,
          subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (selectedFormat?['subscriber_access'] == true),
        );
        final previewPercent = _previewPercent(selectedFormat);
        final ebookPrice = _formatPrice(ebookFormat);
        final hasEbookAccess = _hasLocalFormatAccess(
          bookId: bookId,
          format: 'ebook',
          isFree: isBookFree,
          price: ebookPrice,
          subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (ebookFormat?['subscriber_access'] == true),
        );
        final isEbookPremium = !isBookFree && ebookPrice > 0;
        final isAlreadyPurchased = FFAppState().isLogin &&
            _purchasedFormatKeys.contains('${bookId.toLowerCase()}::audiobook');
        final audiobookPrice = audiobookFormat != null ? _formatPrice(audiobookFormat) : 0.0;
        final hasAudiobookAccess = _hasLocalFormatAccess(
          bookId: bookId,
          format: 'audiobook',
          isFree: isBookFree,
          price: audiobookPrice,
          subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (audiobookFormat?['subscriber_access'] == true),
        );

        final showPreviewBadge = activeTab != BookMasterFormatTab.hardcopy &&
            !_hasLocalFormatAccess(
              bookId: bookId,
              format: activeTab == BookMasterFormatTab.ebook
                  ? 'ebook'
                  : 'audiobook',
              isFree: isBookFree,
              price: _formatPrice(selectedFormat),
              subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (selectedFormat?['subscriber_access'] == true),
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
                                           InkWell(
                                             splashColor: Colors.transparent,
                                             focusColor: Colors.transparent,
                                             hoverColor: Colors.transparent,
                                             highlightColor: Colors.transparent,
                                             onTap: () async {
                                               await SharePlus.instance.share(
                                                   ShareParams(
                                                       text: bookSlug.isNotEmpty
                                                           ? "${FFAppConstants.webUrl}/book/$bookSlug"
                                                           : "${FFAppConstants.webUrl}/b/$bookId"));
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
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText
                                                              .withValues(
                                                                  alpha: 0.4),
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
                                                      FFLocalizations.of(context).getVariableText(enText: 'Purchased', bnText: 'কেনা হয়েছে'),
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
                                              // // English subtitle (title_en from v2)
                                              // Builder(builder: (context) {
                                              //   final titleEn = getJsonField(
                                              //         bookDetailspageGetbookdetailsApiResponse
                                              //             .jsonBody,
                                              //         r'''$.data.bookDetails[0].slug''',
                                              //       )
                                              //           ?.toString()
                                              //           .replaceAll('-', ' ') ??
                                              //       '';
                                              //   if (titleEn.isEmpty) {
                                              //     return const SizedBox
                                              //         .shrink();
                                              //   }
                                              //   return Padding(
                                              //     padding:
                                              //         const EdgeInsets.only(
                                              //             top: 2.0),
                                              //     child: Text(
                                              //       titleEn,
                                              //       maxLines: 1,
                                              //       overflow:
                                              //           TextOverflow.ellipsis,
                                              //       style: FlutterFlowTheme.of(
                                              //               context)
                                              //           .bodySmall
                                              //           .override(
                                              //             fontFamily:
                                              //                 'SF Pro Display',
                                              //             color: FlutterFlowTheme
                                              //                     .of(context)
                                              //                 .secondaryText,
                                              //             fontSize: 12.0,
                                              //             letterSpacing: 0.0,
                                              //           ),
                                              //     ),
                                              //   );
                                              // }),
                                              
                                              SizedBox(height: 8.0),
                                              // Author name
                                               Builder(builder: (context) {
                                                 final aName = EbookGroup.getbookdetailsApiCall.authorName(
                                                       bookDetailspageGetbookdetailsApiResponse
                                                           .jsonBody,
                                                     ) ??
                                                     '';
                                                 final rawImage = EbookGroup.getbookdetailsApiCall.authorimage(
                                                       bookDetailspageGetbookdetailsApiResponse
                                                           .jsonBody,
                                                     ) ??
                                                     '';
                                                 final aImage = rawImage.isNotEmpty
                                                     ? '${FFAppConstants.imageUrl}$rawImage'
                                                     : '';
                                                 final aId = EbookGroup.getbookdetailsApiCall.authorid(
                                                       bookDetailspageGetbookdetailsApiResponse
                                                           .jsonBody,
                                                     ) ??
                                                     '';
                                                 return GestureDetector(
                                                   onTap: () {
                                                     if (aId.isNotEmpty) {
                                                       context.pushNamed(
                                                         AboutAuthorPageWidget.routeName,
                                                         queryParameters: {
                                                           'name': serializeParam(
                                                               aName, ParamType.String),
                                                           'authorImage': serializeParam(
                                                               aImage, ParamType.String),
                                                           'authorId': serializeParam(
                                                               aId, ParamType.String),
                                                         }.withoutNulls,
                                                       );
                                                     }
                                                   },
                                                   child: Row(
                                                     mainAxisSize: MainAxisSize.min,
                                                     children: [
                                                       Container(
                                                         margin: const EdgeInsets.only(right: 6.0),
                                                         child: ClipRRect(
                                                           borderRadius: BorderRadius.circular(12.0),
                                                           child: aImage.isNotEmpty
                                                               ? CachedNetworkImage(
                                                                   fadeInDuration: const Duration(milliseconds: 200),
                                                                   fadeOutDuration: const Duration(milliseconds: 200),
                                                                   imageUrl: aImage,
                                                                   width: 24.0,
                                                                   height: 24.0,
                                                                   fit: BoxFit.cover,
                                                                   errorWidget: (context, error, stackTrace) => Container(
                                                                     width: 24.0,
                                                                     height: 24.0,
                                                                     color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                     child: Icon(
                                                                       Icons.person,
                                                                       size: 14.0,
                                                                       color: FlutterFlowTheme.of(context).secondaryText,
                                                                     ),
                                                                   ),
                                                                 )
                                                               : Container(
                                                                   width: 24.0,
                                                                   height: 24.0,
                                                                   color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                   child: Icon(
                                                                     Icons.person,
                                                                     size: 14.0,
                                                                     color: FlutterFlowTheme.of(context).secondaryText,
                                                                   ),
                                                                 ),
                                                         ),
                                                       ),
                                                       Flexible(
                                                         child: Text(
                                                           aName,
                                                           maxLines: 1,
                                                           overflow: TextOverflow.ellipsis,
                                                           style: FlutterFlowTheme.of(context)
                                                               .bodyMedium
                                                               .override(
                                                                 fontFamily: 'SF Pro Display',
                                                                 color: FlutterFlowTheme.of(context).primary,
                                                                 fontSize: 13.0,
                                                                 letterSpacing: 0.0,
                                                                 fontWeight: FontWeight.normal,
                                                                 lineHeight: 1.3,
                                                               ),
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                               }),
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
                                                    '${getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r"$.data.bookDetails[0].total_reads") ?? 0} ' + FFLocalizations.of(context).getVariableText(enText: 'reads', bnText: 'পঠিত'),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                  if (audiobookFormat != null) ...[
                                                    const SizedBox(width: 12.0),
                                                    Icon(Icons.headphones_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        size: 14.0),
                                                    const SizedBox(width: 3.0),
                                                    Text(
                                                      '${getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r"$.data.bookDetails[0].total_listens") ?? 0} ' + FFLocalizations.of(context).getVariableText(enText: 'listens', bnText: 'বার'),
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryText,
                                                            fontSize: 12.0,
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),

                                              SizedBox(height: 10.0),
                                              // Wishlist + Share row
                                              Row(
                                                children: [
                                                  // Add to Wishlist button
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed:
                                                          _toggleBookmarkStatus,
                                                      icon:
                                                          _model.isFavoriteLoading ==
                                                                  true
                                                              ? SizedBox(
                                                                  width: 14,
                                                                  height: 14,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    valueColor:
                                                                        AlwaysStoppedAnimation(
                                                                            FlutterFlowTheme.of(context).primary),
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  _model.isFavorite!
                                                                      ? Icons
                                                                          .favorite
                                                                      : Icons
                                                                          .favorite_border,
                                                                  
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                ),
                                                      label: Text(
                                                        _model.isFavorite!
                                                            ? FFLocalizations.of(context).getVariableText(enText: 'Wishlisted', bnText: 'প্রিয়')
                                                            : FFLocalizations.of(context).getVariableText(enText: 'Wishlist', bnText: 'প্রিয়'),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  fontSize:
                                                                      12.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                      ),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        side: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary
                                                              .withOpacity(0.5),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
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
                                                  if (selectedFormat != null && !isFormatFree && !hasFormatAccess) ...[
                                                    const SizedBox(width: 12.0),
                                                    Expanded(
                                                      child: Consumer<CartProvider>(
                                                        builder: (context, cart, child) {
                                                          final isInCart = cart.items.containsKey(bookId);
                                                          return OutlinedButton.icon(
                                                            onPressed: () {
                                                              if (isInCart) {
                                                                Navigator.push<void>(
                                                                  context,
                                                                  MaterialPageRoute<void>(
                                                                    builder: (BuildContext context) => const CartPageWidget(),
                                                                  ),
                                                                );
                                                              } else {
                                                                _addToCartOnly(
                                                                  bookId: bookId,
                                                                  bookName: bookName,
                                                                  bookImage: bookImage,
                                                                  price: selectedPrice,
                                                                  type: selectedType,
                                                                  coinPrice: selectedCoinPrice,
                                                                );
                                                              }
                                                            },
                                                            icon: Icon(
                                                              isInCart
                                                                  ? Icons.shopping_cart_rounded
                                                                  : Icons.add_shopping_cart_rounded,
                                                              color: FlutterFlowTheme.of(context).primary,
                                                            ),
                                                            label: Text(
                                                              isInCart
                                                                  ? FFLocalizations.of(context).getVariableText(
                                                                      enText: 'In Cart',
                                                                      bnText: 'কার্টে আছে',
                                                                    )
                                                                  : FFLocalizations.of(context).getVariableText(
                                                                      enText: 'Cart',
                                                                      bnText: 'কার্ট',
                                                                    ),
                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                    fontFamily: 'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(context).primary,
                                                                    fontSize: 14.0,
                                                                    letterSpacing: 0.0,
                                                                  ),
                                                            ),
                                                            style: OutlinedButton.styleFrom(
                                                              side: BorderSide(
                                                                color: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
                                                              ),
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
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
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      opacity:
                                                          ebookFormat == null
                                                              ? 0.45
                                                              : 1,
                                                      child: Text(
                                                          FFLocalizations.of(context).getVariableText(enText: 'eBook', bnText: 'ই-বই'),
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
                                                              letterSpacing:
                                                                  0.0,
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
                                                      opacity:
                                                          audiobookFormat ==
                                                                  null
                                                              ? 0.45
                                                              : 1,
                                                      child: Text(
                                                          FFLocalizations.of(context).getVariableText(enText: 'Audiobook', bnText: 'অডিওবুক'),
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
                                                              letterSpacing:
                                                                  0.0,
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
                                                      opacity:
                                                          hardcopyFormat == null
                                                              ? 0.45
                                                              : 1,
                                                      child: Text(
                                                          FFLocalizations.of(context).getVariableText(enText: 'Hardcopy', bnText: 'প্রিন্ট কপি'),
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
                                                              letterSpacing:
                                                                  0.0,
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
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
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
                                                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Price: ', bnText: 'মূল্য: ') + '৳${_formatPrice(selectedFormat).toStringAsFixed(_formatPrice(selectedFormat).truncateToDouble() == _formatPrice(selectedFormat) ? 0 : 2)}',
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(FFLocalizations.of(context).getVariableText(enText: 'Pages: ', bnText: 'পৃষ্ঠা: ') + '${selectedFormat?['pages']}',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  ),
                                                if (selectedFormat?[
                                                        'duration'] !=
                                                    null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(FFLocalizations.of(context).getVariableText(enText: 'Duration: ', bnText: 'সময়কাল: ') + '${selectedFormat?['duration']}',
                                                      style: FlutterFlowTheme
                                                              .of(context)
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
                                                    selectedFormat?[
                                                            'in_stock'] !=
                                                        null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      selectedFormat?[
                                                                  'in_stock'] ==
                                                              true
                                                          ? 'In stock (${selectedFormat?['stock_count'] ?? 0})'
                                                          : FFLocalizations.of(context).getVariableText(enText: 'Out of stock', bnText: 'স্টক শেষ'),
                                                      style: FlutterFlowTheme
                                                              .of(context)
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
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .account_balance_wallet_rounded,
                                                  size: 16,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _walletCoinBalance == null
                                                      ? 'Available coins: --'
                                                      : 'Available coins: $_walletCoinBalance',
                                                  style: FlutterFlowTheme.of(
                                                          context)
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
                                        if (activeTab ==
                                            BookMasterFormatTab.ebook)
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
                                                          forcePreview: true,
                                                        ),
                                                        text:
                                                            '${FFLocalizations.of(context).getVariableText(enText: 'Preview', bnText: 'প্রিভিউ')} ($previewPercent%)',
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
                                                            _handleBuyNow(
                                                          tab: activeTab,
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          ebookFormat:
                                                              ebookFormat,
                                                          audiobookFormat:
                                                              audiobookFormat,
                                                          hardcopyFormat:
                                                              hardcopyFormat,
                                                        ),
                                                        text: FFLocalizations.of(context).getVariableText(enText: 'Buy Now', bnText: 'এখনি কিনুন'),
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
                                              else if (_isEbookDownloaded && !_isEbookDownloadStale)
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
                                                  text: FFLocalizations.of(context).getVariableText(enText: 'Read Now', bnText: 'এখনি পড়ুন'),
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
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.0,
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
                                                        text: FFLocalizations.of(context).getVariableText(enText: 'Read Now', bnText: 'এখনি পড়ুন'),
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
                                                                      subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (ebookFormat?['subscriber_access'] == true),
                                                                    );
                                                                  },
                                                        text:
                                                            _isDownloadingEbook
                                                                ? FFLocalizations.of(context).getVariableText(enText: 'Downloading...', bnText: 'ডাউনলোড হচ্ছে...')
                                                                : (_isEbookDownloadStale
                                                                    ? FFLocalizations.of(context).getVariableText(enText: 'Update', bnText: 'আপডেট')
                                                                    : FFLocalizations.of(context).getVariableText(enText: 'Download', bnText: 'ডাউনলোড')),
                                                        icon:_isDownloadingEbook?null: Icon(
                                                          _isEbookDownloadStale
                                                              ? Icons.update_rounded
                                                              : Icons.download_rounded,
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
                                                ),
                                            ],
                                          )
                                        else
                                          Builder(builder: (context) {
                                            if (activeTab ==
                                                BookMasterFormatTab.audiobook) {
                                              final hasAudioAccess =
                                                  _hasLocalFormatAccess(
                                                bookId: bookId,
                                                format: 'audiobook',
                                                isFree: isBookFree,
                                                price: _formatPrice(
                                                    audiobookFormat),
                                                 subscriberAccess: (getJsonField(bookDetailspageGetbookdetailsApiResponse.jsonBody, r'''$.data.bookDetails[0].subscriber_access''') == true) || (audiobookFormat?['subscriber_access'] == true),
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
                                                  text: FFLocalizations.of(context).getVariableText(enText: 'Listen Now', bnText: 'এখনি শুনুন'),
                                                  icon: Icon(
                                                    Icons.headphones_rounded,
                                                    color: Colors.white,
                                                  ),
                                                  options: FFButtonOptions(
                                                    width: double.infinity,
                                                    height: 48,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.0,
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
                                                        onPressed: () async {
                                                            final hasFreeChapter = _tracks != null &&
                                                                _tracks!.any((t) =>
                                                                    t['is_free'] == true ||
                                                                    t['is_preview'] == true);
                                                            if (hasFreeChapter) {
                                                              final firstFreeTrack = _tracks?.firstWhere(
                                                                (t) => t['is_free'] == true || t['is_preview'] == true,
                                                                orElse: () => <String, dynamic>{},
                                                              );
                                                              final initialTrackNum = (firstFreeTrack != null && firstFreeTrack.isNotEmpty)
                                                                  ? (firstFreeTrack['track_number'] is num ? (firstFreeTrack['track_number'] as num).toInt() : null)
                                                                  : null;
                                                              final performPlay = () async {
                                                                await _openAudiobookPlayerFromV2(
                                                                  bookId: bookId,
                                                                  bookName: bookName,
                                                                  bookImage: bookImage,
                                                                  authorName: authorName,
                                                                  hasFullAccess: false,
                                                                  forceIsPreviewMode: false,
                                                                  initialTrackNumber: initialTrackNum,
                                                                  audiobookFormat: audiobookFormat,
                                                                );
                                                              };

                                                              final canShowAd = await AdManager.canShowAd();
                                                              if (canShowAd) {
                                                                showDialog(
                                                                  context: context,
                                                                  barrierDismissible: false,
                                                                  builder: (ctx) => custom_widgets.AdRewardDialog(
                                                                    bookImage: bookImage,
                                                                    onWatchAd: performPlay,
                                                                    adType: 'rewarded',
                                                                    claimReward: false,
                                                                  ),
                                                                );
                                                              } else {
                                                                await performPlay();
                                                              }
                                                            } else {
                                                              await _handleMasterAction(
                                                                tab: activeTab,
                                                                bookId: bookId,
                                                                bookName: bookName,
                                                                bookImage: bookImage,
                                                                authorName: authorName,
                                                                isBookFree: isBookFree,
                                                                ebookFormat: ebookFormat,
                                                                audiobookFormat: audiobookFormat,
                                                                hardcopyFormat: hardcopyFormat,
                                                                responseJson: bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                                                forcePreview: true,
                                                              );
                                                            }
                                                          },
                                                          text: (_tracks != null &&
                                                                  _tracks!.any((t) =>
                                                                      t['is_free'] == true ||
                                                                      t['is_preview'] == true))
                                                              ? FFLocalizations.of(context).getVariableText(enText: 'Listen Now', bnText: 'এখনি শুনুন')
                                                              : '${FFLocalizations.of(context).getVariableText(enText: 'Preview', bnText: 'প্রিভিউ')} ($previewPercent%)',
                                                        icon: Icon(
                                                          Icons
                                                              .headphones_rounded,
                                                          color: Colors.white,
                                                        ),
                                                        options:
                                                            FFButtonOptions(
                                                          height: 48,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
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
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: FFButtonWidget(
                                                        onPressed: () =>
                                                            _handleBuyNow(
                                                          tab: activeTab,
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          ebookFormat:
                                                              ebookFormat,
                                                          audiobookFormat:
                                                              audiobookFormat,
                                                          hardcopyFormat:
                                                              hardcopyFormat,
                                                        ),
                                                        text: FFLocalizations.of(context).getVariableText(enText: 'Buy Now', bnText: 'এখনি কিনুন'),
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
                                                     ? FFLocalizations.of(context).getVariableText(enText: 'View Orders', bnText: 'অর্ডার দেখুন')
                                                     : FFLocalizations.of(context).getVariableText(enText: 'Buy Hardcopy', bnText: 'হার্ডকপি কিনুন'),
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
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 0.0,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 12.0),
                                    child: _buildEpisodesInAudioTab(
                                      bookId: bookId,
                                      formats: formats,
                                      bookName: bookName,
                                      bookImage: bookImage,
                                      authorName: authorName,
                                      isBookFree: isBookFree,
                                      hasAudiobookAccess: hasAudiobookAccess,
                                    ),
                                  ),
                                // Book details placement banner
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: custom_widgets.AdBannerWidget(
                                    placementKey: 'book_details',
                                  ),
                                ),
                                // Book Description Section
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 20.0, 16.0, 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(FFLocalizations.of(context).getVariableText(enText: 'About the book', bnText: 'বই সম্পর্কে'), textAlign: TextAlign.start,
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
                                      // Category chip at bottom of about book
                                      Builder(builder: (context) {
                                        final catId = EbookGroup.getbookdetailsApiCall.categoryId(
                                          bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                        ) ?? '';
                                        final catName = EbookGroup.getbookdetailsApiCall.categoryName(
                                          bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                        ) ?? '';
                                        if (catName.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 16.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              if (catId.isNotEmpty) {
                                                context.pushNamed(
                                                  SubCategoriesScreenWidget.routeName,
                                                  queryParameters: {
                                                    'id': serializeParam(catId, ParamType.String),
                                                    'name': serializeParam(catName, ParamType.String),
                                                  }.withoutNulls,
                                                );
                                              }
                                            },
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16.0, vertical: 8.0),
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(20.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                                                                      Text(
                                                      catName,
                                                      style: FlutterFlowTheme.of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily: 'SF Pro Display',
                                                            color: FlutterFlowTheme.of(context).primary,
                                                            fontSize: 13.0,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 8.0, 16.0, 16.0),
                                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Information', bnText: 'তথ্য'), textAlign: TextAlign.start,
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
                                                Text(FFLocalizations.of(context).getVariableText(enText: 'Language', bnText: 'ভাষা'), textAlign: TextAlign.start,
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
                                                  valueOrDefault<String>(EbookGroup.getbookdetailsApiCall.language(bookDetailspageGetbookdetailsApiResponse.jsonBody,), FFLocalizations.of(context).getVariableText(enText: 'Language', bnText: 'ভাষা'),
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
                                                Text(FFLocalizations.of(context).getVariableText(enText: 'Rating', bnText: 'রেটিং'), textAlign: TextAlign.start,
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
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  4.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        '(${EbookGroup.getbookdetailsApiCall.reviewsCount(bookDetailspageGetbookdetailsApiResponse.jsonBody) ?? 0})',
                                                        maxLines: 1,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                              fontSize: 14.0,
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
                                // ── Author / Narrator / Publisher / Translator ──────────────────
                                Builder(builder: (context) {
                                  final aName = EbookGroup.getbookdetailsApiCall
                                          .authorName(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                      ) ??
                                      '';
                                  final aImage =
                                      '${FFAppConstants.imageUrl}${EbookGroup.getbookdetailsApiCall.authorimage(bookDetailspageGetbookdetailsApiResponse.jsonBody) ?? ''}';
                                  final aId =
                                      EbookGroup.getbookdetailsApiCall.authorid(
                                            bookDetailspageGetbookdetailsApiResponse
                                                .jsonBody,
                                          ) ??
                                          '';

                                  final tName = valueOrDefault<String>(
                                    EbookGroup.getbookdetailsApiCall.translatorName(
                                      bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                    ),
                                    '',
                                  );
                                  final tId = valueOrDefault<String>(
                                    EbookGroup.getbookdetailsApiCall.translatorid(
                                      bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                    ),
                                    '',
                                  );
                                  final tImageRaw = valueOrDefault<String>(
                                    EbookGroup.getbookdetailsApiCall.translatorimage(
                                      bookDetailspageGetbookdetailsApiResponse.jsonBody,
                                    ),
                                    '',
                                  );
                                  final tImage = tImageRaw.isEmpty
                                      ? ''
                                      : (tImageRaw.startsWith('http')
                                          ? tImageRaw
                                          : '${FFAppConstants.imageUrl}$tImageRaw');

                                  // Extract narrator details from narrator_ids or from narrator cache
                                  final narratorIdsRaw = audiobookFormat?['narrator_ids'];
                                  final narratorIds = narratorIdsRaw is List
                                      ? narratorIdsRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
                                      : <String>[];
                                      
                                  // Fallback to legacy single narrator if narrator_ids is empty
                                  if (narratorIds.isEmpty) {
                                    final singleNarratorId = audiobookFormat?['narrator_id']?.toString() ?? '';
                                    if (singleNarratorId.isNotEmpty) {
                                      narratorIds.add(singleNarratorId);
                                    }
                                  }

                                  final List<Map<String, dynamic>> resolvedNarrators = [];
                                  for (final id in narratorIds) {
                                    if (_narratorCache.containsKey(id)) {
                                      resolvedNarrators.add(_narratorCache[id]!);
                                    } else {
                                      final initialNarrator = audiobookFormat?['narrator'];
                                      final initId = initialNarrator is Map
                                          ? (initialNarrator['id']?.toString() ?? initialNarrator['_id']?.toString() ?? '')
                                          : '';
                                      if (id == initId && initialNarrator is Map) {
                                        final initName = initialNarrator['name']?.toString() ?? '';
                                        final initImageRaw = initialNarrator['avatar_url']?.toString() ?? initialNarrator['image']?.toString() ?? '';
                                        final initImage = initImageRaw.isEmpty
                                            ? ''
                                            : (initImageRaw.startsWith('http')
                                                ? initImageRaw
                                                : '${FFAppConstants.imageUrl}$initImageRaw');
                                        resolvedNarrators.add({
                                          '_id': id,
                                          'name': initName,
                                          'image': initImage,
                                          'total_listens': initialNarrator['total_listens']
                                        });
                                      }
                                    }
                                  }

                                  final publisherName = getJsonField(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                        r'''$.data.bookDetails[0].publisher.name''',
                                      )?.toString() ??
                                      '';
                                  final publisherImageRaw = getJsonField(
                                        bookDetailspageGetbookdetailsApiResponse
                                            .jsonBody,
                                        r'''$.data.bookDetails[0].publisher.image''',
                                      )?.toString() ??
                                      '';
                                  final publisherId = getJsonField(
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
                                           FFLocalizations.of(context).getVariableText(enText: 'People', bnText: 'সংশ্লিষ্ট ব্যক্তিবর্গ'),
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
                                          label: FFLocalizations.of(context).getVariableText(enText: 'Author', bnText: 'লেখক'),
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

                                       // Translator row
                                       if (tName.isNotEmpty)
                                         _buildPersonRow(
                                           label: FFLocalizations.of(context).getVariableText(enText: 'Translator', bnText: 'অনুবাদক'),
                                           name: tName,
                                           imageUrl: tImage,
                                           subtitle: '',
                                           onTap: () => context.pushNamed(
                                             AboutTranslatorPageWidget.routeName,
                                             queryParameters: {
                                               'name': serializeParam(tName, ParamType.String),
                                               'translatorImage': serializeParam(tImage, ParamType.String),
                                               'translatorId': serializeParam(tId, ParamType.String),
                                             }.withoutNulls,
                                           ),
                                         ),

                                       // Narrator row (audiobook only)
                                       for (final narrator in (_showAllNarrators
                                           ? resolvedNarrators
                                           : resolvedNarrators.take(3)))
                                         _buildPersonRow(
                                           label: FFLocalizations.of(context).getVariableText(enText: 'Narrator', bnText: 'কণ্ঠশিল্পী'),
                                           name: narrator['name']?.toString() ?? '',
                                           imageUrl: () {
                                             final img = narrator['image']?.toString() ?? '';
                                             return img.isEmpty
                                                 ? ''
                                                 : (img.startsWith('http')
                                                     ? img
                                                     : '${FFAppConstants.imageUrl}$img');
                                           }(),
                                           subtitle: '',
                                           onTap: () {
                                             final id = narrator['_id']?.toString() ?? narrator['id']?.toString() ?? '';
                                             final name = narrator['name']?.toString() ?? '';
                                             final img = narrator['image']?.toString() ?? '';
                                             final fullImg = img.isEmpty
                                                 ? ''
                                                 : (img.startsWith('http')
                                                     ? img
                                                     : '${FFAppConstants.imageUrl}$img');
                                             if (id.isNotEmpty) {
                                               context.pushNamed(
                                                 AboutNarratorPageWidget.routeName,
                                                 queryParameters: {
                                                   'name': serializeParam(name, ParamType.String),
                                                   'narratorImage': serializeParam(fullImg, ParamType.String),
                                                   'narratorId': serializeParam(id, ParamType.String),
                                                 }.withoutNulls,
                                               );
                                             }
                                           },
                                         ),
                                       if (resolvedNarrators.length > 3)
                                         Padding(
                                           padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 8.0),
                                           child: InkWell(
                                             onTap: () {
                                               safeSetState(() {
                                                 _showAllNarrators = !_showAllNarrators;
                                               });
                                             },
                                             child: Row(
                                               mainAxisSize: MainAxisSize.max,
                                               mainAxisAlignment: MainAxisAlignment.end,
                                               children: [
                                                 Text(
                                                   _showAllNarrators
                                                       ? FFLocalizations.of(context).getVariableText(enText: 'See less', bnText: 'কম দেখান')
                                                       : FFLocalizations.of(context).getVariableText(enText: 'See more', bnText: 'আরো দেখান'),
                                                   style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                     fontFamily: 'SF Pro Display',
                                                     color: FlutterFlowTheme.of(context).primary,
                                                     fontWeight: FontWeight.w600,
                                                   ),
                                                 ),
                                                 Icon(
                                                   _showAllNarrators
                                                       ? Icons.keyboard_arrow_up_rounded
                                                       : Icons.keyboard_arrow_down_rounded,
                                                   color: FlutterFlowTheme.of(context).primary,
                                                   size: 20.0,
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ),

                                      if (publisherName.isNotEmpty)
                                        _buildPersonRow(
                                          label: FFLocalizations.of(context).getVariableText(enText: 'Publisher', bnText: 'প্রকাশক'),
                                          name: publisherName,
                                          imageUrl: publisherImage,
                                          subtitle: '',
                                          onTap: () {
                                            if (publisherId.isNotEmpty) {
                                              context.pushNamed(
                                                AboutPublisherPageWidget
                                                    .routeName,
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
                                    activeTab ==
                                        BookMasterFormatTab.audiobook &&
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
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              16.0, 0.0, 16.0, 0.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title row
                                          Row(
                                            children: [
                                              Text(
                                                _tracksLoading
                                                    ? FFLocalizations.of(context).getVariableText(enText: 'Episodes', bnText: 'পর্বসমূহ')
                                                    : '${FFLocalizations.of(context).getVariableText(enText: 'Episodes', bnText: 'পর্বসমূহ')} ($trackCount)',
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

                                          if (!_tracksLoading &&
                                              trackCount == 0)
                                            Padding(
                                            padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                FFLocalizations.of(context).getVariableText(enText: 'No episodes available.', bnText: 'কোনো পর্ব উপলব্ধ নেই।'),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),

                                          // Track list
                                          ...tracks.map((track) {
                                            final isPreview =
                                                track['is_preview'] == true;
                                            final trackNum = track['track_number'];
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: ListTile(
                                                  onTap: () async {
                                                    if (!FFAppState().isLogin) {
                                                       context.pushNamed(SignInPageWidget.routeName);
                                                       return;
                                                     }
                                                     final audiobookFormat = _pickFormat(
                                                        formats.cast<Map<String, dynamic>>(), 'audiobook');
                                                    if (audiobookFormat == null) return;
                                                    final audiobookPrice = _formatPrice(audiobookFormat);
                                                    final audiobookCoinPrice = _formatCoinPrice(audiobookFormat);
                                                    final audiobookPreviewPercent = _previewPercent(audiobookFormat);
                                                    final isAudiobookFree = _audiobookPricingMode == 'per_chapter'
                                                        ? false
                                                        : (isBookFree || audiobookPrice <= 0);
                                                    final hasAccessByApi = FFAppState().isLogin &&
                                                        await _hasFormatAccess(bookId: bookId, format: 'audiobook');
                                                    final hasAccess = isAudiobookFree || hasAccessByApi;

                                                    if (hasAccess) {
                                                      final playAudiobook = () async {
                                                        await _openAudiobookPlayerFromV2(
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          authorName: authorName,
                                                          hasFullAccess: true,
                                                          previewPercent: audiobookPreviewPercent,
                                                          audiobookFormat: audiobookFormat,
                                                          initialTrackNumber: trackNum is int ? trackNum : (trackNum is double ? trackNum.toInt() : (trackNum != null ? int.tryParse(trackNum.toString()) : null)),
                                                          isFree: isAudiobookFree,
                                                        );
                                                      };

                                                      final isAlreadyPurchased = FFAppState().isLogin &&
                                                          _purchasedFormatKeys.contains('${bookId.toLowerCase()}::audiobook');
                                                      final isAdNeeded = isAudiobookFree && !isAlreadyPurchased;
                                                      if (isAdNeeded) {
                                                        final canShowAd = await AdManager.canShowAd();
                                                        if (canShowAd) {
                                                          showDialog(
                                                            context: context,
                                                            barrierDismissible: false,
                                                            builder: (ctx) => custom_widgets.AdRewardDialog(
                                                              bookImage: bookImage,
                                                              onWatchAd: playAudiobook,
                                                              adType: 'rewarded_interstitial',
                                                              claimReward: false,
                                                            ),
                                                          );
                                                        } else {
                                                          await playAudiobook();
                                                        }
                                                      } else {
                                                        await playAudiobook();
                                                      }
                                                    } else {
                                                      if (!FFAppState().isLogin) {
                                                        context.pushNamed(SignInPageWidget.routeName);
                                                        return;
                                                      }
                                                      if (audiobookCoinPrice > 0) {
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
                                                            audiobookFormat: audiobookFormat,
                                                            initialTrackNumber: trackNum is int ? trackNum : (trackNum is double ? trackNum.toInt() : (trackNum != null ? int.tryParse(trackNum.toString()) : null)),
                                                            isFree: false,
                                                          );
                                                        }
                                                      } else {
                                                        await _addToCartAndCheckout(
                                                          bookId: bookId,
                                                          bookName: bookName,
                                                          bookImage: bookImage,
                                                          price: audiobookPrice,
                                                          type: 'audiobook',
                                                          coinPrice: audiobookCoinPrice > 0 ? audiobookCoinPrice : null,
                                                        );
                                                      }
                                                    }
                                                  },
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
                                                      '${trackNum ?? ''}',
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
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
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
                                                                  horizontal: 8,
                                                                  vertical: 3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.green,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: Text(FFLocalizations.of(context).getVariableText(enText: 'Free', bnText: 'ফ্রি'), style: TextStyle(
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
                                                          color: FlutterFlowTheme
                                                                  .of(context)
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
                                                        child: Text(FFLocalizations.of(context).getVariableText(enText: 'Reviews', bnText: 'রিভিউসমূহ'), textAlign:
                                                              TextAlign.start,
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
                                                        child: Text(FFLocalizations.of(context).getVariableText(enText: 'View all', bnText: 'সব দেখুন'), textAlign:
                                                              TextAlign.end,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 15.0,
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
                                                          bool isReviewExpanded = false;
                                                          return Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        10.0,
                                                                        0.0,
                                                                        10.0),
                                                            child: Container(
                                                              width: 290.0,
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
                                                                            12.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize.max,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment.start,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          8.0),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          () {
                                                                            final img = getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.userDetails.image''',
                                                                                )?.toString() ??
                                                                                '';
                                                                            final userName = getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.userDetails.name''',
                                                                                )?.toString() ??
                                                                                'User';
                                                                            if (img.isEmpty) {
                                                                              return custom_widgets.AvatarPlaceholder(
                                                                                name: userName,
                                                                                size: 36.0,
                                                                              );
                                                                            }
                                                                            return Container(
                                                                              width: 36.0,
                                                                              height: 36.0,
                                                                              clipBehavior: Clip.antiAlias,
                                                                              decoration: BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                              ),
                                                                              child: CachedNetworkImage(
                                                                                fadeInDuration: Duration(milliseconds: 200),
                                                                                fadeOutDuration: Duration(milliseconds: 200),
                                                                                imageUrl: img.startsWith('http') ? img : '${FFAppConstants.imageUrl}$img',
                                                                                fit: BoxFit.cover,
                                                                                errorWidget: (context, error, stackTrace) => custom_widgets.AvatarPlaceholder(
                                                                                  name: userName,
                                                                                  size: 36.0,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }(),
                                                                          Expanded(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
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
                                                                                          fontSize: 14.0,
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
                                                                                          fontSize: 12.0,
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
                                                                                    width: 14.0,
                                                                                    height: 14.0,
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
                                                                                      fontSize: 13.0,
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
                                                                    StatefulBuilder(
                                                                      builder: (context, setStateBuilder) {
                                                                        final text = getJsonField(
                                                                          reviewListItem,
                                                                          r'''$.description''',
                                                                        ).toString();
                                                                        final isLong = text.length > 90;
                                                                        return Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              text,
                                                                              maxLines: isReviewExpanded ? null : 3,
                                                                              overflow: isReviewExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 14.0,
                                                                                    letterSpacing: 0.0,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            if (isLong)
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setStateBuilder(() {
                                                                                    isReviewExpanded = !isReviewExpanded;
                                                                                  });
                                                                                },
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.only(top: 4.0),
                                                                                  child: Text(
                                                                                    isReviewExpanded
                                                                                        ? FFLocalizations.of(context).getVariableText(enText: 'See less', bnText: 'কম দেখুন')
                                                                                        : FFLocalizations.of(context).getVariableText(enText: 'See more', bnText: 'আরও দেখুন'),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        );
                                                                      },
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
                                                    text: FFLocalizations.of(context).getVariableText(enText: 'Write a Review', bnText: 'রিভিউ লিখুন'),
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
                                                  child: Text(FFLocalizations.of(context).getVariableText(enText: 'Reviews', bnText: 'রিভিউসমূহ'), style: FlutterFlowTheme.of(context).bodyMedium
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
                                                              FFLocalizations.of(context).getVariableText(enText: 'No reviews yet', bnText: 'এখনো কোনো রিভিউ নেই'),
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
                                                              FFLocalizations.of(context).getVariableText(enText: 'Be the first to share your thoughts!', bnText: 'আপনার মতামত প্রথম শেয়ার করুন!'),
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
                                                            text: FFLocalizations.of(context).getVariableText(enText: 'Write a Review', bnText: 'রিভিউ লিখুন'),
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
                                  Builder(builder: (context) {
                                    final authorId = EbookGroup
                                            .getbookdetailsApiCall
                                            .authorid(
                                          bookDetailspageGetbookdetailsApiResponse
                                              .jsonBody,
                                        ) ??
                                        '';
                                    if (authorId.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          0.0, 16.0, 0.0, 0.0),
                                      child: FutureBuilder<ApiCallResponse>(
                                        future: EbookGroup.getbookbyauthorApiCall.call(
                                          authorId: authorId,
                                          token: FFAppState().token,
                                        ),
                                        builder: (context, snapshot) {
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
                                          final response = snapshot.data!;
                                          if (EbookGroup.getbookbyauthorApiCall.success(response.jsonBody) != 1) {
                                            return const SizedBox.shrink();
                                          }
                                          final books = EbookGroup.getbookbyauthorApiCall.bookDetailsList(response.jsonBody)
                                              ?.where((b) => b is Map && (b['_id']?.toString() ?? '') != bookId)
                                              .toList() ?? [];
                                          if (books.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 16.0),
                                                child: Text(
                                                  FFLocalizations.of(context).getVariableText(enText: 'More from author', bnText: 'লেখকের অন্যান্য বই'),
                                                  textAlign: TextAlign.start,
                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                    fontFamily: 'SF Pro Display',
                                                    fontSize: 18.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    lineHeight: 1.5,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    spacing: 5.0,
                                                    verticalDirection: VerticalDirection.down,
                                                    children: List.generate(
                                                      books.length,
                                                      (index) {
                                                        final item = books[index];
                                                        final itemId = getJsonField(item, r'''$._id''').toString();
                                                        final itemName = getJsonField(item, r'''$.name''').toString();
                                                        return wrapWithModel(
                                                          model: _model.mainBookComponentModels.getModel(
                                                            'author_$itemId',
                                                            index,
                                                          ),
                                                          updateCallback: () => safeSetState(() {}),
                                                          child: MainBookComponentWidget(
                                                            key: Key('Keyauthor_$itemId'),
                                                            image: '${FFAppConstants.bookImagesUrl}${getJsonField(item, r'''$.image''').toString()}',
                                                            bookName: itemName,
                                                            id: itemId,
                                                            imageHeight: 155,
                                                            isPurchased: _model.purchasedBookIds.contains(itemId),
                                                            price: getJsonField(item, r'''$.price''').toString(),
                                                            bookType: getJsonField(item, r'''$.type''')?.toString(),
                                                            discountAmount: getJsonField(item, r'''$.discount_amount''').toString(),
                                                            discountPercentage: getJsonField(item, r'''$.discount_percentage''').toString(),
                                                            authorsName: getJsonField(item, r'''$.author.name''').toString(),
                                                            isFav: functions.checkFavOrNot(
                                                              EbookGroup.getFavouriteBookCall.favouriteBookDetailsList(columnGetFavouriteBookResponse.jsonBody)?.toList(),
                                                              itemId,
                                                            ) == true,
                                                            indicator: (index == _model.authorRelatedIndex) && (_model.isAuthorRelated == true),
                                                            isFavAction: () async {
                                                              if (FFAppState().isLogin == true) {
                                                                _model.isAuthorRelated = true;
                                                                _model.authorRelatedIndex = index;
                                                                safeSetState(() {});
                                                                if (functions.checkFavOrNot(
                                                                  EbookGroup.getFavouriteBookCall.favouriteBookDetailsList(columnGetFavouriteBookResponse.jsonBody)?.toList(),
                                                                  itemId,
                                                                ) == true) {
                                                                  _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                    userId: FFAppState().userId,
                                                                    token: FFAppState().token,
                                                                    bookId: itemId,
                                                                  );
                                                                  safeSetState(() => _model.apiRequestCompleter1 = null);
                                                                  await _model.waitForApiRequestCompleted1();
                                                                  await actions.showCustomToastBottom(FFAppState().unFavText);
                                                                } else {
                                                                  _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                    userId: FFAppState().userId,
                                                                    token: FFAppState().token,
                                                                    bookId: itemId,
                                                                  );
                                                                  safeSetState(() => _model.apiRequestCompleter1 = null);
                                                                  await _model.waitForApiRequestCompleted1();
                                                                  await actions.showCustomToastBottom(FFAppState().favText);
                                                                }
                                                                FFAppState().clearGetFavouriteBookCacheCache();
                                                                _model.isAuthorRelated = false;
                                                                safeSetState(() {});
                                                              } else {
                                                                FFAppState().favChange = true;
                                                                FFAppState().bookId = itemId;
                                                                FFAppState().update(() {});
                                                                context.pushNamed(SignInPageWidget.routeName);
                                                              }
                                                              safeSetState(() {});
                                                            },
                                                            isMainTap: () async {
                                                              context.pushNamed(
                                                                BookDetailspageWidget.routeName,
                                                                queryParameters: {
                                                                  'name': serializeParam(itemName, ParamType.String),
                                                                  'image': serializeParam('${FFAppConstants.bookImagesUrl}${getJsonField(item, r'''$.image''').toString()}', ParamType.String),
                                                                  'id': serializeParam(itemId, ParamType.String),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    );
                                  }),
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
                                              child: Text(FFLocalizations.of(context).getVariableText(enText: 'Related books', bnText: 'একই ধরনের বইসমূহ'), textAlign: TextAlign.start,
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
                                                          VerticalDirection
                                                              .down,
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
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              MainBookComponentWidget(
                                                            key: Key(
                                                              'Keybek_${getJsonField(
                                                                authorRelatedbookDetailslistItem,
                                                                r'''$.name''',
                                                              ).toString()}',
                                                            ),
                                                            imageHeight: 155,
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
                                                            bookType:
                                                                getJsonField(
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
                                                                    userId: FFAppState()
                                                                        .userId,
                                                                    token: FFAppState()
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
                                                                    userId: FFAppState()
                                                                        .userId,
                                                                    token: FFAppState()
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

                                                              safeSetState(
                                                                  () {});
                                                            },
                                                            isMainTap:
                                                                () async {
                                                              context.pushNamed(
                                                                BookDetailspageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
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

// ═════════════════════════════════════════════════════════════════════════════
// Animated Episode Card
// ═════════════════════════════════════════════════════════════════════════════

class _AnimatedEpisodeCard extends StatefulWidget {
  const _AnimatedEpisodeCard({
    super.key,
    required this.track,
    required this.index,
    required this.theme,
    required this.isDark,
    required this.isPreview,
    required this.isLocked,
    required this.num,
    required this.title,
    required this.dur,
    required this.onTap,
  });

  final Map<String, dynamic> track;
  final int index;
  final dynamic theme;
  final bool isDark;
  final bool isPreview;
  final bool isLocked;
  final dynamic num;
  final String title;
  final String dur;
  final VoidCallback onTap;

  @override
  State<_AnimatedEpisodeCard> createState() => _AnimatedEpisodeCardState();
}

class _AnimatedEpisodeCardState extends State<_AnimatedEpisodeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    final isFree = widget.track['is_free'] == true;
    final isLocked = widget.isLocked;
    final brandColor = theme.primary as Color;

    final coinCost = (widget.track['chapter_price_coins'] as num?)?.toInt() ?? 0;
    final bdtCost = (widget.track['chapter_price_bdt'] as num?)?.toDouble() ?? 0.0;
    String lockedText = FFLocalizations.of(context).getVariableText(enText: 'Locked', bnText: 'লকড');
    if (coinCost > 0) {
       lockedText = '$coinCost ' + FFLocalizations.of(context).getVariableText(enText: 'Coins', bnText: 'কয়েন');
    } else if (bdtCost > 0) {
      lockedText = '৳${bdtCost.toStringAsFixed(0)}';
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) => _ctrl.forward(),
        onTapCancel: () => _ctrl.forward(),
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: isDark
                ? brandColor.withOpacity(0.08)
                : brandColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: brandColor.withOpacity(isLocked ? 0.12 : 0.30),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Episode number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(isLocked ? 0.15 : 1.0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: isLocked ? brandColor : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A2530),
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (widget.dur.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 10, color: theme.secondaryText as Color),
                            const SizedBox(width: 3),
                            Text(
                              widget.dur,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 10,
                                color: theme.secondaryText as Color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Free/Locked/Unlocked pill + play/lock button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(isLocked ? 0.07 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: brandColor.withOpacity(isLocked ? 0.15 : 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isLocked ? lockedText : (isFree ? FFLocalizations.of(context).getVariableText(enText: 'Free', bnText: 'ফ্রি') : FFLocalizations.of(context).getVariableText(enText: 'Unlocked', bnText: 'আনলকড')),
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? theme.secondaryText as Color : brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    // Play or Lock icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isLocked ? (theme.secondaryText as Color).withOpacity(0.15) : brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        color: isLocked ? theme.secondaryText as Color : Colors.white,
                        isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// See More Button
// ═════════════════════════════════════════════════════════════════════════════

class _SeeMoreButton extends StatefulWidget {
  const _SeeMoreButton({required this.remaining, required this.onTap});
  final int remaining;
  final VoidCallback onTap;

  @override
  State<_SeeMoreButton> createState() => _SeeMoreButtonState();
}

class _SeeMoreButtonState extends State<_SeeMoreButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withOpacity(isDark ? 0.2 : 0.08),
                theme.primary.withOpacity(isDark ? 0.12 : 0.04),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.primary.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.expand_more_rounded,
                color: theme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${FFLocalizations.of(context).getVariableText(enText: 'See All Episodes', bnText: 'সব পর্ব দেখুন')} (+${widget.remaining} ${FFLocalizations.of(context).getVariableText(enText: 'more', bnText: 'আরও')})',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Full Episodes List Page (opened from See More)
// ═════════════════════════════════════════════════════════════════════════════

class _EpisodesListPage extends StatelessWidget {
  const _EpisodesListPage({
    required this.bookName,
    required this.bookImage,
    required this.tracks,
    required this.onPlayTrack,
    required this.hasAudiobookAccess,
    this.audiobookFormat,
  });

  final String bookName;
  final String bookImage;
  final List<Map<String, dynamic>> tracks;
  final Future<void> Function(Map<String, dynamic> track) onPlayTrack;
  final bool hasAudiobookAccess;
  final Map<String, dynamic>? audiobookFormat;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: theme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 14, right: 16),
              title: Text(
                bookName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bookImage.isNotEmpty)
                    Image.network(
                      bookImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: theme.primary),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primary.withOpacity(0.55),
                          theme.primary.withOpacity(0.97),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text('${tracks.length} ' + FFLocalizations.of(context).getVariableText(enText: 'Episodes', bnText: 'পর্বসমূহ'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Track List
          tracks.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.headphones_outlined,
                            size: 56,
                            color: theme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(FFLocalizations.of(context).getVariableText(enText: 'No episodes available', bnText: 'কোনো এপিসোড পাওয়া যায়নি'),
                            style: theme.bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: theme.secondaryText,
                              letterSpacing: 0,
                            )),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final track = tracks[i];
                        final isFree = track['is_free'] == true;
                        final isUnlocked = track['is_unlocked'] == true;
                        final isLocked = !hasAudiobookAccess && !isFree && !isUnlocked;
                        final isPreview = track['is_preview'] == true || isFree;
                        final num = track['track_number'];
                        final title =
                            track['title']?.toString() ?? 'Episode ${i + 1}';
                        final dur = track['duration']?.toString() ?? '';

                        return _AnimatedEpisodeCard(
                          key: ValueKey('eplist_$i'),
                          track: track,
                          index: i,
                          theme: theme,
                          isDark: isDark,
                          isPreview: isPreview,
                          isLocked: isLocked,
                          num: num,
                          title: title,
                          dur: dur,
                          onTap: () => onPlayTrack(track),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
