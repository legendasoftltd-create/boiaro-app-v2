import 'package:a_i_ebook_app/pages/home_pages/home_page/image_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '/backend/boiaro_legacy_adapter.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/shimmers/home_shimmer/home_shimmer_widget.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';
import '/pages/cart_pages/cart_page_widget.dart';
import '/providers/cart_provider.dart';
import '/custom_code/ad_manager.dart';
import '/custom_code/widgets/ad_reward_dialog.dart';

enum HomeBookFilter { all, ebook, audiobook, hardcopy }

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({
    super.key,
    this.embeddedAudiobookMode = false,
  });

  /// When true (Audiobook tab shell), shows only the homepage feed for audiobooks
  /// — same sections as Home with the Audiobook filter — without logo row or format chips.
  final bool embeddedAudiobookMode;

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAudiobookLoading = false;
  bool _isEbookLoading = false;

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
    final body = await _postV2(
      'access/check',
      body: {'book_id': bookId, 'format': format},
      authRequired: true,
    );
    return body?['has_access'] == true;
  }

  Future<List<Map<String, dynamic>>> _fetchAudioTracks(String bookId) async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/books/$bookId/tracks');
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
    return body?['signed_url']?.toString();
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

  Future<String?> _fetchEbookSignedUrl(String bookId) async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final res = await http.post(
        uri,
        headers: _apiHeaders(authRequired: true),
        body: jsonEncode({'book_id': bookId}),
      );
      final decoded = jsonDecode(res.body);
      final body = decoded is Map<String, dynamic> ? decoded : null;
      final url = _extractUrlFromBody(body);
      if (url != null && url.trim().isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchEbookSignedUrlGuestAware(String bookId) async {
    try {
      final uri =
          Uri.parse('${FFAppConstants.mobileApiBaseUrl}/content/ebook-url');
      final guestRes = await http.post(
        uri,
        headers: _apiHeaders(authRequired: false),
        body: jsonEncode({'book_id': bookId}),
      );
      final decoded = jsonDecode(guestRes.body);
      final guestBody = decoded is Map<String, dynamic> ? decoded : null;
      final guestUrl = _extractUrlFromBody(guestBody);
      if (guestUrl != null && guestUrl.trim().isNotEmpty) return guestUrl;
    } catch (_) {}
    if (!FFAppState().isLogin) return null;
    return _fetchEbookSignedUrl(bookId);
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

  Future<void> _resumeAudiobookPlayer({
    required String bookId,
    required String bookName,
    required String bookImage,
    required String authorName,
  }) async {
    if (_isAudiobookLoading) return;
    setState(() {
      _isAudiobookLoading = true;
    });

    try {
      final hasAccess = FFAppState().isLogin &&
          await _hasFormatAccess(bookId: bookId, format: 'audiobook');

      final tracks = await _fetchAudioTracks(bookId);
      final effectiveTracks = List<Map<String, dynamic>>.from(tracks);
      if (effectiveTracks.isEmpty) {
        final fallback = await _fallbackAudioTrack(bookId);
        if (fallback != null) {
          effectiveTracks.add(fallback);
        } else {
          await actions.showCustomToastBottom('No tracks available');
          return;
        }
      }

      final chapters = <Map<String, dynamic>>[];
      Map<String, dynamic> urlsMap = const <String, dynamic>{};
      if (hasAccess && FFAppState().isLogin) {
        final batch = await _fetchBatchAudioUrls(bookId);
        final rawUrls = batch['urls'];
        if (rawUrls is Map) {
          urlsMap = Map<String, dynamic>.from(rawUrls);
        }
      }

      final previewPercent = 15;
      final rawPreviewTracks = effectiveTracks.length * (previewPercent / 100);
      final fullPreviewTracks =
          hasAccess ? effectiveTracks.length : rawPreviewTracks.floor();
      final hasPartialPreviewTrack = !hasAccess &&
          rawPreviewTracks > fullPreviewTracks &&
          fullPreviewTracks < effectiveTracks.length;
      final previewCount = hasAccess
          ? effectiveTracks.length
          : (fullPreviewTracks + (hasPartialPreviewTrack ? 1 : 0))
              .clamp(1, effectiveTracks.length);

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
          authRequired: hasAccess && FFAppState().isLogin,
        );
        if (signedUrl == null || signedUrl.isEmpty) {
          continue;
        }
        if (!hasAccess && !isTrackPreview) {
          continue;
        }
        final isPartialPreviewTrack =
            !hasAccess && hasPartialPreviewTrack && i == (previewCount - 1);
        final previewFraction = isPartialPreviewTrack
            ? (rawPreviewTracks - fullPreviewTracks).clamp(0.0, 1.0)
            : 1.0;

        chapters.add({
          'title': track['title']?.toString() ?? 'Track $trackNumber',
          'file': signedUrl,
          'track_number': trackNumber,
          'duration': track['duration']?.toString() ?? '',
          'isLocked': hasAccess ? false : !isTrackPreview,
          'isPreview': !hasAccess ? true : (track['is_preview'] == true),
          'previewFraction': previewFraction,
        });
      }

      if (chapters.isEmpty) {
        await actions.showCustomToastBottom(
          hasAccess
              ? 'Unable to load audiobook tracks'
              : 'No preview tracks available',
        );
        return;
      }

      final lastTrackNum =
          FFAppState().prefs.getInt('ff_homePageLastAudioTrackNumber') ?? 1;
      Map<String, dynamic> startChapter = chapters.first;
      final matchedIndex = chapters.indexWhere(
          (c) => (c['track_number']?.toString() ?? '') == '$lastTrackNum');
      if (matchedIndex >= 0) {
        startChapter = chapters[matchedIndex];
      }

      final isFree = FFAppState().prefs.getBool('ff_homePageLastAudioBookIsFree') ?? false;
      final playAudio = () async {
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
              'isPreviewMode': !hasAccess,
              'previewPercent': previewPercent,
              'isFree': isFree,
            },
            'chapter': startChapter,
          },
        );
      };

      if (isFree) {
        final canShowAd = await AdManager.canShowAd();
        if (canShowAd) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AdRewardDialog(
              bookImage: bookImage,
              onWatchAd: playAudio,
            ),
          );
        } else {
          await playAudio();
        }
      } else {
        await playAudio();
      }
    } catch (_) {
      await actions.showCustomToastBottom('Failed to load audiobook');
    } finally {
      if (mounted) {
        setState(() {
          _isAudiobookLoading = false;
        });
      }
    }
  }

  final animationsMap = <String, AnimationInfo>{};
  HomeBookFilter _selectedFilter = HomeBookFilter.all;

  String get _homepageCacheKey =>
      'homepage_${_selectedApiType().isEmpty ? 'all' : _selectedApiType()}';

  String _normalizeTypeValue(dynamic type) {
    if (type == null) {
      return '';
    }
    if (type is List) {
      return type.map((e) => e.toString().toLowerCase()).join(',');
    }
    return type.toString().toLowerCase();
  }

  String _normalizeSingleFormat(String raw) {
    final t = raw.toLowerCase().trim();
    if (t.isEmpty) return '';
    if (t.contains('audio')) return 'audiobook';
    if (t.contains('hard') || t.contains('print') || t.contains('paper')) {
      return 'hardcopy';
    }
    if (t.contains('ebook') ||
        t.contains('e-book') ||
        t.contains('epub') ||
        t.contains('pdf')) {
      return 'ebook';
    }
    return '';
  }

  String _resolveBookType(dynamic book) {
    final formats = getJsonField(book, r'''$.formats''');
    if (formats is List) {
      final found = <String>{};
      for (final row in formats) {
        if (row is! Map) continue;
        final normalized = _normalizeSingleFormat('${row['format'] ?? ''}');
        if (normalized.isNotEmpty) found.add(normalized);
      }
      if (found.isNotEmpty) {
        return found.join(',');
      }
    }
    final type = getJsonField(book, r'''$.type''') ??
        getJsonField(book, r'''$.bookType''') ??
        getJsonField(book, r'''$.book_type''') ??
        getJsonField(book, r'''$.format''');
    final raw = _normalizeTypeValue(type);
    if (raw.isEmpty) return raw;
    final parts = raw.split(RegExp(r'[,\s|/]+'));
    final normalized = <String>{};
    for (final p in parts) {
      final n = _normalizeSingleFormat(p);
      if (n.isNotEmpty) normalized.add(n);
    }
    if (normalized.isNotEmpty) {
      return normalized.join(',');
    }
    return raw;
  }

  bool _hasAudio(String type) => type.contains('audio');

  bool _hasEbook(String type) =>
      type.contains('ebook') ||
      type.contains('e-book') ||
      type.contains('epub') ||
      type.contains('pdf');

  bool _hasHardcopy(String type) =>
      type.contains('hard') || type.contains('print') || type.contains('paper');

  Future<void> _openBookDetails(dynamic book) async {
    context.pushNamed(
      BookDetailspageWidget.routeName,
      queryParameters: {
        'name': serializeParam(
          getJsonField(book, r'''$.name''').toString(),
          ParamType.String,
        ),
        'price': serializeParam(
          getJsonField(book, r'''$.price''').toString(),
          ParamType.String,
        ),
        'image': serializeParam(
          _resolveCoverUrl(
            getJsonField(book, r'''$.image''').toString(),
          ),
          ParamType.String,
        ),
        'id': serializeParam(
          getJsonField(book, r'''$._id''').toString(),
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  String _bookId(dynamic book) {
    return getJsonField(book, r'''$._id''')?.toString() ??
        getJsonField(book, r'''$.id''')?.toString() ??
        '';
  }

  ApiCallResponse _emptyCategorySectionsResponse() {
    return ApiCallResponse(
      BoiaroLegacyAdapter.legacyDataEnvelope(
        extra: const {'categorySections': <dynamic>[]},
      ),
      const {},
      200,
    );
  }

  List<dynamic> _pickHomeSectionBooks(List<dynamic> books) {
    return _filterBooks(books);
  }

  bool _matchesFilter(dynamic book) {
    if (_selectedFilter == HomeBookFilter.all) {
      return true;
    }
    final type = _resolveBookType(book);
    if (_selectedFilter == HomeBookFilter.ebook) {
      return _hasEbook(type);
    }
    if (_selectedFilter == HomeBookFilter.audiobook) {
      return _hasAudio(type);
    }
    if (_selectedFilter == HomeBookFilter.hardcopy) {
      return _hasHardcopy(type);
    }
    return false;
  }

  List<dynamic> _filterBooks(List<dynamic> books) {
    return books.where(_matchesFilter).toList();
  }

  bool get _allowsEbook =>
      _selectedFilter == HomeBookFilter.all ||
      _selectedFilter == HomeBookFilter.ebook;

  String _selectedApiType() {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return '';
      case HomeBookFilter.ebook:
        return 'ebook';
      case HomeBookFilter.audiobook:
        return 'audiobook';
      case HomeBookFilter.hardcopy:
        return 'hardcopy';
    }
  }

  String _selectedPopularSectionKey() {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return 'popularBooks';
      case HomeBookFilter.ebook:
        return 'popularEbooks';
      case HomeBookFilter.audiobook:
        return 'popularAudiobooks';
      case HomeBookFilter.hardcopy:
        return 'popularHardCopies';
    }
  }

  String _selectedPopularTitle() {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return 'Popular books';
      case HomeBookFilter.ebook:
        return 'Popular eBooks';
      case HomeBookFilter.audiobook:
        return 'Popular Audiobooks';
      case HomeBookFilter.hardcopy:
        return 'Popular Hardcopies';
    }
  }

  List<dynamic> _popularSectionSource({
    required List<dynamic> popularBooks,
    required List<dynamic> popularEbooks,
    required List<dynamic> popularAudiobooks,
    required List<dynamic> popularHardCopies,
  }) {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return popularBooks;
      case HomeBookFilter.ebook:
        return popularEbooks.isNotEmpty ? popularEbooks : popularBooks;
      case HomeBookFilter.audiobook:
        return popularAudiobooks;
      case HomeBookFilter.hardcopy:
        return popularHardCopies;
    }
  }

  String _selectedTrendingTitle() {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return 'Trending books';
      case HomeBookFilter.ebook:
        return 'Trending eBooks';
      case HomeBookFilter.audiobook:
        return 'Trending Audiobooks';
      case HomeBookFilter.hardcopy:
        return 'Trending Hardcopies';
    }
  }

  String _selectedNewTitle() {
    switch (_selectedFilter) {
      case HomeBookFilter.all:
        return 'New books';
      case HomeBookFilter.ebook:
        return 'New eBooks';
      case HomeBookFilter.audiobook:
        return 'New Audiobooks';
      case HomeBookFilter.hardcopy:
        return 'New Hardcopies';
    }
  }

  Future<void> _openHomepageSectionViewAll({
    required String sectionKey,
    required String title,
    String? type,
  }) async {
    await context.pushNamed(
      PopularBooksPageWidget.routeName,
      queryParameters: {
        'type': serializeParam(type ?? _selectedApiType(), ParamType.String),
        'sectionKey': serializeParam(sectionKey, ParamType.String),
        'title': serializeParam(title, ParamType.String),
      }.withoutNulls,
    );
  }

  double _parseRating(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Widget _buildFormatToggle(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(6.0),
      // decoration: BoxDecoration(
      //   color: FlutterFlowTheme.of(context).secondaryBackground,
      //   borderRadius: BorderRadius.circular(16.0),
      //   border: Border.all(
      //     color: FlutterFlowTheme.of(context).shadowColor,
      //   ),
      // ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildToggleItem(
              context,
              filter: HomeBookFilter.all,
              label: 'All',
              icon: Icons.sync_rounded,
            ),
            _buildToggleItem(
              context,
              filter: HomeBookFilter.ebook,
              label: 'eBook',
              icon: Icons.menu_book_rounded,
            ),
            _buildToggleItem(
              context,
              filter: HomeBookFilter.audiobook,
              label: 'Audiobook',
              icon: Icons.headphones_rounded,
            ),
            _buildToggleItem(
              context,
              filter: HomeBookFilter.hardcopy,
              label: 'Hardcopy',
              icon: Icons.local_library_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context, {
    required HomeBookFilter filter,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        if (_selectedFilter != filter) {
          safeSetState(() {
            _selectedFilter = filter;
            FFAppState().clearGetHomepageCacheCacheKey(_homepageCacheKey);
            _model.apiRequestCompleted2 = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).primaryText.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.0,
              color: isSelected
                  ? FlutterFlowTheme.of(context).primaryBackground
                  : FlutterFlowTheme.of(context).secondaryText,
            ),
            SizedBox(width: 6.0),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? FlutterFlowTheme.of(context).primaryBackground
                        : FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  double _safeRatio(int current, int total) {
    if (total <= 0) {
      return 0.0;
    }
    return (current / total).clamp(0.0, 1.0).toDouble();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatAudioProgressLabel(int positionSec, int durationSec) {
    if (durationSec <= 0) {
      return 'Progress unavailable';
    }
    final position = Duration(seconds: positionSec);
    final duration = Duration(seconds: durationSec);
    return '${_formatDuration(position)} / ${_formatDuration(duration)}';
  }

  String _resolveCoverUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${FFAppConstants.bookImagesUrl}$trimmed';
  }

  ApiCallResponse _emptyFavouriteResponse() => ApiCallResponse(
        {
          'data': {
            'success': 1,
            'message': 'Success',
            'favouriteBookDetails': <dynamic>[],
          },
        },
        const {},
        200,
      );

  Widget _buildResumeCard(
    BuildContext context, {
    required String title,
    required String bookAuthor,
    required String bookType,
    required String progressLabel,
    required double progressValue,
    required String imageUrl,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    String cleanAuthor(String author) {
      var s = author.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        s = s.substring(1, s.length - 1).trim();
      }
      if (s.startsWith('name:')) {
        s = s.substring(5).trim();
      } else if (s.contains('name:')) {
        final index = s.indexOf('name:');
        s = s.substring(index + 5).trim();
        if (s.contains(',')) {
          s = s.split(',')[0].trim();
        }
      }
      return s;
    }

    final trimmedAuthor = cleanAuthor(bookAuthor);
    final trimmedType = bookType.trim();
    final subtitleText = trimmedAuthor.isNotEmpty && trimmedType.isNotEmpty
        ? '$trimmedAuthor • $trimmedType'
        : (trimmedAuthor.isNotEmpty ? trimmedAuthor : trimmedType);
    final safeProgress = progressValue.clamp(0.0, 1.0).toDouble();
    final coverUrl = _resolveCoverUrl(imageUrl);
    final normalizedType = trimmedType.toLowerCase();
    final typeIcon = normalizedType.contains('audio')
        ? Icons.headphones_rounded
        : (normalizedType.contains('hard') || normalizedType.contains('print'))
            ? Icons.local_library_rounded
            : Icons.menu_book_rounded;
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 10.0, 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 8.0),
                      child: Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ),
                    Text(
                      progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 11.0,
                            letterSpacing: 0.0,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999.0),
                        child: LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 4.0,
                          backgroundColor: FlutterFlowTheme.of(context)
                              .primaryText
                              .withValues(alpha: .1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.0),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: coverUrl.isEmpty
                        ? Image.asset(
                            'assets/images/error_image.png',
                            width: 54.0,
                            height: 72.0,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            fadeInDuration: Duration(milliseconds: 200),
                            fadeOutDuration: Duration(milliseconds: 200),
                            imageUrl: coverUrl,
                            width: 54.0,
                            height: 72.0,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/error_image.png',
                              width: 54.0,
                              height: 72.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      right: 4.0,
                      bottom: 4.0,
                      child: Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primaryText
                              .withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Icon(
                          typeIcon,
                          size: 12.0,
                          color: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    if (widget.embeddedAudiobookMode) {
      _selectedFilter = HomeBookFilter.audiobook;
    }

    animationsMap.addAll({
      'columnOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.linear,
            delay: 50.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, -20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'categoryComponentOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final homeBody = SafeArea(
      top: true,
      child: Builder(
        builder: (context) {
          if (FFAppState().connected == true) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (!widget.embeddedAudiobookMode) ...[
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 130.0,
                                height: 40.0,
                                fit: BoxFit.contain,
                              ),
                              // Text(
                              //   'Hello,',
                              //   maxLines: 1,
                              //   style: FlutterFlowTheme.of(context)
                              //       .bodyMedium
                              //       .override(
                              //         fontFamily: 'SF Pro Display',
                              //         fontSize: 18.0,
                              //         letterSpacing: 0.0,
                              //         fontWeight: FontWeight.w600,
                              //         lineHeight: 1.5,
                              //       ),
                              // ),
                              // if (FFAppState().isLogin == true)
                              //   Text(
                              //     '${functions.capitalizeFirst('${getJsonField(
                              //       FFAppState().userDetail,
                              //       r'''$.firstname''',
                              //     ).toString()}')} 👋',
                              //     maxLines: 1,
                              //     style: FlutterFlowTheme.of(context)
                              //         .bodyMedium
                              //         .override(
                              //           fontFamily: 'SF Pro Display',
                              //           fontSize: 24.0,
                              //           letterSpacing: 0.0,
                              //           fontWeight: FontWeight.bold,
                              //           lineHeight: 1.5,
                              //         ),
                              //   ),
                            ],
                          ).animateOnPageLoad(
                              animationsMap['columnOnPageLoadAnimation']!),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          height: 36,
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(SearchPageWidget.routeName);
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .shadowColor),
                                // boxShadow: [
                                //   BoxShadow(
                                //     blurRadius: 16.0,
                                //     color: FlutterFlowTheme.of(context).shadowColor,
                                //     offset: Offset(
                                //       0.0,
                                //       4.0,
                                //     ),
                                //   )
                                // ],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: SvgPicture.asset(
                                        'assets/images/search.svg',
                                        width: 24.0,
                                        height: 24.0,
                                        fit: BoxFit.cover,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 0.0, 0.0),
                                      child: Text(
                                        FFLocalizations.of(context)
                                            .getText('search_hint'),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context
                                .pushNamed(NotificationsPageWidget.routeName);
                          },
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 16.0,
                                  color:
                                      FlutterFlowTheme.of(context).shadowColor,
                                  offset: Offset(
                                    0.0,
                                    4.0,
                                  ),
                                )
                              ],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/notifications_FILL0_wght400_GRAD0_opsz24.svg',
                                width: 22.0,
                                height: 22.0,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                    FlutterFlowTheme.of(context).primaryText,
                                    BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Consumer<CartProvider>(builder: (_, cart, __) {
                          return InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      CartPageWidget(),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 36.0,
                                  height: 36.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
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
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.shopping_cart_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 22.0,
                                        ),
                                      ),
                                      if (cart.itemCount > 0)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            width: 17.0,
                                            height: 17.0,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                cart.itemCount.toString(),
                                                style: TextStyle(
                                                  fontFamily: 'SF Pro Display',
                                                  color: Colors.white,
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
                    child: _buildFormatToggle(context),
                  ),
                ],
                Expanded(
                  child: FutureBuilder<ApiCallResponse>(
                    future:
                        Future.value(_emptyFavouriteResponse()).then((result) {
                      _model.apiRequestCompleted1 = true;
                      return result;
                    }),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return HomeShimmerWidget();
                      }
                      final containerGetFavouriteBookResponse = snapshot.data!;

                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(),
                        child: FutureBuilder<ApiCallResponse>(
                          future: FFAppState()
                              .getHomepageCache(
                            uniqueQueryKey: _homepageCacheKey,
                            requestFn: () => EbookGroup.getHomepageApiCall.call(
                              token: FFAppState().token,
                              type: _selectedApiType(),
                            ),
                          )
                              .then((result) {
                            _model.apiRequestCompleted2 = true;
                            return result;
                          }),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return HomeShimmerWidget();
                            }
                            final containerHomepageResponse = snapshot.data!;

                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(),
                              child: Builder(
                                builder: (context) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(),
                                    child: Builder(
                                      builder: (context) {
                                        return Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(),
                                          child: Builder(
                                            builder: (context) {
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                decoration: BoxDecoration(),
                                                child: Builder(
                                                  builder: (context) {
                                                    if (EbookGroup
                                                            .getHomepageApiCall
                                                            .success(
                                                          containerHomepageResponse
                                                              .jsonBody,
                                                        ) ==
                                                        2) {
                                                      return Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      16.0,
                                                                      0.0,
                                                                      16.0,
                                                                      0.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              EbookGroup
                                                                  .getHomepageApiCall
                                                                  .message(
                                                                containerHomepageResponse
                                                                    .jsonBody,
                                                              ),
                                                              'Message',
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      18.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      return FutureBuilder<
                                                          ApiCallResponse>(
                                                        future: FFAppState()
                                                            .getCategorySectionsCache(
                                                          uniqueQueryKey:
                                                              'category_sections',
                                                          requestFn: () =>
                                                              EbookGroup
                                                                  .getCategorySectionsApiCall
                                                                  .call(
                                                            token: FFAppState()
                                                                .token,
                                                          ),
                                                        ),
                                                        initialData:
                                                            _emptyCategorySectionsResponse(),
                                                        builder: (context,
                                                            categorySnapshot) {
                                                          final categorySections = EbookGroup
                                                                  .getCategorySectionsApiCall
                                                                  .categorySectionsList(
                                                                    categorySnapshot
                                                                        .data
                                                                        ?.jsonBody,
                                                                  )
                                                                  ?.toList() ??
                                                              [];
                                                          return _buildHomepageContent(
                                                            homepageJson:
                                                                containerHomepageResponse
                                                                    .jsonBody,
                                                            favouriteJson:
                                                                containerGetFavouriteBookResponse
                                                                    .jsonBody,
                                                            categorySections:
                                                                categorySections,
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ].addToStart(SizedBox(height: 24.0)),
            );
          } else {
            return Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Lottie.asset(
                'assets/jsons/No_Wifi.json',
                width: 150.0,
                height: 150.0,
                fit: BoxFit.contain,
                animate: true,
              ),
            );
          }
        },
      ),
    );

    if (widget.embeddedAudiobookMode) {
      return homeBody;
    }
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: homeBody,
    );
  }

  Widget _buildContinueReadingSection() {
    return Builder(
      builder: (context) {
        final showEbookResume =
            _allowsEbook &&
            FFAppState().homePageLiveReadBook.trim().isNotEmpty &&
            FFAppState().homePageCurrentPdfIndex > 0;
        final showAudioResume = (_selectedFilter == HomeBookFilter.all ||
                _selectedFilter == HomeBookFilter.audiobook) &&
            FFAppState().homePageLastAudioBookId.isNotEmpty;

        if (!showEbookResume && !showAudioResume) {
          return const SizedBox.shrink();
        }

        final totalIndex = FFAppState().homePageTotalPdfPageIndex;
        final currentIndex = FFAppState().homePageCurrentPdfIndex;
        final isEpubResume =
            FFAppState().homePageBookPdf.toLowerCase().contains('.epub');
        final isPercentBased = isEpubResume && totalIndex == 100;
        final ebookProgress = isPercentBased
            ? (currentIndex.clamp(0, 100) / 100)
            : _safeRatio(currentIndex, totalIndex);
        final ebookProgressLabel = isPercentBased
            ? '${currentIndex.clamp(0, 100)}%'
            : '${FFLocalizations.of(context).getText('page')} $currentIndex ${FFLocalizations.of(context).getText('of')} $totalIndex';
        final audioProgressLabel = _formatAudioProgressLabel(
          FFAppState().homePageLastAudioPositionSec,
          FFAppState().homePageLastAudioDurationSec,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
              child: Text(
                'Continue',
                maxLines: 1,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      lineHeight: 1.5,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 6),
              child: Row(
                children: [
                  if (showEbookResume)
                    Expanded(
                      child: _buildResumeCard(
                        context,
                        title: FFAppState().homePageBookName,
                        bookAuthor: FFAppState().homePageBookAuthor,
                        bookType: 'eBook',
                        progressLabel: ebookProgressLabel,
                        progressValue: ebookProgress,
                        imageUrl: FFAppState().homePageLiveReadBook,
                        isLoading: _isEbookLoading,
                        onTap: () async {
                          if (_isEbookLoading) return;
                          setState(() {
                            _isEbookLoading = true;
                          });
                          try {
                            final bookId = FFAppState().homePageBookId;
                            String? freshUrl;
                            if (FFAppState().isLogin) {
                              freshUrl = await _fetchEbookSignedUrl(bookId);
                            }
                            freshUrl ??= await _fetchEbookSignedUrlGuestAware(bookId);
                            if (freshUrl == null || freshUrl.trim().isEmpty) {
                              await actions.showCustomToastBottom(
                                  'Unable to load book link');
                              return;
                            }
                            FFAppState().homePageBookPdf = freshUrl;
                            FFAppState().update(() {});

                            await context.pushNamed(
                              ReadBookCustomPageWidget.routeName,
                              queryParameters: {
                                'pdf': serializeParam(
                                  freshUrl,
                                  ParamType.String,
                                ),
                                'id': serializeParam(
                                  FFAppState().homePageBookId,
                                  ParamType.String,
                                ),
                                'name': serializeParam(
                                  FFAppState().homePageBookName,
                                  ParamType.String,
                                ),
                                'author': serializeParam(
                                  FFAppState().homePageBookAuthor,
                                  ParamType.String,
                                ),
                                'image': serializeParam(
                                  FFAppState().homePageLiveReadBook,
                                  ParamType.String,
                                ),
                              }.withoutNulls,
                            );
                          } catch (_) {
                            await actions.showCustomToastBottom('Failed to load book');
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isEbookLoading = false;
                              });
                            }
                          }
                        },
                      ).animateOnPageLoad(
                          animationsMap['containerOnPageLoadAnimation']!),
                    ),
                  if (showEbookResume && showAudioResume)
                    const SizedBox(width: 12),
                  if (showAudioResume)
                    Expanded(
                      child: _buildResumeCard(
                        context,
                        title: FFAppState().homePageLastAudioBookName,
                        bookAuthor: FFAppState().homePageLastAudioBookAuthor,
                        bookType: 'Audiobook',
                        progressLabel: audioProgressLabel,
                        progressValue: FFAppState().homePageLastAudioProgress,
                        imageUrl: FFAppState().homePageLastAudioBookImage,
                        isLoading: _isAudiobookLoading,
                        onTap: () async {
                          await _resumeAudiobookPlayer(
                            bookId: FFAppState().homePageLastAudioBookId,
                            bookName: FFAppState().homePageLastAudioBookName,
                            bookImage: FFAppState().homePageLastAudioBookImage,
                            authorName:
                                FFAppState().homePageLastAudioBookAuthor,
                          );
                        },
                      ).animateOnPageLoad(
                          animationsMap['containerOnPageLoadAnimation']!),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title, {
    Future<void> Function()? onViewAll,
    double fontSize = 17.0,
    EdgeInsetsGeometry padding =
        const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 3),
  }) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'SF Pro Display',
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  lineHeight: 1.5,
                ),
          ),
          if (onViewAll != null)
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async => onViewAll(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  FFLocalizations.of(context).getText('view_all'),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.0,
                        color: Colors.white,
                        lineHeight: 1.5,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(dynamic homepageJson) {
    final sliders = EbookGroup.getHomepageApiCall
            .sliderDetailsList(homepageJson)
            ?.toList() ??
        [];
    if (sliders.isNotEmpty) {
      return BannerSlider(
        sliderItems: sliders,
        onOpenBook: _openBookDetails,
      );
    }
    // Audiobook-tab homepage requests often omit `slider`; reuse the same
    // hero strip as Home by loading the unfiltered homepage cache for sliders only.
    if (!widget.embeddedAudiobookMode) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<ApiCallResponse>(
      future: FFAppState().getHomepageCache(
        uniqueQueryKey: 'homepage_all',
        requestFn: () => EbookGroup.getHomepageApiCall.call(
          token: FFAppState().token,
          type: '',
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 200,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        final body = snapshot.data!.jsonBody;
        final fallback =
            EbookGroup.getHomepageApiCall.sliderDetailsList(body)?.toList() ??
                [];
        if (fallback.isEmpty) {
          return const SizedBox.shrink();
        }
        return BannerSlider(
          sliderItems: fallback,
          onOpenBook: _openBookDetails,
        );
      },
    );
  }

  Widget _buildCategoriesSection(dynamic homepageJson) {
    final items = (EbookGroup.getHomepageApiCall
                .categoryDetailsList(homepageJson)
                ?.toList() ??
            [])
        .toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          FFLocalizations.of(context).getText('categories_title'),
          onViewAll: () async {
            context.pushNamed(CategoriesScreenWidget.routeName);
          },
        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation1']!),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0.0 : 16.0,
                ),
                child: wrapWithModel(
                  model: _model.categoryComponentModels1.getModel(
                    getJsonField(item, r'''$.name''').toString(),
                    index,
                  ),
                  updateCallback: () => safeSetState(() {}),
                  child: CategoryComponentWidget(
                    key: Key(
                      'category_${getJsonField(item, r'''$._id''').toString()}',
                    ),
                    icon:
                        '${FFAppConstants.webUrl}${getJsonField(item, r'''$.icon''').toString()}',
                    name: getJsonField(item, r'''$.name''').toString(),
                    isSmall: true,
                    onMainTap: () async {
                      context.pushNamed(
                        GetBookByCategoryPageWidget.routeName,
                        queryParameters: {
                          'id': serializeParam(
                            getJsonField(item, r'''$._id''').toString(),
                            ParamType.String,
                          ),
                          'name': serializeParam(
                            getJsonField(item, r'''$.name''').toString(),
                            ParamType.String,
                          ),
                        }.withoutNulls,
                      );
                    },
                  ),
                ),
              ).animateOnPageLoad(
                  animationsMap['categoryComponentOnPageLoadAnimation']!);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorsSection(dynamic homepageJson) {
    final items = (EbookGroup.getHomepageApiCall
                .authorDetailsList(homepageJson)
                ?.toList() ??
            [])
        .toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          FFLocalizations.of(context).getText('best_authors_title'),
          onViewAll: () async {
            context.pushNamed(BestAuthorPageWidget.routeName);
          },
        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation3']!),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0.0 : 16.0,
                ),
                child: wrapWithModel(
                  model: _model.categoryComponentModels2.getModel(
                    getJsonField(item, r'''$.name''').toString(),
                    index,
                  ),
                  updateCallback: () => safeSetState(() {}),
                  child: CategoryComponentWidget(
                    key: Key(
                      'author_${getJsonField(item, r'''$._id''').toString()}',
                    ),
                    icon:
                        '${FFAppConstants.imageUrl}${getJsonField(item, r'''$.image''').toString()}',
                    name: getJsonField(item, r'''$.name''').toString(),
                    isSmall: true,
                    onMainTap: () async {
                      context.pushNamed(
                        AboutAuthorPageWidget.routeName,
                        queryParameters: {
                          'name': serializeParam(
                            getJsonField(item, r'''$.name''').toString(),
                            ParamType.String,
                          ),
                          'authorImage': serializeParam(
                            '${FFAppConstants.imageUrl}${getJsonField(item, r'''$.image''').toString()}',
                            ParamType.String,
                          ),
                          'authorId': serializeParam(
                            getJsonField(item, r'''$._id''').toString(),
                            ParamType.String,
                          ),
                        }.withoutNulls,
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNarratorsSection(dynamic homepageJson) {
    final raw = EbookGroup.getHomepageApiCall.narratorDetailsList(homepageJson);
    if (raw == null || raw.isEmpty) {
      return const SizedBox.shrink();
    }
    final items = raw.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          FFLocalizations.of(context).getText('featured_narrators_title'),
          onViewAll: () async {
            context.pushNamed(BestNarratorPageWidget.routeName);
          },
        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation3']!),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0.0 : 16.0,
                ),
                child: wrapWithModel(
                  model: _model.categoryComponentModels3.getModel(
                    getJsonField(item, r'''$.name''').toString(),
                    index,
                  ),
                  updateCallback: () => safeSetState(() {}),
                  child: CategoryComponentWidget(
                    key: Key(
                      'narrator_${getJsonField(item, r'''$._id''').toString()}',
                    ),
                    icon:
                        '${FFAppConstants.imageUrl}${getJsonField(item, r'''$.image''').toString()}',
                    name: getJsonField(item, r'''$.name''').toString(),
                    isSmall: true,
                    onMainTap: () async {
                      context.pushNamed(
                        AboutNarratorPageWidget.routeName,
                        queryParameters: {
                          'name': serializeParam(
                            getJsonField(item, r'''$.name''').toString(),
                            ParamType.String,
                          ),
                          'narratorImage': serializeParam(
                            '${FFAppConstants.imageUrl}${getJsonField(item, r'''$.image''').toString()}',
                            ParamType.String,
                          ),
                          'narratorId': serializeParam(
                            getJsonField(item, r'''$._id''').toString(),
                            ParamType.String,
                          ),
                        }.withoutNulls,
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSection({
    required List<dynamic> books,
    required dynamic favouriteJson,
  }) {
    final items = _filterBooks(books);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          FFLocalizations.of(context).getText('popular_books_title'),
          onViewAll: () async {
            context.pushNamed(
              PopularBooksPageWidget.routeName,
              queryParameters: {
                'type': serializeParam(_selectedApiType(), ParamType.String),
                'sectionKey': serializeParam(
                  _selectedPopularSectionKey(),
                  ParamType.String,
                ),
                'title':
                    serializeParam(_selectedPopularTitle(), ParamType.String),
              }.withoutNulls,
            );
          },
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final id = _bookId(item);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: wrapWithModel(
                  model: _model.listMainContainerComponentModels.getModel(
                    'popular_$id',
                    index,
                  ),
                  updateCallback: () => safeSetState(() {}),
                  child: ListMainContainerComponentWidget(
                    image:
                        '${FFAppConstants.bookImagesUrl}${getJsonField(item, r'''$.image''').toString()}',
                    name: getJsonField(item, r'''$.name''').toString(),
                    id: id,
                    authorName:
                        getJsonField(item, r'''$.author.name''').toString(),
                    averageRating: _parseRating(
                      getJsonField(item, r'''$.averageRating'''),
                    ),
                    isPurchased: _model.purchasedBookIds.contains(id),
                    bookType: _resolveBookType(item),
                    indicator: (index == _model.popularIndex) &&
                        (_model.isPopular == true),
                    width: 280.0,
                    isFav: functions.checkFavOrNot(
                          EbookGroup.getFavouriteBookCall
                              .favouriteBookDetailsList(favouriteJson)
                              ?.toList(),
                          id,
                        ) ==
                        true,
                    isFavAction: () async {
                      _model.isPopular = true;
                      _model.popularIndex = index;
                      safeSetState(() {});
                      final currentlyFav = functions.checkFavOrNot(
                            EbookGroup.getFavouriteBookCall
                                .favouriteBookDetailsList(favouriteJson)
                                ?.toList(),
                            id,
                          ) ==
                          true;
                      if (!FFAppState().isLogin) {
                        FFAppState().favChange = true;
                        FFAppState().bookId = id;
                        FFAppState().update(() {});
                        context.pushNamed(SignInPageWidget.routeName);
                      } else if (currentlyFav) {
                        await EbookGroup.removeFavouritebookCall.call(
                          userId: FFAppState().userId,
                          token: FFAppState().token,
                          bookId: id,
                        );
                        await actions.showCustomToastBottom(
                          FFAppState().unFavText,
                        );
                      } else {
                        await EbookGroup.addFavouriteBookApiCall.call(
                          userId: FFAppState().userId,
                          token: FFAppState().token,
                          bookId: id,
                        );
                        await actions.showCustomToastBottom(
                          FFAppState().favText,
                        );
                      }
                      safeSetState(() {
                        FFAppState().clearGetFavouriteBookCacheCache();
                        _model.apiRequestCompleted1 = false;
                        _model.isPopular = false;
                      });
                      await _model.waitForApiRequestCompleted1();
                    },
                    onMainTap: () async {
                      await _openBookDetails(item);
                    },
                  ),
                ),
              );
            })
                .addToStart(const SizedBox(width: 5))
                .addToEnd(const SizedBox(width: 5)),
          ),
        ),
      ],
    );
  }

  Widget _buildHomepageContent({
    required dynamic homepageJson,
    required dynamic favouriteJson,
    required List<dynamic> categorySections,
  }) {
    final newBooks =
        EbookGroup.getHomepageApiCall.newBookList(homepageJson)?.toList() ?? [];
    final trendingBooks = EbookGroup.getHomepageApiCall
            .trendingBookList(homepageJson)
            ?.toList() ??
        [];
    final popularBooks =
        EbookGroup.getHomepageApiCall.popularBookList(homepageJson)?.toList() ??
            [];
    final freeBooks =
        EbookGroup.getHomepageApiCall.freeBookList(homepageJson)?.toList() ??
            [];
    final topTen = EbookGroup.getHomepageApiCall
            .topTenMostReadList(homepageJson)
            ?.toList() ??
        [];
    final becauseYouRead = EbookGroup.getHomepageApiCall
            .becauseYouReadList(homepageJson)
            ?.toList() ??
        [];
    final editorsPick =
        EbookGroup.getHomepageApiCall.editorsPickList(homepageJson)?.toList() ??
            [];
    final popularAudiobooks = EbookGroup.getHomepageApiCall
            .popularAudiobookList(homepageJson)
            ?.toList() ??
        [];
    final popularHardCopies = EbookGroup.getHomepageApiCall
            .popularHardCopyList(homepageJson)
            ?.toList() ??
        [];
    final popularEbooks = EbookGroup.getHomepageApiCall
            .popularEbookList(homepageJson)
            ?.toList() ??
        [];

    return RefreshIndicator(
      key: const Key('RefreshIndicator_hiaxgz4b'),
      color: FlutterFlowTheme.of(context).primary,
      onRefresh: () async {
        safeSetState(() {
          FFAppState().clearGetFavouriteBookCacheCache();
          FFAppState().clearGetHomepageCacheCache();
          FFAppState().clearGetCategorySectionsCacheCache();
          _model.apiRequestCompleted1 = false;
          _model.apiRequestCompleted2 = false;
        });
        await Future.wait([
          _model.waitForApiRequestCompleted1(),
          _model.waitForApiRequestCompleted2(),
        ]);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSliderSection(homepageJson),
          _buildCategoriesSection(homepageJson),
          _buildContinueReadingSection(),
          _buildBookStripSection(
            title: FFLocalizations.of(context).getText('new_books_title'),
            sectionKey: 'new_books',
            books: newBooks,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              context.pushNamed(
                NewBooksPageWidget.routeName,
                queryParameters: {
                  'type': serializeParam(_selectedApiType(), ParamType.String),
                  'title':
                      serializeParam(_selectedNewTitle(), ParamType.String),
                }.withoutNulls,
              );
            },
          ),
          _buildBookStripSection(
            title: FFLocalizations.of(context).getText('trending_books_title'),
            sectionKey: 'trending_books',
            books: trendingBooks,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              context.pushNamed(
                TrendingBooksPageWidget.routeName,
                queryParameters: {
                  'type': serializeParam(_selectedApiType(), ParamType.String),
                  'title': serializeParam(
                      _selectedTrendingTitle(), ParamType.String),
                }.withoutNulls,
              );
            },
          ),
          _buildAuthorsSection(homepageJson),
          _buildNarratorsSection(homepageJson),
          _buildHomeLibraryPromo(),
          _buildPopularSection(
            books: _popularSectionSource(
              popularBooks: popularBooks,
              popularEbooks: popularEbooks,
              popularAudiobooks: popularAudiobooks,
              popularHardCopies: popularHardCopies,
            ),
            favouriteJson: favouriteJson,
          ),
          _buildBookStripSection(
            title: 'Top 10 Most Read',
            sectionKey: 'top_10_most_read',
            books: topTen,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              await _openHomepageSectionViewAll(
                sectionKey: 'topMostRead',
                title: 'Top 10 Most Read',
              );
            },
          ),
          _buildBookStripSection(
            title: 'Free Books',
            sectionKey: 'free_books',
            books: freeBooks,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              await _openHomepageSectionViewAll(
                sectionKey: 'freeBooks',
                title: 'Free Books',
              );
            },
          ),
          _buildBookStripSection(
            title: 'Editor\'s Pick',
            sectionKey: 'editors_pick',
            books: editorsPick,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              await _openHomepageSectionViewAll(
                sectionKey: 'editorsPick',
                title: 'Editor\'s Pick',
              );
            },
          ),
          _buildBookStripSection(
            title: 'Because You Read',
            sectionKey: 'because_you_read',
            books: becauseYouRead,
            favouriteJson: favouriteJson,
            onViewAll: () async {
              await _openHomepageSectionViewAll(
                sectionKey: 'becauseYouRead',
                title: 'Because You Read',
              );
            },
          ),
          if (_selectedFilter == HomeBookFilter.all ||
              _selectedFilter == HomeBookFilter.audiobook)
            _buildBookStripSection(
              title: 'Popular Audiobooks',
              sectionKey: 'popular_audiobooks',
              books: popularAudiobooks,
              favouriteJson: favouriteJson,
              onViewAll: () async {
                await _openHomepageSectionViewAll(
                  sectionKey: 'popularAudiobooks',
                  title: 'Popular Audiobooks',
                  type: 'audiobook',
                );
              },
            ),
          if (_selectedFilter == HomeBookFilter.all ||
              _selectedFilter == HomeBookFilter.hardcopy)
            _buildBookStripSection(
              title: 'Hard Copies',
              sectionKey: 'hard_copies',
              books: popularHardCopies,
              favouriteJson: favouriteJson,
              onViewAll: () async {
                await _openHomepageSectionViewAll(
                  sectionKey: 'popularHardCopies',
                  title: 'Hard Copies',
                  type: 'hardcopy',
                );
              },
            ),
          _buildDynamicCategorySections(
            sections: categorySections,
            favouriteJson: favouriteJson,
          ),
        ],
      ),
    );
  }

  Widget _buildBookStripSection({
    required String title,
    required String sectionKey,
    required List<dynamic> books,
    required dynamic favouriteJson,
    Future<void> Function()? onViewAll,
  }) {
    final picked = _pickHomeSectionBooks(books);
    if (picked.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title,
          onViewAll: onViewAll,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0.0, 0, 0.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 10.0,
              children: List.generate(picked.length, (idx) {
                final item = picked[idx];
                final id = _bookId(item);
                return wrapWithModel(
                  model: _model.mainBookComponentModels.getModel(
                    '${sectionKey}_$id',
                    idx + (sectionKey.hashCode & 0x3fffffff),
                  ),
                  updateCallback: () => safeSetState(() {}),
                  child: MainBookComponentWidget(
                    key: Key('${sectionKey}_$id'),
                    image:
                        '${FFAppConstants.bookImagesUrl}${getJsonField(item, r'''$.image''').toString()}',
                    bookName: getJsonField(item, r'''$.name''').toString(),
                    price: getJsonField(item, r'''$.price''').toString(),
                    bookType: getJsonField(item, r'''$.type''')?.toString(),
                    discountAmount:
                        getJsonField(item, r'''$.discount_amount''').toString(),
                    discountPercentage: getJsonField(
                      item,
                      r'''$.discount_percentage''',
                    ).toString(),
                    id: id,
                    isPurchased: _model.purchasedBookIds.contains(id),
                    authorsName:
                        getJsonField(item, r'''$.author.name''').toString(),
                    isFav: functions.checkFavOrNot(
                          EbookGroup.getFavouriteBookCall
                              .favouriteBookDetailsList(favouriteJson)
                              ?.toList(),
                          id,
                        ) ==
                        true,
                    isFavAction: () async {
                      if (!FFAppState().isLogin) {
                        FFAppState().favChange = true;
                        FFAppState().bookId = id;
                        FFAppState().update(() {});
                        context.pushNamed(SignInPageWidget.routeName);
                        return;
                      }
                      final currentlyFav = functions.checkFavOrNot(
                            EbookGroup.getFavouriteBookCall
                                .favouriteBookDetailsList(favouriteJson)
                                ?.toList(),
                            id,
                          ) ==
                          true;
                      if (currentlyFav) {
                        await EbookGroup.removeFavouritebookCall.call(
                          userId: FFAppState().userId,
                          token: FFAppState().token,
                          bookId: id,
                        );
                        await actions.showCustomToastBottom(
                          FFAppState().unFavText,
                        );
                      } else {
                        await EbookGroup.addFavouriteBookApiCall.call(
                          userId: FFAppState().userId,
                          token: FFAppState().token,
                          bookId: id,
                        );
                        await actions.showCustomToastBottom(
                          FFAppState().favText,
                        );
                      }
                      safeSetState(() {
                        FFAppState().clearGetFavouriteBookCacheCache();
                        _model.apiRequestCompleted1 = false;
                      });
                      await _model.waitForApiRequestCompleted1();
                    },
                    isMainTap: () async {
                      await _openBookDetails(item);
                    },
                  ),
                );
              }).addToStart(const SizedBox(width: 8)),
            ),
          ),
        ),
      ],
    );
  }

  String _categorySectionTitle(dynamic section) {
    final title =
        getJsonField(section, r'''$.title''')?.toString().trim() ?? '';
    if (title.isNotEmpty && title.toLowerCase() != 'null') {
      return title;
    }
    return getJsonField(section, r'''$.category.name''')?.toString().trim() ??
        '';
  }

  Future<void> _openCategorySection(dynamic section) async {
    final categoryId =
        getJsonField(section, r'''$.category_id''')?.toString().trim() ?? '';
    if (categoryId.isEmpty) {
      return;
    }
    context.pushNamed(
      GetBookByCategoryPageWidget.routeName,
      queryParameters: {
        'id': serializeParam(categoryId, ParamType.String),
        'name':
            serializeParam(_categorySectionTitle(section), ParamType.String),
      }.withoutNulls,
    );
  }

  Widget _buildDynamicCategorySections({
    required List<dynamic> sections,
    required dynamic favouriteJson,
  }) {
    final widgets = <Widget>[];
    for (final section in sections) {
      final title = _categorySectionTitle(section);
      final books =
          (getJsonField(section, r'''$.books''', true) as List?)?.toList() ??
              [];
      if (title.isEmpty || books.isEmpty) {
        continue;
      }
      final picked = _pickHomeSectionBooks(books);
      if (picked.isEmpty) {
        continue;
      }
      final sectionId = getJsonField(section, r'''$.id''')?.toString().trim();
      final fallbackCategoryId =
          getJsonField(section, r'''$.category_id''')?.toString().trim() ?? '';
      widgets.add(
        _buildBookStripSection(
          title: title,
          sectionKey:
              'category_section_${sectionId?.isNotEmpty == true ? sectionId : fallbackCategoryId}',
          books: books,
          favouriteJson: favouriteJson,
          onViewAll: fallbackCategoryId.isEmpty
              ? null
              : () => _openCategorySection(section),
        ),
      );
    }
    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(children: widgets);
  }

  Widget _buildHomeLibraryPromo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
              FlutterFlowTheme.of(context).secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FFLocalizations.of(context).getText('home_app_promo_title'),
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.bold,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              FFLocalizations.of(context).getText('home_app_promo_body'),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
