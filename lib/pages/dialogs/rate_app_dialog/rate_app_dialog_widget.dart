import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'rate_app_dialog_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
export 'rate_app_dialog_model.dart';

class RateAppDialogWidget extends StatefulWidget {
  const RateAppDialogWidget({super.key});

  @override
  State<RateAppDialogWidget> createState() => _RateAppDialogWidgetState();
}

class _RateAppDialogWidgetState extends State<RateAppDialogWidget> {
  late RateAppDialogModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RateAppDialogModel());
    _model.feedbackTextController ??= TextEditingController();
    _model.feedbackFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _submitRating() async {
    if (_model.selectedStars >= 4) {
      // High rating -> Launch Play Store URL
      Navigator.of(context).pop();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('boiaro_last_rate_submitted_time_ms', DateTime.now().millisecondsSinceEpoch);
      await launchURL('https://play.google.com/store/apps/details?id=com.boiaro.app');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ধন্যবাদ! আপনার মূল্যায়ন আমাদের অনুপ্রাণিত করে।'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Low rating -> Show feedback form
      setState(() {
        _model.showFeedbackField = true;
      });
    }
  }

  void _submitFeedback() async {
    Navigator.of(context).pop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('boiaro_last_rate_submitted_time_ms', DateTime.now().millisecondsSinceEpoch);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('আপনার ফিডব্যাকের জন্য ধন্যবাদ! আমরা অ্যাপটি আরও উন্নত করব।'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: () {
            if (MediaQuery.sizeOf(context).width < kBreakpointSmall) {
              return (MediaQuery.sizeOf(context).width - 32);
            } else {
              return 400.0;
            }
          }(),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10.0,
                color: Color(0x1A000000),
                offset: Offset(0.0, 4.0),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24.0, 32.0, 24.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Heart or Star Illustration Header
                Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 40.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                
                // Title
                Text(
                  _model.showFeedbackField 
                      ? 'আমাদের মতামত জানান' 
                      : 'বই আরো অ্যাপটি আপনার কেমন লাগছে?',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 10.0),

                // Subtitle
                Text(
                  _model.showFeedbackField
                      ? 'অনুগ্রহ করে জানান আমরা কীভাবে আমাদের অ্যাপের সার্ভিস আরও উন্নত করতে পারি।'
                      : 'আপনার মূল্যবান মতামত আমাদের অ্যাপের মান আরও উন্নত করতে সাহায্য করবে।',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        lineHeight: 1.4,
                      ),
                ),
                const SizedBox(height: 24.0),

                if (!_model.showFeedbackField) ...[
                  // Stars Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isSelected = starVal <= _model.selectedStars;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _model.selectedStars = starVal;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected 
                                ? const Color(0xFFFFB300) 
                                : FlutterFlowTheme.of(context).secondaryText.withOpacity(0.5),
                            size: 44.0,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32.0),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('boiaro_last_rate_dismissed_time_ms', DateTime.now().millisecondsSinceEpoch);
                          },
                          text: 'পরে জানাবো',
                          options: FFButtonOptions(
                            height: 48.0,
                            color: Colors.transparent,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: _submitRating,
                          text: 'সাবমিট',
                          options: FFButtonOptions(
                            height: 48.0,
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Feedback Text Field
                  TextFormField(
                    controller: _model.feedbackTextController,
                    focusNode: _model.feedbackFocusNode,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'এখানে লিখুন...',
                      hintStyle: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 24.0),

                  // Feedback Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () {
                            setState(() {
                              _model.showFeedbackField = false;
                            });
                          },
                          text: 'ফিরে যান',
                          options: FFButtonOptions(
                            height: 48.0,
                            color: Colors.transparent,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: _submitFeedback,
                          text: 'ফিডব্যাক দিন',
                          options: FFButtonOptions(
                            height: 48.0,
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
