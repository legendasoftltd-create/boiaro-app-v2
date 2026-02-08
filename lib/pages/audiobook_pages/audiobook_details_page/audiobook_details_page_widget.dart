import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audiobook = widget.audiobook;
    
    // Mocking chapters if not provided
    final List<dynamic> chapters = audiobook['chapters'] ?? [
      {'title': 'Introduction & Chapter 1', 'duration': '27:52', 'isLocked': false},
      {'title': 'Chapter 2: The Mystery Unfolds', 'duration': '28:00', 'isLocked': true},
      {'title': 'Chapter 3: Deep Dive', 'duration': '28:00', 'isLocked': true},
      {'title': 'Chapter 4: The Clues', 'duration': '5:59', 'isLocked': true},
      {'title': 'Chapter 5: Hidden Truth', 'duration': '20:09', 'isLocked': true},
    ];

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
                          audiobook['image'] ?? 'https://picsum.photos/seed/audio/800/1200',
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
                                    audiobook['title'] ?? 'Title',
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
                                        audiobook['author'] ?? 'Author Name',
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
                                    audiobook['category'] ?? 'Fiction',
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context).primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '৳${audiobook['offerPrice'] ?? audiobook['price'] ?? '0'}',
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
                              _buildStatItem(context, '4.6 ★', 'Review (14)'),
                              _buildStatItem(context, 'Audio', 'Book'),
                              _buildStatItem(context, Icons.bookmark_border_rounded, 'Wishlist'),
                              _buildStatItem(context, '${chapters.length}', 'Chapters'),
                            ],
                          ),
                        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation1']!),

                        SizedBox(height: 32),

                        // Action Button
                        InkWell(
                          onTap: () {},
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
                                  'বইটি কিনুন', // Buy the book
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
                            return _buildChapterTile(context, chapter, index + 1);
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
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'হমায়ুন আহমেদের অমর সৃষ্টি মিসির আলী, এই গল্পের কেন্দ্রীয় চরিত্র। ওনার সাথে দেখা করতে আসেন ওসমান গনি...',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      lineHeight: 1.5,
                                    ),
                              ),
                              TextSpan(
                                text: ' আরও পড়ুন', // Read More
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context).error,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Tags
                        Row(
                          children: [
                            _buildTag(context, 'Mystery'),
                            SizedBox(width: 8),
                            _buildTag(context, 'Thriller'),
                          ],
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

                        // Recommendation Section (Placeholders for now)
                        _buildSectionHeader(context, 'More from this author'),
                        SizedBox(height: 16),
                        Container(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) => _buildSimpleBookCard(context),
                          ),
                        ),

                        SizedBox(height: 32),

                        _buildSectionHeader(context, 'Similar Audiobooks'),
                        SizedBox(height: 16),
                        Container(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) => _buildSimpleBookCard(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
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

  Widget _buildChapterTile(BuildContext context, dynamic chapter, int index) {
    final bool isLocked = chapter['isLocked'] ?? false;
    return InkWell(
      onTap: () async {
        context.pushNamed(
          AudioPlayerPageWidget.routeName,
          extra: <String, dynamic>{
            'audiobook': widget.audiobook,
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
          border: Border.all(color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5)),
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
                  chapter['title'],
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  chapter['duration'],
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
            Icon(Icons.lock_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 20)
          else
            Icon(Icons.check_circle_rounded, color: FlutterFlowTheme.of(context).success, size: 20),
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

  Widget _buildSimpleBookCard(BuildContext context) {
    return Container(
      width: 130,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://picsum.photos/seed/${DateTime.now().millisecond}/200/300',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Book Title',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '৳150',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
