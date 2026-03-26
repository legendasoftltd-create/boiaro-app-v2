import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/index.dart';
import 'audiobook_view_all_page_model.dart';
export 'audiobook_view_all_page_model.dart';
import '/pages/components/main_book_component/main_book_component_widget.dart';

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
                return _buildAudiobookMainCard(audiobook);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudiobookMainCard(Map<String, dynamic> audiobook) {
    return MainBookComponentWidget(
      key: Key('AudiobookViewAll_${audiobook['id']}'),
      id: audiobook['id']?.toString(),
      image: audiobook['image']?.toString(),
      bookName: audiobook['title']?.toString(),
      authorsName: audiobook['author']?.toString(),
      price: (audiobook['price'] ?? 0).toString(),
      bookType: audiobook['bookType']?.toString() ??
          audiobook['type']?.toString() ??
          getJsonField(audiobook['raw'], r'''$.type''')?.toString() ??
          'audiobook',
      discountAmount: audiobook['discountAmount']?.toString(),
      discountPercentage: audiobook['discountPercentage']?.toString(),
      isFav: false,
      isFavAction: () async {
        // TODO: hook up favorite action for audiobooks if needed.
      },
      isMainTap: () async {
        final bookType = (audiobook['bookType']?.toString() ??
                audiobook['type']?.toString() ??
                getJsonField(audiobook['raw'], r'''$.type''')?.toString() ??
                '')
            .toLowerCase();
        if (bookType == 'audiobook') {
          context.pushNamed(
            AudiobookDetailsPageWidget.routeName,
            extra: <String, dynamic>{
              'audiobook': audiobook,
            },
          );
        } else {
          context.pushNamed(
            BookDetailspageWidget.routeName,
            queryParameters: {
              'name': serializeParam(
                audiobook['title']?.toString() ?? '',
                ParamType.String,
              ),
              'price': serializeParam(
                (audiobook['price'] ?? '').toString(),
                ParamType.String,
              ),
              'image': serializeParam(
                audiobook['image']?.toString() ?? '',
                ParamType.String,
              ),
              'id': serializeParam(
                audiobook['id']?.toString() ?? '',
                ParamType.String,
              ),
            }.withoutNulls,
          );
        }
      },
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!);
  }
}
