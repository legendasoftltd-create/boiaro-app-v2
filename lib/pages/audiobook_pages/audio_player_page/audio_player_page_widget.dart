import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'audio_player_page_model.dart';
export 'audio_player_page_model.dart';

class AudioPlayerPageWidget extends StatefulWidget {
  const AudioPlayerPageWidget({
    super.key,
    required this.audiobook,
    required this.chapter,
  });

  final Map<String, dynamic> audiobook;
  final Map<String, dynamic> chapter;

  static String routeName = 'AudioPlayerPage';
  static String routePath = '/audioPlayerPage';

  @override
  State<AudioPlayerPageWidget> createState() => _AudioPlayerPageWidgetState();
}

class _AudioPlayerPageWidgetState extends State<AudioPlayerPageWidget>
    with TickerProviderStateMixin {
  late AudioPlayerPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = {
    'imageOnPageLoadAnimation': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effectsBuilder: () => [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
        ScaleEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
        ),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudioPlayerPageModel());
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
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 30),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Now Playing',
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontFamily: 'SF Pro Display',
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: FlutterFlowTheme.of(context).primaryText),
              onPressed: () {},
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Art
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 40.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(0, 20),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: Image.network(
                          widget.audiobook['image'] ?? 'https://picsum.photos/seed/audio/800/800',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animateOnPageLoad(animationsMap['imageOnPageLoadAnimation']!),
                  ),
                ),

                // Title and Author
                Column(
                  children: [
                    Text(
                      widget.chapter['title'] ?? 'Chapter Title',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.audiobook['author'] ?? 'Author Name',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),

                SizedBox(height: 48),

                // Progress Bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: FlutterFlowTheme.of(context).primary,
                        inactiveTrackColor: FlutterFlowTheme.of(context).gray200,
                        thumbColor: FlutterFlowTheme.of(context).primary,
                        overlayColor: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _model.sliderValue,
                        min: 0,
                        max: 100,
                        onChanged: (val) {
                          setState(() {
                            _model.sliderValue = val;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0:10',
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                          ),
                          Text(
                            widget.chapter['duration'] ?? '0:30',
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.replay_10_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {},
                    ),
                    // Play/Pause Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _model.isPlaying = !_model.isPlaying;
                        });
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 20.0,
                              color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                              offset: Offset(0, 10),
                            )
                          ],
                        ),
                        child: Icon(
                          _model.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 36),
                      onPressed: () {},
                    ),
                  ],
                ),

                SizedBox(height: 48),

                // Bottom Icons Row
                Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomAction(context, '1.0x', 'Speed'),
                      _buildBottomAction(context, Icons.format_list_bulleted_rounded, 'Episodes'),
                      _buildBottomAction(context, Icons.timer_outlined, 'Sleep Timer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, dynamic icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon is IconData)
          Icon(icon, color: FlutterFlowTheme.of(context).primaryText, size: 24)
        else
          Text(
            icon,
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
