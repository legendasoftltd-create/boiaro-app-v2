import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/index.dart';
import 'package:flutter/material.dart';

import 'audiobook_page_model.dart';
export 'audiobook_page_model.dart';

/// Bottom-nav Audiobook tab: same feed as [HomePageWidget] with the Audiobook
/// filter applied (sections, lists, navigation). Custom [AppBar] only.
class AudiobookPageWidget extends StatefulWidget {
  const AudiobookPageWidget({super.key});

  static String routeName = 'AudiobookPage';
  static String routePath = '/audiobookPage';

  @override
  State<AudiobookPageWidget> createState() => _AudiobookPageWidgetState();
}

class _AudiobookPageWidgetState extends State<AudiobookPageWidget> {
  late AudiobookPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudiobookPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: const HomePageWidget(embeddedAudiobookMode: true),
    );
  }
}
