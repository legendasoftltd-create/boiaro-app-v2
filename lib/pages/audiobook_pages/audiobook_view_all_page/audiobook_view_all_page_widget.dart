import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'audiobook_view_all_page_model.dart';
export 'audiobook_view_all_page_model.dart';

class AudiobookViewAllPageWidget extends StatefulWidget {
  const AudiobookViewAllPageWidget({
    super.key,
    required this.title,
    required this.audiobooks,
  });

  final String title;
  final List<dynamic> audiobooks;

  static String routeName = 'AudiobookViewAllPage';
  static String routePath = '/audiobookViewAllPage';

  @override
  State<AudiobookViewAllPageWidget> createState() =>
      _AudiobookViewAllPageWidgetState();
}

class _AudiobookViewAllPageWidgetState extends State<AudiobookViewAllPageWidget> {
  late AudiobookViewAllPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = {
    'containerOnPageLoadAnimation': AnimationInfo(
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
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudiobookViewAllPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.safePop();
            },
            child: Icon(
              Icons.chevron_left_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 32.0,
            ),
          ),
          title: Text(
            widget.title,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.65,
              ),
              itemCount: widget.audiobooks.length,
              itemBuilder: (context, index) {
                final audiobook = widget.audiobooks[index] as Map<String, dynamic>;
                return _buildAudiobookCard(audiobook);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudiobookCard(Map<String, dynamic> audiobook) {
    return Container(
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
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    child: Image.network(
                      audiobook['image'] ?? 'https://picsum.photos/seed/audio/400/600',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Favorite Button
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
                          color: Colors.black.withOpacity(0.1),
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
                // Rating
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12.0),
                        SizedBox(width: 2.0),
                        Text(
                          audiobook['rating']?.toString() ?? '0.0',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: Colors.white,
                            fontSize: 10.0,
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
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audiobook['title'] ?? 'Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 2.0),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 10.0),
                          SizedBox(width: 4.0),
                          Text(
                            audiobook['duration'] ?? '0h 0m',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'SF Pro Display',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (audiobook['price'] == null)
                        Text(
                          'Free',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).primary,
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      else
                        Row(
                          children: [
                            if (audiobook['offerPrice'] != null) ...[
                              Text(
                                '\$${(audiobook['price'] as num).toStringAsFixed(2)}',
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 10.0,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                '\$${(audiobook['offerPrice'] as num).toStringAsFixed(2)}',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else
                              Text(
                                '\$${(audiobook['price'] as num).toStringAsFixed(2)}',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!);
  }
}
