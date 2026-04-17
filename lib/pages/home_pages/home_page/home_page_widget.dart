import 'package:a_i_ebook_app/pages/home_pages/home_page/image_slider.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/list_main_container_component/list_main_container_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';
import '/pages/empty_components/blank_component/blank_component_widget.dart';
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
import '/pages/latest_screen/new_books_page_widget.dart';
import '/providers/cart_provider.dart';

enum HomeBookFilter { all, ebook, audiobook, hardcopy }

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};
  HomeBookFilter _selectedFilter = HomeBookFilter.all;

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
    final type = _resolveBookType(book);
    if (_hasAudio(type)) {
      context.pushNamed(
        AudiobookDetailsPageWidget.routeName,
        extra: <String, dynamic>{
          'audiobook': book,
        },
      );
      return;
    }

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
          '${FFAppConstants.bookImagesUrl}${getJsonField(book, r'''$.image''').toString()}',
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

  int _bookReads(dynamic book) {
    final raw = getJsonField(book, r'''$.total_reads''') ??
        getJsonField(book, r'''$.totalReads''');
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  List<dynamic> _pickHomeSectionBooks(List<dynamic> books, {int limit = 3}) {
    final filtered = _filterBooks(books);
    if (filtered.isEmpty) {
      return [];
    }
    if (_selectedFilter != HomeBookFilter.all) {
      // return filtered.take(limit).toList();
      return filtered;
    }

    final picked = <dynamic>[];
    final usedIds = <String>{};
    void addBook(dynamic book) {
      final id = _bookId(book);
      if (usedIds.contains(id)) {
        return;
      }
      usedIds.add(id);
      picked.add(book);
    }

    final ebooks =
        filtered.where((book) => _hasEbook(_resolveBookType(book))).toList();
    final audios =
        filtered.where((book) => _hasAudio(_resolveBookType(book))).toList();
    final hardcopies =
        filtered.where((book) => _hasHardcopy(_resolveBookType(book))).toList();

    if (ebooks.isNotEmpty) addBook(ebooks.first);
    if (audios.isNotEmpty && picked.length < limit) addBook(audios.first);
    if (hardcopies.isNotEmpty && picked.length < limit) {
      addBook(hardcopies.first);
    }

    for (final book in filtered) {
      if (picked.length >= limit) {
        break;
      }
      addBook(book);
    }

    return picked;
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
          safeSetState(() => _selectedFilter = filter);
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

  Widget _buildResumeCard(
    BuildContext context, {
    required String title,
    required String bookAuthor,
    required String bookType,
    required String progressLabel,
    required double progressValue,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final trimmedAuthor = bookAuthor.trim();
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
      onTap: onTap,
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
                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 8.0),
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
                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999.0),
                        child: LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 4.0,
                          backgroundColor:
                              FlutterFlowTheme.of(context).primaryText.withValues(alpha: .1),
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
                        color:
                            FlutterFlowTheme.of(context).primaryBackground,
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
      if (FFAppState().isLogin) {
        await _loadPurchasedBooks();
      }
      safeSetState(() {});
    });
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
        final bookIds = EbookGroup.userBookPurchaseRecordsApiCall.bookId(
          response.jsonBody ?? '',
        );
        _model.purchasedBookIds = bookIds ?? [];
        safeSetState(() {});
      }
    } catch (e) {
      debugPrint('Error loading purchased books: $e');
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Builder(
          builder: (context) {
            if (FFAppState().connected == true) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
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
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          border: Border.all(color: FlutterFlowTheme.of(context).shadowColor),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                                  FFLocalizations.of(context).getText('search_hint'),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
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
                                colorFilter: ColorFilter.mode(FlutterFlowTheme.of(context).primaryText, BlendMode.srcIn),
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
                  Expanded(
                    child: FutureBuilder<ApiCallResponse>(
                      future: FFAppState()
                          .getFavouriteBookCache(
                        requestFn: () => EbookGroup.getFavouriteBookCall.call(
                          userId: FFAppState().userId,
                          token: FFAppState().token,
                        ),
                      )
                          .then((result) {
                        _model.apiRequestCompleted1 = true;
                        return result;
                      }),
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
                        if (!snapshot.hasData) {
                          return HomeShimmerWidget();
                        }
                        final containerGetFavouriteBookResponse =
                            snapshot.data!;

                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(),
                          child: FutureBuilder<ApiCallResponse>(
                            future: FFAppState()
                                .getCategoriesCache(
                              requestFn: () =>
                                  EbookGroup.getcategoriesApiCall.call(),
                            )
                                .then((result) {
                              _model.apiRequestCompleted4 = true;
                              return result;
                            }),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return BlankComponentWidget();
                              }
                              final containerGetcategoriesApiResponse =
                                  snapshot.data!;

                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(),
                                child: FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .getTrendingBooksCache(
                                    requestFn: () => EbookGroup
                                        .getTrendingBooksApiCall
                                        .call(),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted2 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return HomeShimmerWidget();
                                    }
                                    final containerGetTrendingBooksApiResponse =
                                        snapshot.data!;

                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(),
                                      child: FutureBuilder<ApiCallResponse>(
                                        future: FFAppState()
                                            .getauthorsCache(
                                          requestFn: () => EbookGroup
                                              .getauthorsApiCall
                                              .call(),
                                        )
                                            .then((result) {
                                          _model.apiRequestCompleted5 = true;
                                          return result;
                                        }),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return HomeShimmerWidget();
                                          }
                                          final containerGetauthorsApiResponse =
                                              snapshot.data!;

                                          return Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(),
                                            child:
                                                FutureBuilder<ApiCallResponse>(
                                              future: FFAppState()
                                                  .popularBookCache(
                                                requestFn: () => EbookGroup
                                                    .getPopularBooksApiCall
                                                    .call(),
                                              )
                                                  .then((result) {
                                                _model.apiRequestCompleted3 =
                                                    true;
                                                return result;
                                              }),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return HomeShimmerWidget();
                                                }
                                                final containerGetPopularBooksApiResponse =
                                                    snapshot.data!;

                                                return Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(),
                                                  child: Builder(
                                                    builder: (context) {
                                                      if ((EbookGroup
                                                                  .getcategoriesApiCall
                                                                  .success(
                                                                containerGetcategoriesApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getTrendingBooksApiCall
                                                                  .success(
                                                                containerGetTrendingBooksApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getauthorsApiCall
                                                                  .success(
                                                                containerGetauthorsApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2) ||
                                                          (EbookGroup
                                                                  .getPopularBooksApiCall
                                                                  .success(
                                                                containerGetPopularBooksApiResponse
                                                                    .jsonBody,
                                                              ) ==
                                                              2)) {
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
                                                                    .getTrendingBooksApiCall
                                                                    .message(
                                                                  containerGetTrendingBooksApiResponse
                                                                      .jsonBody,
                                                                ),
                                                                'Message',
                                                              ),
                                                              textAlign:
                                                                  TextAlign
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
                                                        return RefreshIndicator(
                                                          key: Key(
                                                              'RefreshIndicator_hiaxgz4b'),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          onRefresh: () async {
                                                            await Future.wait([
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetFavouriteBookCacheCache();
                                                                  _model.apiRequestCompleted1 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted1();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetCategoriesCacheCache();
                                                                  _model.apiRequestCompleted4 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted4();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetTrendingBooksCacheCache();
                                                                  _model.apiRequestCompleted2 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted2();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearGetauthorsCacheCache();
                                                                  _model.apiRequestCompleted5 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted5();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(
                                                                    () {
                                                                  FFAppState()
                                                                      .clearPopularBookCacheCache();
                                                                  _model.apiRequestCompleted3 =
                                                                      false;
                                                                });
                                                                await _model
                                                                    .waitForApiRequestCompleted3();
                                                              }),
                                                              Future(() async {
                                                                safeSetState(() {
                                                                  FFAppState()
                                                                      .clearGetnarratorsCacheCache();
                                                                });
                                                              }),
                                                            ]);
                                                          },
                                                          child: ListView(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            scrollDirection:
                                                                Axis.vertical,
                                                            children: [
                                                              FutureBuilder<
                                                                  ApiCallResponse>(
                                                                future: FFAppState()
                                                                    .getSlidersCache(
                                                                  requestFn: () =>
                                                                      EbookGroup
                                                                          .getSlidersApiCall
                                                                          .call(),
                                                                )
                                                                    .then((result) {
                                                                  _model.apiRequestCompleted6 =
                                                                      true;
                                                                  return result;
                                                                }),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  // Customize what your widget looks like when it's loading.
                                                                  if (!snapshot
                                                                      .hasData) {
                                                                    return SizedBox();
                                                                  }
                                                                  final containerGetSlidersResponse =
                                                                      snapshot
                                                                          .data!;
                                                                  return BannerSlider(
                                                                    imageUrls: (EbookGroup
                                                                            .getSlidersApiCall
                                                                            .sliderDetailsList(
                                                                              containerGetSlidersResponse.jsonBody,
                                                                            )
                                                                            ?.map<String>((e) =>
                                                                                '${FFAppConstants.sliderImagesUrl}${getJsonField(e, r'''$.image''').toString()}')
                                                                            .toList() ??
                                                                        []),
                                                                    links: (EbookGroup
                                                                            .getSlidersApiCall
                                                                            .sliderDetailsList(
                                                                              containerGetSlidersResponse.jsonBody,
                                                                            )
                                                                            ?.map<String>((e) =>
                                                                                '${getJsonField(e, r'''$.button_url''').toString()}')
                                                                            .toList() ??
                                                                        []),
                                                                  );
                                                                },
                                                              ),
                                                              Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getcategoriesApiCall
                                                                              .categoryDetailsList(
                                                                            containerGetcategoriesApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getcategoriesApiCall
                                                                              .categoryDetailsList(
                                                                        containerGetcategoriesApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
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
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            16.0),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              FFLocalizations.of(context).getText('categories_title'),
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 20.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                context.pushNamed(CategoriesScreenWidget.routeName);
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(12)),
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText('view_all'),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 17.0,
                                                                                        letterSpacing: 0.0,
                                                                                        lineHeight: 1.5,
                                                                                        color: Colors.white,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation1']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final categoryDetailsList = (EbookGroup.getcategoriesApiCall
                                                                                        .categoryDetailsList(
                                                                                          containerGetcategoriesApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(4)
                                                                                .toList();

                                                                            return Wrap(
                                                                              spacing: 16.0,
                                                                              runSpacing: 16.0,
                                                                              alignment: WrapAlignment.start,
                                                                              crossAxisAlignment: WrapCrossAlignment.start,
                                                                              direction: Axis.horizontal,
                                                                              runAlignment: WrapAlignment.start,
                                                                              verticalDirection: VerticalDirection.down,
                                                                              clipBehavior: Clip.none,
                                                                              children: List.generate(categoryDetailsList.length, (categoryDetailsListIndex) {
                                                                                final categoryDetailsListItem = categoryDetailsList[categoryDetailsListIndex];
                                                                                return wrapWithModel(
                                                                                  model: _model.categoryComponentModels1.getModel(
                                                                                    getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    categoryDetailsListIndex,
                                                                                  ),
                                                                                  updateCallback: () => safeSetState(() {}),
                                                                                  child: CategoryComponentWidget(
                                                                                    key: Key(
                                                                                      'Key15y_${getJsonField(
                                                                                        categoryDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString()}',
                                                                                    ),
                                                                                    image: '${FFAppConstants.imageUrl}${getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.image''',
                                                                                    ).toString()}',
                                                                                    name: getJsonField(
                                                                                      categoryDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    isSmall: true,
                                                                                    onMainTap: () async {
                                                                                      context.pushNamed(
                                                                                        SubCategoriesScreenWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'id': serializeParam(
                                                                                            getJsonField(
                                                                                              categoryDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'name': serializeParam(
                                                                                            getJsonField(
                                                                                              categoryDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                        }.withoutNulls,
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ).animateOnPageLoad(animationsMap['categoryComponentOnPageLoadAnimation']!);
                                                                              }),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              _buildContinueReadingSection(),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: FutureBuilder<
                                                                    ApiCallResponse>(
                                                                  future: FFAppState()
                                                                      .getNewBooksCache(
                                                                    requestFn: () =>
                                                                        EbookGroup
                                                                            .getNewBooksApiCall
                                                                            .call(),
                                                                  )
                                                                      .then((result) {
                                                                    _model.apiRequestCompleted7 =
                                                                        true;
                                                                    return result;
                                                                  }),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    // Customize what your widget looks like when it's loading.
                                                                    if (!snapshot
                                                                        .hasData) {
                                                                      return SizedBox();
                                                                    }
                                                                    final containerGetNewBooksApiResponse =
                                                                        snapshot
                                                                            .data!;
                                                                    final allNewBooks =
                                                                        (EbookGroup.getNewBooksApiCall
                                                                                    .bookDetailsList(
                                                                                      containerGetNewBooksApiResponse.jsonBody,
                                                                                    )
                                                                                    ?.toList() ??
                                                                                []);
                                                                    final newbookDetailsList =
                                                                        _pickHomeSectionBooks(
                                                                            allNewBooks);
                                                                    return Visibility(
                                                                      visible:
                                                                          newbookDetailsList
                                                                              .isNotEmpty,
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.fromLTRB( 16.0, 8, 16.0, 3),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  FFLocalizations.of(context).getText('new_books_title'),
                                                                                  maxLines: 1,
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 17.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        lineHeight: 1.5,
                                                                                      ),
                                                                                ),
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    context.pushNamed(NewBooksPageWidget.routeName);
                                                                                  },
                                                                                  child: Container(
                                                                                    padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                    decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(12)),
                                                                                    child: Text(
                                                                                      FFLocalizations.of(context).getText('view_all'),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            fontSize: 14.0,
                                                                                            letterSpacing: 0.0,
                                                                                            lineHeight: 1.5,
                                                                                            color: Colors.white,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation2']!),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0,
                                                                                0.0,
                                                                                0,
                                                                                0.0),
                                                                            child:
                                                                                Builder(
                                                                              builder: (context) {
                                                                                return SingleChildScrollView(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  child: Row(
                                                                                    spacing: 10.0,
                                                                                    // runSpacing: 16.0,
                                                                                    // alignment: WrapAlignment.start,
                                                                                    // crossAxisAlignment: WrapCrossAlignment.start,
                                                                                    // direction: Axis.horizontal,
                                                                                    // runAlignment: WrapAlignment.start,
                                                                                    // verticalDirection: VerticalDirection.down,
                                                                                    // clipBehavior: Clip.none,
                                                                                    children: List.generate(newbookDetailsList.length, (newbookDetailsListIndex) {
                                                                                      final newbookDetailsListItem = newbookDetailsList[newbookDetailsListIndex];
                                                                                      return wrapWithModel(
                                                                                        model: _model.mainBookComponentModels.getModel(
                                                                                          getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.name''',
                                                                                          ).toString(),
                                                                                          newbookDetailsListIndex,
                                                                                        ),
                                                                                        updateCallback: () => safeSetState(() {}),
                                                                                        child: MainBookComponentWidget(
                                                                                          key: Key(
                                                                                            'Key0kh_${getJsonField(
                                                                                              newbookDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString()}',
                                                                                          ),
                                                                                          image: '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.image''',
                                                                                          ).toString()}',
                                                                                          bookName: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.name''',
                                                                                          ).toString(),
                                                                                          price: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.price''',
                                                                                          ).toString(),
                                                                                          bookType: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.type''',
                                                                                          )?.toString(),
                                                                                          discountAmount: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.discount_amount''',
                                                                                          ).toString(),
                                                                                          discountPercentage: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.discount_percentage''',
                                                                                          ).toString(),
                                                                                          id: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$._id''',
                                                                                          ).toString(),
                                                                                          isPurchased: _model.purchasedBookIds.contains(
                                                                                            getJsonField(
                                                                                              newbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                          ),
                                                                                          authorsName: getJsonField(
                                                                                            newbookDetailsListItem,
                                                                                            r'''$.author.name''',
                                                                                          ).toString(),
                                                                                          isFav: functions.checkFavOrNot(
                                                                                                  EbookGroup.getFavouriteBookCall
                                                                                                      .favouriteBookDetailsList(
                                                                                                        containerGetFavouriteBookResponse.jsonBody,
                                                                                                      )
                                                                                                      ?.toList(),
                                                                                                  getJsonField(
                                                                                                    newbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString()) ==
                                                                                              true,
                                                                                          indicator: (newbookDetailsListIndex == _model.newBooksIndex) && (_model.isNewBooks == true),
                                                                                          isFavAction: () async {
                                                                                            if (FFAppState().isLogin == true) {
                                                                                              _model.isNewBooks = true;
                                                                                              _model.newBooksIndex = newbookDetailsListIndex;
                                                                                              safeSetState(() {});
                                                                                              if (functions.checkFavOrNot(
                                                                                                      EbookGroup.getFavouriteBookCall
                                                                                                          .favouriteBookDetailsList(
                                                                                                            containerGetFavouriteBookResponse.jsonBody,
                                                                                                          )
                                                                                                          ?.toList(),
                                                                                                      getJsonField(
                                                                                                        newbookDetailsListItem,
                                                                                                        r'''$._id''',
                                                                                                      ).toString()) ==
                                                                                                  true) {
                                                                                                _model.getPopularHomeDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                                  userId: FFAppState().userId,
                                                                                                  token: FFAppState().token,
                                                                                                  bookId: getJsonField(
                                                                                                    newbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString(),
                                                                                                );
                                                                                        
                                                                                                safeSetState(() {
                                                                                                  FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                  _model.apiRequestCompleted1 = false;
                                                                                                });
                                                                                                await _model.waitForApiRequestCompleted1();
                                                                                                await actions.showCustomToastBottom(
                                                                                                  FFAppState().unFavText,
                                                                                                );
                                                                                              } else {
                                                                                                _model.getPopularHomeAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                                  userId: FFAppState().userId,
                                                                                                  token: FFAppState().token,
                                                                                                  bookId: getJsonField(
                                                                                                    newbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString(),
                                                                                                );
                                                                                        
                                                                                                safeSetState(() {
                                                                                                  FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                  _model.apiRequestCompleted1 = false;
                                                                                                });
                                                                                                await _model.waitForApiRequestCompleted1();
                                                                                                await actions.showCustomToastBottom(
                                                                                                  FFAppState().favText,
                                                                                                );
                                                                                              }
                                                                                        
                                                                                              FFAppState().clearGetFavouriteBookCacheCache();
                                                                                              _model.isNewBooks = false;
                                                                                              safeSetState(() {});
                                                                                            } else {
                                                                                              FFAppState().favChange = true;
                                                                                              FFAppState().bookId = getJsonField(
                                                                                                newbookDetailsListItem,
                                                                                                r'''$._id''',
                                                                                              ).toString();
                                                                                              FFAppState().update(() {});
                                                                                        
                                                                                              context.pushNamed(SignInPageWidget.routeName);
                                                                                            }
                                                                                        
                                                                                            safeSetState(() {});
                                                                                          },
                                                                                          isMainTap: () async {
                                                                                            await _openBookDetails(
                                                                                              newbookDetailsListItem,
                                                                                            );
                                                                                          },
                                                                                        ),
                                                                                      );
                                                                                    }).addToStart(SizedBox(width: 8,)),
                                                                                  )
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: _filterBooks(
                                                                          (EbookGroup.getTrendingBooksApiCall
                                                                                      .bookDetailsList(
                                                                                        containerGetTrendingBooksApiResponse.jsonBody,
                                                                                      )
                                                                                      ?.toList() ??
                                                                                  []))
                                                                      .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.fromLTRB(16.0, 8, 16.0, 3),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Text(
                                                                              FFLocalizations.of(context).getText('trending_books_title'),
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 17.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                context.pushNamed(TrendingBooksPageWidget.routeName);
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(12)),
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText('view_all'),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 14.0,
                                                                                        letterSpacing: 0.0,
                                                                                        lineHeight: 1.5,
                                                                                        color: Colors.white,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation2']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0,
                                                                            0.0,
                                                                            0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final trendbookDetailsList =
                                                                                _pickHomeSectionBooks(
                                                                                    (EbookGroup.getTrendingBooksApiCall
                                                                                                .bookDetailsList(
                                                                                                  containerGetTrendingBooksApiResponse.jsonBody,
                                                                                                )
                                                                                                ?.toList() ??
                                                                                            []));

                                                                            return SingleChildScrollView(
                                                                              scrollDirection: Axis.horizontal,
                                                                              child: Row(
                                                                                spacing: 10.0,
                                                                                // runSpacing: 16.0,
                                                                                // alignment: WrapAlignment.start,
                                                                                // crossAxisAlignment: WrapCrossAlignment.start,
                                                                                // direction: Axis.horizontal,
                                                                                // runAlignment: WrapAlignment.start,
                                                                                // verticalDirection: VerticalDirection.down,
                                                                                // clipBehavior: Clip.none,
                                                                                children: List.generate(trendbookDetailsList.length, (trendbookDetailsListIndex) {
                                                                                  final trendbookDetailsListItem = trendbookDetailsList[trendbookDetailsListIndex];
                                                                                  return wrapWithModel(
                                                                                    model: _model.mainBookComponentModels.getModel(
                                                                                      getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString(),
                                                                                      trendbookDetailsListIndex,
                                                                                    ),
                                                                                    updateCallback: () => safeSetState(() {}),
                                                                                    child: MainBookComponentWidget(
                                                                                      key: Key(
                                                                                        'Key0kh_${getJsonField(
                                                                                          trendbookDetailsListItem,
                                                                                          r'''$.name''',
                                                                                        ).toString()}',
                                                                                      ),
                                                                                      image: '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.image''',
                                                                                      ).toString()}',
                                                                                      bookName: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString(),
                                                                                      price: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.price''',
                                                                                      ).toString(),
                                                                                      bookType: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.type''',
                                                                                      )?.toString(),
                                                                                      discountAmount: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.discount_amount''',
                                                                                      ).toString(),
                                                                                      discountPercentage: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.discount_percentage''',
                                                                                      ).toString(),
                                                                                      id: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$._id''',
                                                                                      ).toString(),
                                                                                      isPurchased: _model.purchasedBookIds.contains(
                                                                                        getJsonField(
                                                                                          trendbookDetailsListItem,
                                                                                          r'''$._id''',
                                                                                        ).toString(),
                                                                                      ),
                                                                                      authorsName: getJsonField(
                                                                                        trendbookDetailsListItem,
                                                                                        r'''$.author.name''',
                                                                                      ).toString(),
                                                                                      isFav: functions.checkFavOrNot(
                                                                                              EbookGroup.getFavouriteBookCall
                                                                                                  .favouriteBookDetailsList(
                                                                                                    containerGetFavouriteBookResponse.jsonBody,
                                                                                                  )
                                                                                                  ?.toList(),
                                                                                              getJsonField(
                                                                                                trendbookDetailsListItem,
                                                                                                r'''$._id''',
                                                                                              ).toString()) ==
                                                                                          true,
                                                                                      indicator: (trendbookDetailsListIndex == _model.trendingIndex) && (_model.isTrending == true),
                                                                                      isFavAction: () async {
                                                                                        if (FFAppState().isLogin == true) {
                                                                                          _model.isTrending = true;
                                                                                          _model.trendingIndex = trendbookDetailsListIndex;
                                                                                          safeSetState(() {});
                                                                                          if (functions.checkFavOrNot(
                                                                                                  EbookGroup.getFavouriteBookCall
                                                                                                      .favouriteBookDetailsList(
                                                                                                        containerGetFavouriteBookResponse.jsonBody,
                                                                                                      )
                                                                                                      ?.toList(),
                                                                                                  getJsonField(
                                                                                                    trendbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString()) ==
                                                                                              true) {
                                                                                            _model.getPopularHomeDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                              userId: FFAppState().userId,
                                                                                              token: FFAppState().token,
                                                                                              bookId: getJsonField(
                                                                                                trendbookDetailsListItem,
                                                                                                r'''$._id''',
                                                                                              ).toString(),
                                                                                            );
                                                                                    
                                                                                            safeSetState(() {
                                                                                              FFAppState().clearGetFavouriteBookCacheCache();
                                                                                              _model.apiRequestCompleted1 = false;
                                                                                            });
                                                                                            await _model.waitForApiRequestCompleted1();
                                                                                            await actions.showCustomToastBottom(
                                                                                              FFAppState().unFavText,
                                                                                            );
                                                                                          } else {
                                                                                            _model.getPopularHomeAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                              userId: FFAppState().userId,
                                                                                              token: FFAppState().token,
                                                                                              bookId: getJsonField(
                                                                                                trendbookDetailsListItem,
                                                                                                r'''$._id''',
                                                                                              ).toString(),
                                                                                            );
                                                                                    
                                                                                            safeSetState(() {
                                                                                              FFAppState().clearGetFavouriteBookCacheCache();
                                                                                              _model.apiRequestCompleted1 = false;
                                                                                            });
                                                                                            await _model.waitForApiRequestCompleted1();
                                                                                            await actions.showCustomToastBottom(
                                                                                              FFAppState().favText,
                                                                                            );
                                                                                          }
                                                                                    
                                                                                          FFAppState().clearGetFavouriteBookCacheCache();
                                                                                          _model.isTrending = false;
                                                                                          safeSetState(() {});
                                                                                        } else {
                                                                                          FFAppState().favChange = true;
                                                                                          FFAppState().bookId = getJsonField(
                                                                                            trendbookDetailsListItem,
                                                                                            r'''$._id''',
                                                                                          ).toString();
                                                                                          FFAppState().update(() {});
                                                                                    
                                                                                          context.pushNamed(SignInPageWidget.routeName);
                                                                                        }
                                                                                    
                                                                                        safeSetState(() {});
                                                                                      },
                                                                                      isMainTap: () async {
                                                                                        await _openBookDetails(
                                                                                          trendbookDetailsListItem,
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                                }).addToStart(SizedBox(width: 8,)),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: EbookGroup
                                                                              .getauthorsApiCall
                                                                              .authorDetailsList(
                                                                            containerGetauthorsApiResponse.jsonBody,
                                                                          ) !=
                                                                          null &&
                                                                      (EbookGroup
                                                                              .getauthorsApiCall
                                                                              .authorDetailsList(
                                                                        containerGetauthorsApiResponse
                                                                            .jsonBody,
                                                                      ))!
                                                                          .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.fromLTRB(16.0, 10, 16.0,5),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              FFLocalizations.of(context).getText('best_authors_title'),
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 17.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                context.pushNamed(BestAuthorPageWidget.routeName);
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(12)),
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText('view_all'),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 14.0,
                                                                                        letterSpacing: 0.0,
                                                                                        lineHeight: 1.5,
                                                                                        color: Colors.white,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation3']!),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final authorDetailsList = (EbookGroup.getauthorsApiCall
                                                                                        .authorDetailsList(
                                                                                          containerGetauthorsApiResponse.jsonBody,
                                                                                        )
                                                                                        ?.toList() ??
                                                                                    [])
                                                                                .take(4)
                                                                                .toList();

                                                                            return Wrap(
                                                                              spacing: 16.0,
                                                                              runSpacing: 16.0,
                                                                              alignment: WrapAlignment.start,
                                                                              crossAxisAlignment: WrapCrossAlignment.start,
                                                                              direction: Axis.horizontal,
                                                                              runAlignment: WrapAlignment.start,
                                                                              verticalDirection: VerticalDirection.down,
                                                                              clipBehavior: Clip.none,
                                                                              children: List.generate(authorDetailsList.length, (authorDetailsListIndex) {
                                                                                final authorDetailsListItem = authorDetailsList[authorDetailsListIndex];
                                                                                return wrapWithModel(
                                                                                  model: _model.categoryComponentModels2.getModel(
                                                                                    getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    authorDetailsListIndex,
                                                                                  ),
                                                                                  updateCallback: () => safeSetState(() {}),
                                                                                  child: CategoryComponentWidget(
                                                                                    key: Key(
                                                                                      'Keywz2_${getJsonField(
                                                                                        authorDetailsListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString()}',
                                                                                    ),
                                                                                    image: '${FFAppConstants.imageUrl}${getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.image''',
                                                                                    ).toString()}',
                                                                                    name: getJsonField(
                                                                                      authorDetailsListItem,
                                                                                      r'''$.name''',
                                                                                    ).toString(),
                                                                                    isSmall: true,
                                                                                    onMainTap: () async {
                                                                                      context.pushNamed(
                                                                                        AboutAuthorPageWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'name': serializeParam(
                                                                                            getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'authorImage': serializeParam(
                                                                                            '${FFAppConstants.imageUrl}${getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$.image''',
                                                                                            ).toString()}',
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'authorId': serializeParam(
                                                                                            getJsonField(
                                                                                              authorDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                        }.withoutNulls,
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                );
                                                                              }),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              _buildFeaturedNarratorsSection(),
                                                              _buildHomeLibraryPromo(),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child:
                                                                    Visibility(
                                                                  visible: _filterBooks(
                                                                          (EbookGroup.getPopularBooksApiCall
                                                                                      .bookDetailsList(
                                                                                        containerGetPopularBooksApiResponse.jsonBody,
                                                                                      )
                                                                                      ?.toList() ??
                                                                                  []))
                                                                      .isNotEmpty,
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:EdgeInsets.fromLTRB(16.0, 8, 16.0, 3),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              FFLocalizations.of(context).getText('popular_books_title'),
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 17.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                context.pushNamed(PopularBooksPageWidget.routeName);
                                                                              },
                                                                              child: Container(
                                                                                padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(12)),
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText('view_all'),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 14.0,
                                                                                        letterSpacing: 0.0,
                                                                                        lineHeight: 1.5,
                                                                                        color: Colors.white,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ].divide(SizedBox(width: 4.0)),
                                                                        ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation4']!),
                                                                      ),
                                                                      Container(
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            160.0,
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            final popularbookDetailsList =
                                                                                _pickHomeSectionBooks(
                                                                                    (EbookGroup.getPopularBooksApiCall
                                                                                                .bookDetailsList(
                                                                                                  containerGetPopularBooksApiResponse.jsonBody,
                                                                                                )
                                                                                                ?.toList() ??
                                                                                            []));

                                                                            return SingleChildScrollView(
                                                                              scrollDirection: Axis.horizontal,
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: List.generate(popularbookDetailsList.length, (popularbookDetailsListIndex) {
                                                                                  final popularbookDetailsListItem = popularbookDetailsList[popularbookDetailsListIndex];
                                                                                  return Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(10, 0, 0.0, 0),
                                                                                      child: wrapWithModel(
                                                                                        model: _model.listMainContainerComponentModels.getModel(
                                                                                          getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.name''',
                                                                                          ).toString(),
                                                                                          popularbookDetailsListIndex,
                                                                                        ),
                                                                                        updateCallback: () => safeSetState(() {}),
                                                                                        child: ListMainContainerComponentWidget(
                                                                                          key: Key(
                                                                                            'Key9t2_${getJsonField(
                                                                                              popularbookDetailsListItem,
                                                                                              r'''$.name''',
                                                                                            ).toString()}',
                                                                                          ),
                                                                                          image: '${FFAppConstants.bookImagesUrl}${getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.image''',
                                                                                          ).toString()}',
                                                                                          name: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.name''',
                                                                                          ).toString(),
                                                                                          price: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.price''',
                                                                                          ).toString(),
                                                                                          bookType: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.type''',
                                                                                          )?.toString(),
                                                                                          discountAmount: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.discount_amount''',
                                                                                          ).toString(),
                                                                                          discountPercentage: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.discount_percentage''',
                                                                                          ).toString(),
                                                                                          id: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$._id''',
                                                                                          ).toString(),
                                                                                          isPurchased: _model.purchasedBookIds.contains(
                                                                                            getJsonField(
                                                                                              popularbookDetailsListItem,
                                                                                              r'''$._id''',
                                                                                            ).toString(),
                                                                                          ),
                                                                                          authorName: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.author.name''',
                                                                                          ).toString(),
                                                                                          averageRating: getJsonField(
                                                                                            popularbookDetailsListItem,
                                                                                            r'''$.averageRating''',
                                                                                          ).toDouble(),
                                                                                          isFav: functions.checkFavOrNot(
                                                                                                  EbookGroup.getFavouriteBookCall
                                                                                                      .favouriteBookDetailsList(
                                                                                                        containerGetFavouriteBookResponse.jsonBody,
                                                                                                      )
                                                                                                      ?.toList(),
                                                                                                  getJsonField(
                                                                                                    popularbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString()) ==
                                                                                              true,
                                                                                          indicator: (popularbookDetailsListIndex == _model.popularIndex) && (_model.isPopular == true),
                                                                                          width: 280.0,
                                                                                          // price: getJsonField(
                                                                                          //   popularbookDetailsListItem,
                                                                                          //   r'''$.price''',
                                                                                          // ).toString(),
                                                                                          isFavAction: () async {
                                                                                            if (FFAppState().isLogin == true) {
                                                                                              _model.isPopular = true;
                                                                                              _model.popularIndex = popularbookDetailsListIndex;
                                                                                              safeSetState(() {});
                                                                                              if (functions.checkFavOrNot(
                                                                                                      EbookGroup.getFavouriteBookCall
                                                                                                          .favouriteBookDetailsList(
                                                                                                            containerGetFavouriteBookResponse.jsonBody,
                                                                                                          )
                                                                                                          ?.toList(),
                                                                                                      getJsonField(
                                                                                                        popularbookDetailsListItem,
                                                                                                        r'''$._id''',
                                                                                                      ).toString()) ==
                                                                                                  true) {
                                                                                                _model.getPopularDetete = await EbookGroup.removeFavouritebookCall.call(
                                                                                                  userId: FFAppState().userId,
                                                                                                  token: FFAppState().token,
                                                                                                  bookId: getJsonField(
                                                                                                    popularbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString(),
                                                                                                );

                                                                                                safeSetState(() {
                                                                                                  FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                  _model.apiRequestCompleted1 = false;
                                                                                                });
                                                                                                await _model.waitForApiRequestCompleted1();
                                                                                                await actions.showCustomToastBottom(
                                                                                                  FFAppState().unFavText,
                                                                                                );
                                                                                              } else {
                                                                                                _model.getPopularAdd = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                                  userId: FFAppState().userId,
                                                                                                  token: FFAppState().token,
                                                                                                  bookId: getJsonField(
                                                                                                    popularbookDetailsListItem,
                                                                                                    r'''$._id''',
                                                                                                  ).toString(),
                                                                                                );

                                                                                                safeSetState(() {
                                                                                                  FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                  _model.apiRequestCompleted1 = false;
                                                                                                });
                                                                                                await _model.waitForApiRequestCompleted1();
                                                                                                await actions.showCustomToastBottom(
                                                                                                  FFAppState().favText,
                                                                                                );
                                                                                              }

                                                                                              FFAppState().clearGetFavouriteBookCacheCache();
                                                                                              _model.isPopular = false;
                                                                                              safeSetState(() {});
                                                                                            } else {
                                                                                              FFAppState().favChange = true;
                                                                                              FFAppState().bookId = getJsonField(
                                                                                                popularbookDetailsListItem,
                                                                                                r'''$._id''',
                                                                                              ).toString();
                                                                                              FFAppState().update(() {});

                                                                                              context.pushNamed(SignInPageWidget.routeName);
                                                                                            }

                                                                                            safeSetState(() {});
                                                                                          },
                                                                                          onMainTap: () async {
                                                                                            await _openBookDetails(
                                                                                              popularbookDetailsListItem,
                                                                                            );
                                                                                          },
                                                                                        ),
                                                                                      ));
                                                                                }).divide(SizedBox(width: 5.0)).addToStart(SizedBox(width: 5.0)).addToEnd(SizedBox(width: 5.0)),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              Builder(
                                                                builder: (context) {
                                                                  final popularBooks = (EbookGroup
                                                                              .getPopularBooksApiCall
                                                                              .bookDetailsList(
                                                                                containerGetPopularBooksApiResponse.jsonBody,
                                                                              )
                                                                              ?.toList() ??
                                                                          []);
                                                                  final trendingBooks = (EbookGroup
                                                                              .getTrendingBooksApiCall
                                                                              .bookDetailsList(
                                                                                containerGetTrendingBooksApiResponse.jsonBody,
                                                                              )
                                                                              ?.toList() ??
                                                                          []);
                                                                  final freeBooks = [
                                                                    ...popularBooks,
                                                                    ...trendingBooks,
                                                                  ].where((b) => _isFreeBook(b)).toList();
                                                                  final topMostRead = [
                                                                    ...popularBooks,
                                                                    ...trendingBooks,
                                                                  ]..sort((a, b) =>
                                                                      _bookReads(b)
                                                                          .compareTo(
                                                                              _bookReads(a)));
                                                                  final popularAudiobooks = popularBooks
                                                                      .where((b) => _hasAudio(_resolveBookType(b)))
                                                                      .toList();
                                                                  final popularHardCopies = popularBooks
                                                                      .where((b) => _hasHardcopy(_resolveBookType(b)))
                                                                      .toList();
                                                                  return Column(
                                                                    children: [
                                                                      _buildBookStripSection(
                                                                        title: 'Top 10 Most Read',
                                                                        sectionKey: 'top_10_most_read',
                                                                        books: topMostRead.take(10).toList(),
                                                                        favouriteJson: containerGetFavouriteBookResponse.jsonBody,
                                                                      ),
                                                                      _buildBookStripSection(
                                                                        title: 'Free Books',
                                                                        sectionKey: 'free_books',
                                                                        books: freeBooks,
                                                                        favouriteJson: containerGetFavouriteBookResponse.jsonBody,
                                                                      ),
                                                                      if (_selectedFilter == HomeBookFilter.all ||
                                                                          _selectedFilter ==
                                                                              HomeBookFilter.audiobook)
                                                                        _buildBookStripSection(
                                                                          title: 'Popular Audiobooks',
                                                                          sectionKey: 'popular_audiobooks',
                                                                          books: popularAudiobooks,
                                                                          favouriteJson: containerGetFavouriteBookResponse.jsonBody,
                                                                        ),
                                                                      if (_selectedFilter == HomeBookFilter.all ||
                                                                          _selectedFilter ==
                                                                              HomeBookFilter.hardcopy)
                                                                        _buildBookStripSection(
                                                                          title: 'Hard Copies',
                                                                          sectionKey: 'hard_copies',
                                                                          books: popularHardCopies,
                                                                          favouriteJson: containerGetFavouriteBookResponse.jsonBody,
                                                                        ),
                                                                    ],
                                                                  );
                                                                },
                                                              ),
                                                              Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: FutureBuilder<
                                                                    ApiCallResponse>(
                                                                  future: FFAppState()
                                                                      .getFeaturedBooksByCategoryCache(
                                                                    requestFn: () =>
                                                                        EbookGroup
                                                                            .getFeaturedBooksByCategoryApiCall
                                                                            .call(
                                                                      token: FFAppState()
                                                                          .token,
                                                                    ),
                                                                  )
                                                                      .then((result) {
                                                                    _model.apiRequestCompleted8 =
                                                                        true;
                                                                    return result;
                                                                  }),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    if (!snapshot
                                                                        .hasData) {
                                                                      return SizedBox();
                                                                    }
                                                                    final containerFeaturedBooksResponse =
                                                                        snapshot
                                                                            .data!;
                                                                    final categoryBooksList = EbookGroup
                                                                        .getFeaturedBooksByCategoryApiCall
                                                                        .categoryBooks(
                                                                            containerFeaturedBooksResponse.jsonBody);

                                                                    if (categoryBooksList ==
                                                                            null ||
                                                                        categoryBooksList
                                                                            .isEmpty) {
                                                                      return SizedBox();
                                                                    }

                                                                    return Column(
                                                                      children: List.generate(
                                                                          categoryBooksList
                                                                              .length,
                                                                          (catIndex) {
                                                                        final categoryItem =
                                                                            categoryBooksList[catIndex];
                                                                        final featuredBooks = getJsonField(
                                                                            categoryItem,
                                                                            r'''$.featuredBooks''');
                                                                        final featuredBooksList =
                                                                            (featuredBooks as List?)
                                                                                    ?.toList() ??
                                                                                [];
                                                                        final filteredFeaturedBooks =
                                                                            _pickHomeSectionBooks(
                                                                                featuredBooksList);

                                                                        if (filteredFeaturedBooks
                                                                            .isEmpty) {
                                                                          return SizedBox();
                                                                        }

                                                                        return Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Padding(
                                                                              padding: EdgeInsets.fromLTRB(16.0, 8, 16.0, 3),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    getJsonField(categoryItem, r'''$.name''').toString(),
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 17.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                  InkWell(
                                                                                    splashColor: Colors.transparent,
                                                                                    focusColor: Colors.transparent,
                                                                                    hoverColor: Colors.transparent,
                                                                                    highlightColor: Colors.transparent,
                                                                                    onTap: () async {
                                                                                      context.pushNamed(
                                                                                        GetBookByCategoryPageWidget.routeName,
                                                                                        queryParameters: {
                                                                                          'name': serializeParam(
                                                                                            getJsonField(categoryItem, r'''$.name''').toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                          'id': serializeParam(
                                                                                            getJsonField(categoryItem, r'''$._id''').toString(),
                                                                                            ParamType.String,
                                                                                          ),
                                                                                        }.withoutNulls,
                                                                                      );
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                      ),
                                                                                      child: Text(
                                                                                        FFLocalizations.of(context).getText('view_all'),
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              fontSize: 14.0,
                                                                                              letterSpacing: 0.0,
                                                                                              lineHeight: 1.5,
                                                                                              color: Colors.white,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            SingleChildScrollView(
                                                                              scrollDirection: Axis.horizontal,
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0, 0, 8.0),
                                                                              child: Row(
                                                                                spacing: 10,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: List.generate(filteredFeaturedBooks.length, (bookIndex) {
                                                                                  final bookItem = filteredFeaturedBooks[bookIndex];
                                                                                  final bookId = getJsonField(bookItem, r'''$._id''').toString();
                                                                                  return wrapWithModel(
                                                                                    model: _model.featuredBooksComponentModels.getModel(
                                                                                      bookId,
                                                                                      catIndex * 1000 + bookIndex,
                                                                                    ),
                                                                                    updateCallback: () => safeSetState(() {}),
                                                                                    child: MainBookComponentWidget(
                                                                                      key: Key('FeaturedBook_${catIndex}_$bookIndex'),
                                                                                      id: bookId,
                                                                                      image: '${FFAppConstants.bookImagesUrl}${getJsonField(bookItem, r'''$.image''').toString()}',
                                                                                      bookName: getJsonField(bookItem, r'''$.name''').toString(),
                                                                                      authorsName: getJsonField(bookItem, r'''$.author.name''').toString(),
                                                                                      price: getJsonField(bookItem, r'''$.price''').toString(),
                                                                                      bookType: _resolveBookType(bookItem),
                                                                                      discountPercentage: getJsonField(bookItem, r'''$.discount_percentage''').toString(),
                                                                                      isFav: functions.checkFavOrNot(
                                                                                        EbookGroup.getFavouriteBookCall
                                                                                            .favouriteBookDetailsList(
                                                                                              containerGetFavouriteBookResponse.jsonBody,
                                                                                            )
                                                                                            ?.toList(),
                                                                                        bookId,
                                                                                      ),
                                                                                      isPurchased: _model.purchasedBookIds.contains(bookId),
                                                                                      isFavAction: () async {
                                                                                        if (functions.checkFavOrNot(
                                                                                          EbookGroup.getFavouriteBookCall
                                                                                              .favouriteBookDetailsList(
                                                                                                containerGetFavouriteBookResponse.jsonBody,
                                                                                              )
                                                                                              ?.toList(),
                                                                                          bookId,
                                                                                        )!) {
                                                                                          var response = await EbookGroup.removeFavouritebookCall.call(
                                                                                            bookId: bookId,
                                                                                            userId: FFAppState().userId,
                                                                                            token: FFAppState().token,
                                                                                          );
                                                                                          if (response.succeeded) {
                                                                                            safeSetState(() {
                                                                                              FFAppState().clearGetFavouriteBookCacheCache();
                                                                                              _model.apiRequestCompleted1 = false;
                                                                                            });
                                                                                            await _model.waitForApiRequestCompleted1();
                                                                                            await actions.showCustomToastBottom(FFAppState().unFavText);
                                                                                          }
                                                                                        } else {
                                                                                          if (FFAppState().isLogin == true) {
                                                                                            var response = await EbookGroup.addFavouriteBookApiCall.call(
                                                                                              bookId: bookId,
                                                                                              userId: FFAppState().userId,
                                                                                              token: FFAppState().token,
                                                                                            );
                                                                                            if (response.succeeded) {
                                                                                              safeSetState(() {
                                                                                                FFAppState().clearGetFavouriteBookCacheCache();
                                                                                                _model.apiRequestCompleted1 = false;
                                                                                              });
                                                                                              await _model.waitForApiRequestCompleted1();
                                                                                              await actions.showCustomToastBottom(FFAppState().favText);
                                                                                            }
                                                                                          } else {
                                                                                            FFAppState().favChange = true;
                                                                                            FFAppState().bookId = bookId;
                                                                                            FFAppState().update(() {});
                                                                                            context.pushNamed(SignInPageWidget.routeName);
                                                                                          }
                                                                                        }
                                                                                        safeSetState(() {});
                                                                                      },
                                                                                      isMainTap: () async {
                                                                                        await _openBookDetails(
                                                                                          bookItem,
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                                }).addToStart(SizedBox(width: 10,))
                                                                                // .divide(SizedBox(width: 16.0)).addToStart(SizedBox(width: 16.0)).addToEnd(SizedBox(width: 16.0)),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      }),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
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
      ),
    );
  }

  Widget _buildContinueReadingSection() {
    return Builder(
      builder: (context) {
        final showEbookResume = _allowsEbook &&
            FFAppState().homePageLiveReadBook.trim().isNotEmpty;
        final showAudioResume =
            (_selectedFilter == HomeBookFilter.all ||
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
                        onTap: () async {
                          context.pushNamed(
                            ReadBookCustomPageWidget.routeName,
                            queryParameters: {
                              'pdf': serializeParam(
                                FFAppState().homePageBookPdf,
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
                        onTap: () async {
                          context.pushNamed(
                            AudiobookDetailsPageWidget.routeName,
                            extra: <String, dynamic>{
                              'audiobook': {
                                'id': FFAppState().homePageLastAudioBookId,
                                'title': FFAppState().homePageLastAudioBookName,
                                'image': FFAppState().homePageLastAudioBookImage,
                              },
                            },
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

  bool _isFreeBook(dynamic book) {
    final v = getJsonField(book, r'''$.is_free''');
    if (v is bool) return v;
    final s = (v ?? '').toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  Widget _buildBookStripSection({
    required String title,
    required String sectionKey,
    required List<dynamic> books,
    required dynamic favouriteJson,
  }) {
    final picked = _pickHomeSectionBooks(books);
    if (picked.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8, 16.0, 3),
          child: Text(
            title,
            maxLines: 1,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'SF Pro Display',
                  fontSize: 17.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  lineHeight: 1.5,
                ),
          ),
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
                    authorsName: getJsonField(item, r'''$.author.name''')
                        .toString(),
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

  Widget _buildFeaturedNarratorsSection() {
    return FutureBuilder<ApiCallResponse>(
      future: FFAppState().getnarratorsCache(
        requestFn: () => EbookGroup.getnarratorsApiCall.call(
          token: FFAppState().token,
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final res = snapshot.data!;
        final body = res.jsonBody;
        if (EbookGroup.getnarratorsApiCall.success(body) != 1) {
          return const SizedBox.shrink();
        }
        final raw = EbookGroup.getnarratorsApiCall.narratorDetailsList(body);
        if (raw == null || raw.isEmpty) {
          return const SizedBox.shrink();
        }
        final picked = raw.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                FFLocalizations.of(context).getText('featured_narrators_title'),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in picked)
                      if (item is Map)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 12),
                          child: InkWell(
                            onTap: () {},
                            child: SizedBox(
                              width: 88,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: CachedNetworkImage(
                                      imageUrl: _resolveCoverUrl(
                                        getJsonField(item, r'''$.image''')
                                            .toString(),
                                      ),
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 72,
                                        height: 72,
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        child: Icon(
                                          Icons.person,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    getJsonField(item, r'''$.name''')
                                        .toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 12,
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
          ],
        );
      },
    );
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
