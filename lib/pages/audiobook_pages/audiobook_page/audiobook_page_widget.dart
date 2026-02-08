import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '/index.dart';
import 'audiobook_page_model.dart';
export 'audiobook_page_model.dart';

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

  // Dummy audiobook data
  
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

  final List<Map<String, dynamic>> featuredAudiobooks = [
    {
      'title': 'The Midnight Library',
      'author': 'Matt Haig',
      'duration': '8h 30m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio1/400/600',
      'color': Color(0xFF6366F1),
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
      'duration': '5h 35m',
      'rating': 4.9,
      'image': 'https://picsum.photos/seed/audio2/400/600',
      'color': Color(0xFFEC4899),
    },
    {
      'title': 'Project Hail Mary',
      'author': 'Andy Weir',
      'duration': '16h 10m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio3/400/600',
      'color': Color(0xFF8B5CF6),
    },
  ];

  final List<Map<String, dynamic>> popularAudiobooks = [
    {
      'title': 'The Psychology of Money',
      'author': 'Morgan Housel',
      'duration': '5h 48m',
      'rating': 4.6,
      'image': 'https://picsum.photos/seed/audio4/400/600',
      'views': '12.5k',
      'price': 14.99,
      'offerPrice': 9.99,
    },
    {
      'title': 'Educated',
      'author': 'Tara Westover',
      'duration': '12h 10m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio5/400/600',
      'views': '8.3k',
      'price': 16.99,
      'offerPrice': 12.99,
    },
    {
      'title': 'Sapiens',
      'author': 'Yuval Noah Harari',
      'duration': '15h 17m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio6/400/600',
      'views': '25.7k',
      'price': 19.99,
      'offerPrice': 14.99,
    },
    {
      'title': 'The Alchemist',
      'author': 'Paulo Coelho',
      'duration': '4h 0m',
      'rating': 4.5,
      'image': 'https://picsum.photos/seed/audio7/400/600',
      'views': '18.2k',
      'price': 12.99,
      'offerPrice': 7.99,
    },
  ];


  final List<Map<String, dynamic>> newReleases = [
    {
      'title': 'Tomorrow, and Tomorrow',
      'author': 'Gabrielle Zevin',
      'duration': '14h 58m',
      'rating': 4.6,
      'image': 'https://picsum.photos/seed/audio8/400/600',
      'views': '15.3k',
      'price': 18.99,
      'offerPrice': 13.99,
    },
    {
      'title': 'Lessons in Chemistry',
      'author': 'Bonnie Garmus',
      'duration': '11h 22m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio9/400/600',
      'views': '22.1k',
      'price': 15.99,
      'offerPrice': 11.99,
    },
    {
      'title': 'The Light We Carry',
      'author': 'Michelle Obama',
      'duration': '9h 18m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio10/400/600',
      'views': '19.8k',
      'price': 17.99,
      'offerPrice': 12.99,
    },
    {
      'title': 'Spare',
      'author': 'Prince Harry',
      'duration': '15h 39m',
      'rating': 4.4,
      'image': 'https://picsum.photos/seed/audio11/400/600',
      'views': '31.5k',
      'price': 20.99,
      'offerPrice': 15.99,
    },
  ];

  final List<Map<String, dynamic>> bestSellers = [
    {
      'title': 'Becoming',
      'author': 'Michelle Obama',
      'duration': '19h 3m',
      'rating': 4.9,
      'image': 'https://picsum.photos/seed/audio12/400/600',
      'views': '45.2k',
      'price': 22.99,
      'offerPrice': 16.99,
    },
    {
      'title': 'The 7 Habits',
      'author': 'Stephen Covey',
      'duration': '15h 50m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio13/400/600',
      'views': '38.7k',
      'price': 18.99,
      'offerPrice': 13.99,
    },
    {
      'title': 'Thinking, Fast and Slow',
      'author': 'Daniel Kahneman',
      'duration': '20h 2m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio14/400/600',
      'views': '29.3k',
      'price': 21.99,
      'offerPrice': 15.99,
    },
    {
      'title': 'The Power of Now',
      'author': 'Eckhart Tolle',
      'duration': '7h 37m',
      'rating': 4.6,
      'image': 'https://picsum.photos/seed/audio15/400/600',
      'views': '33.1k',
      'price': 14.99,
      'offerPrice': 9.99,
    },
  ];

  final List<Map<String, dynamic>> recommendedForYou = [
    {
      'title': 'The Subtle Art',
      'author': 'Mark Manson',
      'duration': '5h 17m',
      'rating': 4.5,
      'image': 'https://picsum.photos/seed/audio16/400/600',
      'views': '27.6k',
      'price': 13.99,
      'offerPrice': 8.99,
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'duration': '21h 2m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio17/400/600',
      'views': '41.2k',
      'price': 24.99,
      'offerPrice': 18.99,
    },
    {
      'title': 'The Four Agreements',
      'author': 'Don Miguel Ruiz',
      'duration': '2h 31m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio18/400/600',
      'views': '16.8k',
      'price': 11.99,
      'offerPrice': 7.99,
    },
    {
      'title': 'Can\'t Hurt Me',
      'author': 'David Goggins',
      'duration': '13h 37m',
      'rating': 4.9,
      'image': 'https://picsum.photos/seed/audio19/400/600',
      'views': '52.3k',
      'price': 19.99,
      'offerPrice': 14.99,
    },
  ];

  final List<Map<String, dynamic>> recentlyAdded = [
    {
      'title': 'The Midnight Library',
      'author': 'Matt Haig',
      'duration': '8h 30m',
      'rating': 4.8,
      'image': 'https://picsum.photos/seed/audio20/400/600',
      'views': '34.5k',
      'price': 15.99,
      'offerPrice': 11.99,
    },
    {
      'title': 'Where the Crawdads Sing',
      'author': 'Delia Owens',
      'duration': '12h 12m',
      'rating': 4.7,
      'image': 'https://picsum.photos/seed/audio21/400/600',
      'views': '48.9k',
      'price': 17.99,
      'offerPrice': 12.99,
    },
    {
      'title': 'The Silent Patient',
      'author': 'Alex Michaelides',
      'duration': '8h 43m',
      'rating': 4.6,
      'image': 'https://picsum.photos/seed/audio22/400/600',
      'views': '39.7k',
      'price': 14.99,
      'offerPrice': 10.99,
    },
    {
      'title': 'Greenlights',
      'author': 'Matthew McConaughey',
      'duration': '6h 42m',
      'rating': 4.5,
      'image': 'https://picsum.photos/seed/audio23/400/600',
      'views': '28.4k',
      'price': 13.99,
      'offerPrice': 9.99,
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudiobookPageModel());

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

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
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
                      Container(
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
                                Container(
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

            // Categories Section
            Padding(
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
                      Container(
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
                    ],
                  ).animateOnPageLoad(
                      animationsMap['rowOnPageLoadAnimation']!),
                  SizedBox(height: 16.0),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: category['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: category['color'].withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: category['color'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category['icon'],
                                color: Colors.white,
                                size: 24.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              category['name'],
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              '${category['count']} books',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ).animateOnPageLoad(
                          animationsMap['containerOnPageLoadAnimation2']!);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.0),

            // Content Sections
            // Popular Audiobooks Section
            Column(
              mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'Popular Audiobooks',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': popularAudiobooks,
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: popularAudiobooks.length,
                          itemBuilder: (context, index) {
                            final audiobook = popularAudiobooks[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == popularAudiobooks.length - 1
                                    ? 0.0
                                    : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.0),

                  // New Releases Section
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'New Releases',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': newReleases,
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: newReleases.length,
                          itemBuilder: (context, index) {
                            final audiobook = newReleases[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == newReleases.length - 1 ? 0.0 : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.0),

                  // Trending Section
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'Trending Now',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': popularAudiobooks.reversed.toList(),
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: popularAudiobooks.length,
                          itemBuilder: (context, index) {
                            final audiobook = popularAudiobooks.reversed
                                .toList()[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == popularAudiobooks.length - 1
                                    ? 0.0
                                    : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.0),

                  // Best Sellers Section
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Best Sellers',
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
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'Best Sellers',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': bestSellers,
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: bestSellers.length,
                          itemBuilder: (context, index) {
                            final audiobook = bestSellers[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == bestSellers.length - 1 ? 0.0 : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.0),

                  // Recommended for You Section
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.recommend_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                                SizedBox(width: 8.0),
                                Text(
                                  'Recommended for You',
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
                              ],
                            ),
                            InkWell(
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'Recommended for You',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': recommendedForYou,
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendedForYou.length,
                          itemBuilder: (context, index) {
                            final audiobook = recommendedForYou[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == recommendedForYou.length - 1
                                    ? 0.0
                                    : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.0),

                  // Recently Added Section
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.new_releases_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                                SizedBox(width: 8.0),
                                Text(
                                  'Recently Added',
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
                              ],
                            ),
                            InkWell(
                              onTap: () async {
                                context.pushNamed(
                                  AudiobookViewAllPageWidget.routeName,
                                  queryParameters: {
                                    'title': serializeParam(
                                      'Recently Added',
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                  extra: <String, dynamic>{
                                    'audiobooks': recentlyAdded,
                                  },
                                );
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
                      ),
                      Container(
                        width: double.infinity,
                        height: 280.0,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          scrollDirection: Axis.horizontal,
                          itemCount: recentlyAdded.length,
                          itemBuilder: (context, index) {
                            final audiobook = recentlyAdded[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                0.0,
                                index == recentlyAdded.length - 1 ? 0.0 : 16.0,
                                0.0,
                              ),
                              child: _buildAudiobookCard(audiobook),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudiobookCard(Map<String, dynamic> audiobook) {
    return InkWell(
      onTap: () async {
        context.pushNamed(
          AudiobookDetailsPageWidget.routeName,
          extra: <String, dynamic>{
            'audiobook': audiobook,
          },
        );
      },
      child: Container(
        width: 180.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 12.0,
            color: FlutterFlowTheme.of(context).shadowColor,
            offset: Offset(0.0, 4.0),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 160.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  child: Image.network(
                    audiobook['image'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Favorite Button (Top Left)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8.0,
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0.0, 2.0),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: FlutterFlowTheme.of(context).error,
                    size: 18.0,
                  ),
                ),
              ),
              // Rating Badge (Top Right)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 14.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        audiobook['rating'].toString(),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: Colors.white,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // Views Count Badge (Bottom Left)
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 12.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        audiobook['views'] ?? '0',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: Colors.white,
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // Play Button (Bottom Right)
              Positioned(
                bottom: 8.0,
                right: 8.0,
                child: Container(
                  width: 35.0,
                  height: 35.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8.0,
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.4),
                        offset: Offset(0.0, 2.0),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audiobook['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  
                  SizedBox(height: 4.0),
                  // Duration
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 12.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        audiobook['duration'],
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 10.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  // Pricing
                  if (audiobook['price'] == null)
                  Text(
                    'Free',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                        ),
                  ),
                  if (audiobook['price'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (audiobook['offerPrice'] != null) ...[
                              Text(
                                '\$${(audiobook['price'] as num).toStringAsFixed(2)}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                              SizedBox(width: 6.0),
                              Text(
                                '\$${(audiobook['offerPrice'] as num).toStringAsFixed(2)}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context).primary,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ] else ...[
                              Text(
                                '\$${(audiobook['price'] as num).toStringAsFixed(2)}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      // Discount Badge
                      if (audiobook['offerPrice'] != null &&
                          audiobook['price'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '-${(((audiobook['price'] - audiobook['offerPrice']) / audiobook['price']) * 100).toInt()}%',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'SF Pro Display',
                                      color: Colors.white,
                                      fontSize: 9.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),)
    );
  }
}
