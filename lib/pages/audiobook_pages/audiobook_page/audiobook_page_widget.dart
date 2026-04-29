import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '/index.dart';
import 'audiobook_page_model.dart';
export 'audiobook_page_model.dart';

// Components
import '/pages/components/category_component/category_component_widget.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';

class AudiobookPageWidget extends StatefulWidget {
  const AudiobookPageWidget({super.key});

  static String routeName = 'AudiobookPage';
  static String routePath = '/audiobookPage';

  @override
  State<AudiobookPageWidget> createState() => _AudiobookPageWidgetState();
}

class _AudiobookPageWidgetState extends State<AudiobookPageWidget>
    with TickerProviderStateMixin {
  late AudiobookPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final animationsMap = <String, AnimationInfo>{};

  // Banner carousel data
  final List<Map<String, dynamic>> banners = [
    {
      'title': 'Discover New Worlds',
      'subtitle': 'Explore our latest audiobook collection',
      'image': 'https://picsum.photos/seed/banner1/800/400',
      'color': Color(0xFF6366F1),
    },
    {
      'title': 'Listen Anywhere',
      'subtitle': 'Download and enjoy offline',
      'image': 'https://picsum.photos/seed/banner2/800/400',
      'color': Color(0xFFEC4899),
    },
    {
      'title': 'Best Sellers',
      'subtitle': 'Top rated audiobooks this month',
      'image': 'https://picsum.photos/seed/banner3/800/400',
      'color': Color(0xFF8B5CF6),
    },
  ];

  // Category data
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Fiction',
      'icon': Icons.auto_stories_rounded,
      'color': Color(0xFF6366F1),
      'count': '2.5k',
    },
    {
      'name': 'Self-Help',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFFEC4899),
      'count': '1.8k',
    },
    {
      'name': 'Business',
      'icon': Icons.business_center_rounded,
      'color': Color(0xFF8B5CF6),
      'count': '1.2k',
    },
    {
      'name': 'Mystery',
      'icon': Icons.search_rounded,
      'color': Color(0xFF14B8A6),
      'count': '950',
    },
    {
      'name': 'Romance',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFF43F5E),
      'count': '1.5k',
    },
    {
      'name': 'Science',
      'icon': Icons.science_rounded,
      'color': Color(0xFF3B82F6),
      'count': '780',
    },
  ];

  late Future<ApiCallResponse> _popularFuture;
  late Future<ApiCallResponse> _newFuture;
  late Future<ApiCallResponse> _trendingFuture;
  late Future<ApiCallResponse> _allFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudiobookPageModel());
    _popularFuture =
        EbookGroup.getPopularBooksApiCall.call(type: 'audiobook');
    _newFuture = EbookGroup.getNewBooksApiCall.call(type: 'audiobook');
    _trendingFuture =
        EbookGroup.getTrendingBooksApiCall.call(type: 'audiobook');
    _allFuture = EbookGroup.latestAllBookApiCall.call(type: 'audiobook');

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.9, 0.9),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
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
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
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

  num? _calculateOfferPrice(dynamic price, dynamic discountAmount,
      dynamic discountPercentage) {
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
      return 'https://picsum.photos/seed/audiobook/400/600';
    }
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return '${FFAppConstants.bookImagesUrl}$trimmed';
  }

  String _resolveBookType(dynamic book) {
    final type = getJsonField(book, r'''$.type''') ??
        getJsonField(book, r'''$.bookType''') ??
        getJsonField(book, r'''$.book_type''');
    return (type?.toString() ?? '').toLowerCase();
  }

  bool _isAudiobook(dynamic book) {
    final type = _resolveBookType(book);
    return type.contains('audio');
  }

  List<Map<String, dynamic>> _normalizeBooksFromResponse(
      ApiCallResponse? response) {
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
    final audioList = rawList.where(_isAudiobook).toList();
    return audioList.map<Map<String, dynamic>>(_normalizeBook).toList();
  }

  Map<String, dynamic> _normalizeBook(dynamic book) {
    final image = _resolveBookImage(
      getJsonField(book, r'''$.image''')?.toString(),
    );
    final price = getJsonField(book, r'''$.price''');
    final discountAmount = getJsonField(book, r'''$.discount_amount''');
    final discountPercentage = getJsonField(book, r'''$.discount_percentage''');
    final offerPrice =
        _calculateOfferPrice(price, discountAmount, discountPercentage);
    return {
      'id': getJsonField(book, r'''$._id''')?.toString() ?? '',
      'title': getJsonField(book, r'''$.name''')?.toString() ?? 'Untitled',
      'author': getJsonField(book, r'''$.author.name''')?.toString() ?? '',
      'duration': getJsonField(book, r'''$.duration''')?.toString() ??
          getJsonField(book, r'''$.totalDuration''')?.toString() ??
          '',
      'rating': _toNum(getJsonField(book, r'''$.averageRating''')) ?? 0,
      'image': image,
      'views': getJsonField(book, r'''$.viewCount''')?.toString() ?? '0',
      'price': _toNum(price),
      'offerPrice': offerPrice,
      'discountAmount': discountAmount?.toString() ?? '',
      'discountPercentage': discountPercentage?.toString() ?? '',
      'category': getJsonField(book, r'''$.category.name''')?.toString() ?? '',
      'chapters': getJsonField(book, r'''$.chapters''', true),
      'raw': book,
    };
  }

  Widget _buildLoadingList(double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
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

  Widget _buildEmptyList(String message, double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          message,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'SF Pro Display',
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: Stack(
        children: [
          // Original content
          SafeArea(
            top: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audiobooks',
                            style: FlutterFlowTheme.of(context).headlineLarge.override(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 32.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Listen to your favorite stories',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Icon
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(SearchPageWidget.routeName);
                            },
                            child: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.0),
                          // Headphones Icon
                          Container(
                            width: 48.0,
                            height: 48.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                stops: [0.0, 1.0],
                                begin: AlignmentDirectional(-1.0, -1.0),
                                end: AlignmentDirectional(1.0, 1.0),
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12.0,
                                  color: Color(0x406366F1),
                                  offset: Offset(0.0, 4.0),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.headphones_rounded,
                              color: Colors.white,
                              size: 24.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Banner Carousel Section
                Container(
                  width: double.infinity,
                  height: 180.0,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          0.0,
                          0.0,
                          index == banners.length - 1 ? 0.0 : 16.0,
                          0.0,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                banner['color'],
                                banner['color'].withOpacity(0.7),
                              ],
                              stops: [0.0, 1.0],
                              begin: AlignmentDirectional(-1.0, -1.0),
                              end: AlignmentDirectional(1.0, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 20.0,
                                color: banner['color'].withOpacity(0.3),
                                offset: Offset(0.0, 8.0),
                              )
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background pattern/image
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Opacity(
                                    opacity: 0.2,
                                    child: Image.network(
                                      banner['image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner['title'],
                                      style: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: Colors.white,
                                            fontSize: 28.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      banner['subtitle'],
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    SizedBox(height: 16.0),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        final response = await _allFuture;
                                        final books =
                                            _normalizeBooksFromResponse(response);
                                        if (books.isEmpty) {
                                          return;
                                        }
                                        context.pushNamed(
                                          AudiobookViewAllPageWidget.routeName,
                                          queryParameters: {
                                            'title': serializeParam(
                                              'Explore',
                                              ParamType.String,
                                            ),
                                          }.withoutNulls,
                                          extra: <String, dynamic>{
                                            'audiobooks': books,
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                          vertical: 10.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(25.0),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Explore Now',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'SF Pro Display',
                                                    color: banner['color'],
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            SizedBox(width: 8.0),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: banner['color'],
                                              size: 18.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation1']!),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24.0),

                // Categories Section (Dynamic from API)
                FutureBuilder<ApiCallResponse>(
                  future: EbookGroup.getcategoriesApiCall.call(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox(height: 200.0, child: Center(child: CircularProgressIndicator()));
                    }
                    final categoryDetailsList = EbookGroup.getcategoriesApiCall
                            .categoryDetailsList(snapshot.data!.jsonBody)
                            ?.toList() ??
                        [];
                    if (categoryDetailsList.isEmpty) {
                      return SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Browse by Category',
                                maxLines: 1,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
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
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'View All',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ).animateOnPageLoad(
                              animationsMap['rowOnPageLoadAnimation']!),
                          SizedBox(height: 16.0),
                          Wrap(
                            spacing: 16.0,
                            runSpacing: 16.0,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            direction: Axis.horizontal,
                            runAlignment: WrapAlignment.start,
                            verticalDirection: VerticalDirection.down,
                            clipBehavior: Clip.none,
                            children: List.generate(
                              categoryDetailsList.take(4).length,
                              (index) {
                                final categoryItem = categoryDetailsList[index];
                                return CategoryComponentWidget(
                                  key: Key(
                                    'AudiobookCategory_${getJsonField(categoryItem, r'''$.name''').toString()}',
                                  ),
                                  icon:
                                      '${FFAppConstants.imageUrl}${getJsonField(categoryItem, r'''$.icon''').toString()}',
                                  name: getJsonField(
                                          categoryItem, r'''$.name''')
                                      .toString(),
                                  isSmall: true,
                                  onMainTap: () async {
                                    context.pushNamed(
                                      SubCategoriesScreenWidget.routeName,
                                      queryParameters: {
                                        'id': serializeParam(
                                          getJsonField(categoryItem, r'''$._id''')
                                              .toString(),
                                          ParamType.String,
                                        ),
                                        'name': serializeParam(
                                          getJsonField(categoryItem, r'''$.name''')
                                              .toString(),
                                          ParamType.String,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 24.0),

                // Content Sections
                  // Popular Audiobooks Section
                  FutureBuilder<ApiCallResponse>(
                    future: _popularFuture,
                    builder: (context, snapshot) {
                      final books = snapshot.hasData
                          ? _normalizeBooksFromResponse(snapshot.data)
                          : <Map<String, dynamic>>[];
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Popular Audiobooks',
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        lineHeight: 1.5,
                                      ),
                                ),
                                InkWell(
                                  onTap: books.isEmpty
                                      ? null
                                      : () async {
                                          context.pushNamed(
                                            AudiobookViewAllPageWidget.routeName,
                                            queryParameters: {
                                              'title': serializeParam(
                                                'Popular Audiobooks',
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                            extra: <String, dynamic>{
                                              'audiobooks': books,
                                            },
                                          );
                                        },
                                  child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'View All',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.5,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animateOnPageLoad(
                                animationsMap['rowOnPageLoadAnimation']!),
                          ),
                          if (!snapshot.hasData)
                            _buildLoadingList(280.0)
                          else if (books.isEmpty)
                            _buildEmptyList('No audiobooks found', 280.0)
                          else
                            Container(
                              width: double.infinity,
                              height: 280.0,
                              child: ListView.builder(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16.0),
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final audiobook = books[index];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0,
                                      0.0,
                                      index == books.length - 1 ? 0.0 : 16.0,
                                      0.0,
                                    ),
                                    child: _buildAudiobookMainCard(audiobook),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.0),

                  // New Releases Section
                  FutureBuilder<ApiCallResponse>(
                    future: _newFuture,
                    builder: (context, snapshot) {
                      final books = snapshot.hasData
                          ? _normalizeBooksFromResponse(snapshot.data)
                          : <Map<String, dynamic>>[];
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'New Releases',
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        lineHeight: 1.5,
                                      ),
                                ),
                                InkWell(
                                  onTap: books.isEmpty
                                      ? null
                                      : () async {
                                          context.pushNamed(
                                            AudiobookViewAllPageWidget
                                                .routeName,
                                            queryParameters: {
                                              'title': serializeParam(
                                                'New Releases',
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                            extra: <String, dynamic>{
                                              'audiobooks': books,
                                            },
                                          );
                                        },
                                  child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'View All',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.5,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animateOnPageLoad(
                                animationsMap['rowOnPageLoadAnimation']!),
                          ),
                          if (!snapshot.hasData)
                            _buildLoadingList(280.0)
                          else if (books.isEmpty)
                            _buildEmptyList('No audiobooks found', 280.0)
                          else
                            Container(
                              width: double.infinity,
                              height: 280.0,
                              child: ListView.builder(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16.0),
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final audiobook = books[index];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0,
                                      0.0,
                                      index == books.length - 1 ? 0.0 : 16.0,
                                      0.0,
                                    ),
                                    child: _buildAudiobookMainCard(audiobook),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.0),

                  // Trending Section
                  FutureBuilder<ApiCallResponse>(
                    future: _trendingFuture,
                    builder: (context, snapshot) {
                      final books = snapshot.hasData
                          ? _normalizeBooksFromResponse(snapshot.data)
                          : <Map<String, dynamic>>[];
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trending Now',
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        lineHeight: 1.5,
                                      ),
                                ),
                                InkWell(
                                  onTap: books.isEmpty
                                      ? null
                                      : () async {
                                          context.pushNamed(
                                            AudiobookViewAllPageWidget
                                                .routeName,
                                            queryParameters: {
                                              'title': serializeParam(
                                                'Trending Now',
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                            extra: <String, dynamic>{
                                              'audiobooks': books,
                                            },
                                          );
                                        },
                                  child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'View All',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.5,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animateOnPageLoad(
                                animationsMap['rowOnPageLoadAnimation']!),
                          ),
                          if (!snapshot.hasData)
                            _buildLoadingList(280.0)
                          else if (books.isEmpty)
                            _buildEmptyList('No audiobooks found', 280.0)
                          else
                            Container(
                              width: double.infinity,
                              height: 280.0,
                              child: ListView.builder(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16.0),
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final audiobook = books[index];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0,
                                      0.0,
                                      index == books.length - 1 ? 0.0 : 16.0,
                                      0.0,
                                    ),
                                    child: _buildAudiobookMainCard(audiobook),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.0),

                  // Best Sellers Section
                  FutureBuilder<ApiCallResponse>(
                    future: _allFuture,
                    builder: (context, snapshot) {
                      final books = snapshot.hasData
                          ? _normalizeBooksFromResponse(snapshot.data)
                          : <Map<String, dynamic>>[];
                      final displayBooks =
                          books.isNotEmpty ? books.take(10).toList() : books;
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Latest Audiobooks',
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        lineHeight: 1.5,
                                      ),
                                ),
                                InkWell(
                                  onTap: displayBooks.isEmpty
                                      ? null
                                      : () async {
                                          context.pushNamed(
                                            AudiobookViewAllPageWidget
                                                .routeName,
                                            queryParameters: {
                                              'title': serializeParam(
                                                'Best Sellers',
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                            extra: <String, dynamic>{
                                              'audiobooks': displayBooks,
                                            },
                                          );
                                        },
                                  child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(10, 0.0, 10, 0),
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'View All',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.5,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animateOnPageLoad(
                                animationsMap['rowOnPageLoadAnimation']!),
                          ),
                          if (!snapshot.hasData)
                            _buildLoadingList(280.0)
                          else if (displayBooks.isEmpty)
                            _buildEmptyList('No audiobooks found', 280.0)
                          else
                            Container(
                              width: double.infinity,
                              height: 280.0,
                              child: ListView.builder(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 16.0),
                                scrollDirection: Axis.horizontal,
                                itemCount: displayBooks.length,
                                itemBuilder: (context, index) {
                                  final audiobook = displayBooks[index];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0,
                                      0.0,
                                      index == displayBooks.length - 1
                                          ? 0.0
                                          : 16.0,
                                      0.0,
                                    ),
                                    child: _buildAudiobookMainCard(audiobook),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 24.0),

                  // Audiobooks by Category Section
                  FutureBuilder<ApiCallResponse>(
                    future: EbookGroup.getFeaturedBooksByCategoryApiCall.call(
                      token: FFAppState().token,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      final categoryBooksList = EbookGroup
                          .getFeaturedBooksByCategoryApiCall
                          .categoryBooks(snapshot.data!.jsonBody);

                      if (categoryBooksList == null ||
                          categoryBooksList.isEmpty) {
                        return SizedBox.shrink();
                      }

                      return Column(
                        children: List.generate(
                          categoryBooksList.length,
                          (catIndex) {
                            final categoryItem = categoryBooksList[catIndex];
                            final featuredBooks = getJsonField(
                                categoryItem, r'''$.featuredBooks''');

                            final featuredBooksList =
                                (featuredBooks as List?)?.toList() ?? [];
                            final audioFeaturedBooks = featuredBooksList
                                .where(_isAudiobook)
                                .toList();

                            if (audioFeaturedBooks.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 16.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        getJsonField(categoryItem,
                                                r'''$.name''')
                                            .toString(),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
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
                                          context.pushNamed(
                                            GetBookByCategoryPageWidget
                                                .routeName,
                                            queryParameters: {
                                              'name': serializeParam(
                                                getJsonField(categoryItem,
                                                        r'''$.name''')
                                                    .toString(),
                                                ParamType.String,
                                              ),
                                              'id': serializeParam(
                                                getJsonField(categoryItem,
                                                        r'''$._id''')
                                                    .toString(),
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(
                                              10, 0.0, 10, 0),
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'View All',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily:
                                                      'SF Pro Display',
                                                  fontSize: 17.0,
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
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(
                                      audioFeaturedBooks.length,
                                      (bookIndex) {
                                        final bookItem =
                                            audioFeaturedBooks[bookIndex];
                                        final bookId = getJsonField(
                                                bookItem, r'''$._id''')
                                            .toString();
                                        return Padding(
                                          padding: EdgeInsetsDirectional
                                              .fromSTEB(
                                                  bookIndex == 0 ? 16.0 : 0.0,
                                                  0.0,
                                                  16.0,
                                                  0.0),
                                        child: MainBookComponentWidget(
                                          key: Key(
                                              'AudiobookByCat_${catIndex}_$bookIndex'),
                                          id: bookId,
                                          image:
                                              '${FFAppConstants.bookImagesUrl}${getJsonField(bookItem, r'''$.image''').toString()}',
                                          bookName: getJsonField(
                                                  bookItem, r'''$.name''')
                                              .toString(),
                                          authorsName: getJsonField(
                                                  bookItem,
                                                  r'''$.author.name''')
                                              .toString(),
                                          price: getJsonField(
                                                  bookItem, r'''$.price''')
                                              .toString(),
                                          bookType: getJsonField(
                                                  bookItem, r'''$.type''')
                                              ?.toString(),
                                          discountPercentage: getJsonField(
                                                  bookItem,
                                                  r'''$.discount_percentage''')
                                              .toString(),
                                          discountAmount: getJsonField(
                                                  bookItem,
                                                    r'''$.discount_amount''')
                                                .toString(),
                                            isFav: false,
                                            isFavAction: () async {
                                              // Handle favorite action
                                            },
                                            isMainTap: () async {
                                              context.pushNamed(
                                                AudiobookDetailsPageWidget
                                                    .routeName,
                                                extra: <String, dynamic>{
                                                  'audiobook': _normalizeBook(bookItem),
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.0),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudiobookMainCard(Map<String, dynamic> audiobook) {
    return MainBookComponentWidget(
      key: Key('AudiobookCard_${audiobook['id']}'),
      id: audiobook['id']?.toString(),
      image: audiobook['image']?.toString(),
      bookName: audiobook['title']?.toString(),
      authorsName: audiobook['author']?.toString(),
      price: (audiobook['price'] ?? 0).toString(),
      bookType: 'audiobook',
      discountAmount: audiobook['discountAmount']?.toString(),
      discountPercentage: audiobook['discountPercentage']?.toString(),
      isFav: false,
      isFavAction: () async {
        // TODO: hook up favorite action for audiobooks if needed.
      },
      isMainTap: () async {
        context.pushNamed(
          AudiobookDetailsPageWidget.routeName,
          extra: <String, dynamic>{
            'audiobook': audiobook,
          },
        );
      },
    );
  }
}
