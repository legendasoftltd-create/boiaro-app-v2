import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/index.dart';
import 'audiobook_details_page_model.dart';
export 'audiobook_details_page_model.dart';

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
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _extractBookId(Map<String, dynamic> audiobook) {
    final id = audiobook['id'] ??
        audiobook['_id'] ??
        getJsonField(audiobook, r'''$._id''');
    return id?.toString() ?? '';
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
      final price = getJsonField(bookDetails, r'''$.price''') ?? fallback['price'];
    final discountAmount = getJsonField(bookDetails, r'''$.discount_amount''');
    final discountPercentage =
        getJsonField(bookDetails, r'''$.discount_percentage''');
    final offerPrice =
        _calculateOfferPrice(price, discountAmount, discountPercentage) ??
            fallback['offerPrice'];
      final rating =
          _toNum(getJsonField(bookDetails, r'''$.averageRating''')) ??
              _toNum(fallback['rating']) ??
              0;
      final previewAudio =
          getJsonField(bookDetails, r'''$.preview_audio''') ??
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
      'category': getJsonField(bookDetails, r'''$.category.name''')?.toString() ??
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
            ) ??
            '',
        'previewAudio': previewAudio,
        'raw': bookDetails ?? fallback,
      };
    }

  List<Map<String, dynamic>> _normalizeChapters(
      dynamic bookDetails, List<dynamic> fallback) {
    final rawChapters = (getJsonField(bookDetails, r'''$.chapters''', true) ??
            fallback)
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
      final isLocked = getJsonField(chapter, r'''$.isLocked''') ??
          getJsonField(chapter, r'''$.is_locked''') ??
          false;
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

  List<Map<String, dynamic>> _normalizeRelatedBooks(
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
        final details =
            (detailsList != null && detailsList.isNotEmpty) ? detailsList.first : null;
        final book = _normalizeBookDetails(details, fallback);
        final chapters = _normalizeChapters(
          details,
          (fallback['chapters'] as List?) ?? [],
        );
        final previewAudio = book['previewAudio'] ??
            getJsonField(details, r'''$.preview_audio''') ??
            getJsonField(book['raw'], r'''$.preview_audio''');
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
                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
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
                        child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
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
                          icon: Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          onPressed: () {},
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
                          icon: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                          onPressed: () {},
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
                              onTap: () {
                                final previewPath = previewAudio?.toString().trim() ?? '';
                                if (previewPath.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Preview audio not available'),
                                    ),
                                  );
                                  return;
                                }
                                final previewChapter = <String, dynamic>{
                                  'title': 'Preview',
                                  'file': previewPath,
                                  'isLocked': false,
                                  'isPreview': true,
                                };
                                context.pushNamed(
                                  AudioPlayerPageWidget.routeName,
                                  extra: <String, dynamic>{
                                    'audiobook': {
                                      ...book,
                                      'chapters': chapters,
                                    },
                                    'chapter': previewChapter,
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Preview',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person_pin_circle_outlined, color: FlutterFlowTheme.of(context).primary, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        book['author'] ?? 'Author Name',
                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'SF Pro Display',
                                              color: FlutterFlowTheme.of(context).primary,
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
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    book['category'] ?? 'Fiction',
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context).primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '৳${book['offerPrice'] ?? book['price'] ?? '0'}',
                                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context).primary,
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
                            color: FlutterFlowTheme.of(context).secondaryBackground,
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
                              _buildStatItem(context, Icons.bookmark_border_rounded, 'Wishlist'),
                              _buildStatItem(context, '${chapters.length}', 'Chapters'),
                            ],
                          ),
                        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation1']!),

                        SizedBox(height: 32),

                        // Action Button
                        InkWell(
                          onTap: chapters.isEmpty
                              ? null
                              : () async {
                                    context.pushNamed(
                                      AudioPlayerPageWidget.routeName,
                                      extra: <String, dynamic>{
                                        "audiobook": {
                                          ...book,
                                          'chapters': chapters,
                                        },
                                        "chapter": chapters.first,
                                      },
                                    );
                                },
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.headphones_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Listen Now',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
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
                          style: FlutterFlowTheme.of(context).titleLarge.override(
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
                            return _buildChapterTile(context, book, chapter, index + 1, chapters);
                          },
                        ),

                        SizedBox(height: 32),

                        // Description
                        Text(
                          'Description',
                          style: FlutterFlowTheme.of(context).titleLarge.override(
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          description.isNotEmpty ? description
                              : 'No description available.',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).secondaryText,
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

                        // Opinion/Comment Box
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primaryBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'আপনার মতামত দিন...', // Give your opinion
                                hintStyle: FlutterFlowTheme.of(context).bodySmall,
                                border: InputBorder.none,
                                suffixIcon: Icon(Icons.send_rounded, color: FlutterFlowTheme.of(context).primary),
                              ),
                            ),
                          ),
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
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildRelatedBookCard(filtered[index]),
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
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildRelatedBookCard(filtered[index]),
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
          Icon(value, color: FlutterFlowTheme.of(context).primaryText, size: 24),
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
    List<Map<String, dynamic>> chapters,
  ) {
    final bool isLocked = chapter['isLocked'] ?? false;
    return InkWell(
      onTap: () async {
          context.pushNamed(
            AudioPlayerPageWidget.routeName,
            extra: <String, dynamic>{
              'audiobook': {
                ...audiobook,
                'chapters': chapters,
              },
              'chapter': chapter,
            },
          );
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
                  Text(
                    chapter['duration'] ?? '--:--',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'SF Pro Display',
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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

  Widget _buildRelatedBookCard(Map<String, dynamic> related) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
      child: InkWell(
        onTap: () async {
          context.pushNamed(
            AudiobookDetailsPageWidget.routeName,
            extra: <String, dynamic>{
              'audiobook': related,
            },
          );
        },
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  related['image'] ??
                      'https://picsum.photos/seed/related/300/400',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      related['title'] ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      related['author'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
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
  }

}
